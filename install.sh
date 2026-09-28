#!/usr/bin/env bash
# Instala o WAF (Nginx + ModSecurity + OWASP CRS + bloqueio por país) direto
# no host. Suporta Ubuntu 24.04+, Debian 12+ e Rocky/Alma/RHEL 9.
# Pode ser rodado de novo para atualizar: arquivos que você personaliza
# (backend.conf, exclusoes.conf, crs-setup.conf) não são sobrescritos.
set -euo pipefail

CRS_VERSAO=4.29.0
CRS_SHA256=1aa1c5c8fc29e532d35293bcea36bf72de61db8f6ed4716a0f91ab14552b7fed

REPO=$(cd "$(dirname "$0")" && pwd)

erro() { echo "install.sh: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || erro "rode como root (sudo ./install.sh)"

. /etc/os-release
case " $ID ${ID_LIKE:-} " in
    *" debian "* | *" ubuntu "*) FAMILIA=debian ;;
    *" rhel "* | *" fedora "*) FAMILIA=rhel ;;
    *) erro "distribuição não suportada: $PRETTY_NAME" ;;
esac

# --- Pacotes ------------------------------------------------------------------

if [[ $FAMILIA == debian ]]; then
    NGINX_USUARIO=www-data
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        nginx libnginx-mod-http-modsecurity python3 curl ca-certificates
    # O site padrão também usa default_server na porta 80.
    if [[ -L /etc/nginx/sites-enabled/default ]]; then
        rm /etc/nginx/sites-enabled/default
        echo "Site padrão do Nginx desativado (/etc/nginx/sites-enabled/default)."
    fi
else
    [[ ${VERSION_ID%%.*} == 9 ]] || erro "só a versão 9 é suportada (o EPEL $VERSION_ID não tem o nginx-mod-modsecurity)"
    NGINX_USUARIO=nginx
    if [[ $ID != rhel ]]; then
        dnf install -y epel-release dnf-plugins-core
        dnf config-manager --set-enabled crb
    else
        rpm -q epel-release >/dev/null ||
            dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    fi
    dnf install -y nginx nginx-mod-modsecurity python3 curl tar
fi

# --- OWASP CRS ----------------------------------------------------------------

CRS_DIR=/etc/nginx/modsec/coreruleset-$CRS_VERSAO
if [[ ! -d $CRS_DIR ]]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    curl -fsSL -o "$tmp/crs.tar.gz" \
        "https://github.com/coreruleset/coreruleset/releases/download/v$CRS_VERSAO/coreruleset-$CRS_VERSAO-minimal.tar.gz"
    echo "$CRS_SHA256  $tmp/crs.tar.gz" | sha256sum -c --quiet ||
        erro "checksum do CRS não confere"
    mkdir -p /etc/nginx/modsec
    tar --no-same-owner -xzf "$tmp/crs.tar.gz" -C /etc/nginx/modsec
fi
ln -sfn "coreruleset-$CRS_VERSAO" /etc/nginx/modsec/crs

# --- Arquivos de configuração -------------------------------------------------

# Sobrescreve, guardando uma cópia .bak se o conteúdo mudou.
instala() {
    if [[ -e $3 ]] && ! cmp -s "$2" "$3"; then
        cp -p "$3" "$3.bak"
    fi
    install -D -m "$1" "$2" "$3"
}

# Só cria: arquivos que você personaliza.
instala_se_ausente() {
    [[ -e $2 ]] || install -D -m 0644 "$1" "$2"
}

instala 0644 "$REPO/nginx/waf.conf" /etc/nginx/conf.d/waf.conf
instala 0644 "$REPO/nginx/redes-privadas.conf" /etc/nginx/waf/redes-privadas.conf
instala_se_ausente "$REPO/nginx/backend.conf" /etc/nginx/waf/backend.conf

instala 0644 "$REPO/modsec/main.conf" /etc/nginx/modsec/main.conf
instala 0644 "$REPO/modsec/modsecurity.conf" /etc/nginx/modsec/modsecurity.conf
instala_se_ausente "$REPO/modsec/exclusoes.conf" /etc/nginx/modsec/exclusoes.conf
instala_se_ausente "$CRS_DIR/crs-setup.conf.example" /etc/nginx/modsec/crs-setup.conf

# O log de auditoria tem dados das requisições: só o usuário do Nginx lê.
install -d -m 0750 -o "$NGINX_USUARIO" /var/log/nginx/modsec
instala 0644 "$REPO/logrotate/waf-modsec" /etc/logrotate.d/waf-modsec

instala 0755 "$REPO/scripts/waf-atualiza-geo" /usr/local/sbin/waf-atualiza-geo
instala 0644 "$REPO/systemd/waf-atualiza-geo.service" /etc/systemd/system/waf-atualiza-geo.service
instala 0644 "$REPO/systemd/waf-atualiza-geo.timer" /etc/systemd/system/waf-atualiza-geo.timer

# --- SELinux e firewall -------------------------------------------------------

if command -v getenforce >/dev/null && [[ $(getenforce) != Disabled ]]; then
    # Permite ao Nginx conectar no backend.
    setsebool -P httpd_can_network_connect 1
    restorecon -R /etc/nginx /var/log/nginx /usr/local/sbin/waf-atualiza-geo /etc/systemd/system/waf-atualiza-geo.*
fi

if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-service=http --add-service=https
    firewall-cmd --reload
elif command -v ufw >/dev/null && ufw status | grep -q "Status: active"; then
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

# --- Faixas de IP e ativação --------------------------------------------------

# Gera geo-pais.conf e valida toda a configuração com nginx -t.
/usr/local/sbin/waf-atualiza-geo --paises BR --sem-reload

systemctl daemon-reload
systemctl enable --now waf-atualiza-geo.timer
systemctl enable nginx
systemctl reload-or-restart nginx

echo
echo "WAF instalado. Próximo passo: ajuste o backend em /etc/nginx/waf/backend.conf"
echo "e aplique com: nginx -t && systemctl reload nginx"
