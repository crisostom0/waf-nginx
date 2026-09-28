## 🇧🇷 Português

# WAF com NGINX + ModSecurity

[![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)](https://github.com/crisostom0/waf-nginx)

Instala direto no servidor (sem Docker) um proxy reverso NGINX com:

- **ModSecurity 3 + OWASP Core Rule Set 4**: bloqueia ataques comuns como SQL Injection, XSS e LFI.
- **Bloqueio por país**: só o Brasil e redes privadas (10/8, 172.16/12, 192.168/16, localhost…) passam; o resto recebe 403.
- **Bloqueio de datacenters**: IPs de nuvens e hospedagens (AWS, Azure, Locaweb, UOL Host, Equinix…) recebem 403, porque é de lá que vem boa parte dos bots.

### Sistemas suportados

| Sistema | Versões |
|---|---|
| Ubuntu | 24.04 ou mais novo |
| Debian | 12 ou mais novo |
| Rocky Linux / AlmaLinux / RHEL | 9 (usa o EPEL) |

Ubuntu 22.04 e Rocky 10 não têm o módulo ModSecurity do NGINX empacotado.

### Instalação

```bash
git clone https://github.com/crisostom0/waf-nginx.git
cd waf-nginx
sudo ./install.sh
```

Depois, aponte o WAF para a sua aplicação em `/etc/nginx/waf/backend.conf` (o padrão é `127.0.0.1:8080`) e aplique:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

O instalador:

- instala o NGINX e o módulo ModSecurity pelos pacotes da distribuição;
- baixa o OWASP CRS numa versão fixa e confere o checksum;
- no Ubuntu/Debian, desativa o site padrão do NGINX (ele também ocupa a porta 80);
- no Rocky/RHEL, libera o NGINX no SELinux para conectar no backend;
- abre as portas 80 e 443 no firewalld ou no ufw, se estiverem ativos;
- gera as listas de IPs do Brasil e dos datacenters e agenda a atualização diária.

Pode rodar o `install.sh` de novo para atualizar. Ele não sobrescreve `backend.conf`, `asn-datacenters.txt`, `exclusoes.conf` e `crs-setup.conf`.

### Onde fica cada coisa

| Arquivo no servidor | Para quê |
|---|---|
| `/etc/nginx/conf.d/waf.conf` | Servidor NGINX do WAF |
| `/etc/nginx/waf/backend.conf` | Endereço da aplicação protegida |
| `/etc/nginx/waf/redes-privadas.conf` | Redes sempre liberadas |
| `/etc/nginx/waf/geo-pais.conf` | Faixas de IP do Brasil (gerado, não edite) |
| `/etc/nginx/waf/asn-datacenters.txt` | Provedores (ASN) bloqueados |
| `/etc/nginx/waf/geo-datacenters.conf` | Faixas de IP desses provedores (gerado, não edite) |
| `/etc/nginx/modsec/modsecurity.conf` | Configuração do ModSecurity |
| `/etc/nginx/modsec/exclusoes.conf` | Exceções para falsos positivos |
| `/etc/nginx/modsec/crs-setup.conf` | Configuração do OWASP CRS |
| `/var/log/nginx/modsec/audit.log` | O que o WAF bloqueou e por quê |

### Listas de IP

Nenhuma das fontes exige conta ou chave:

- **País**: delegações públicas do [LACNIC](https://www.lacnic.net/), o registro de IPs da América Latina, que inclui o NIC.br.
- **Datacenters**: base gratuita [DB-IP Lite](https://db-ip.com) de IP para ASN (licença CC BY 4.0), atualizada mensalmente pelo DB-IP.

O timer `waf-atualiza-geo.timer` atualiza as duas listas uma vez por dia. Se uma fonte estiver fora do ar, a outra é atualizada mesmo assim; se o NGINX rejeitar uma lista nova, a anterior é mantida.

Para atualizar na hora:

```bash
sudo systemctl start waf-atualiza-geo.service
```

Para liberar outros países da América Latina, edite `--paises` em `/etc/systemd/system/waf-atualiza-geo.service` (ex.: `--paises BR,AR`) e rode `sudo systemctl daemon-reload`.

Essas faixas indicam onde o bloco de IP foi registrado, não onde o usuário está. Brasileiros usando VPN, proxy ou rede móvel estrangeira podem ser bloqueados.

### Bloqueio de datacenters

A lista de provedores fica em `/etc/nginx/waf/asn-datacenters.txt`, um ASN por linha. Depois de editar, aplique com:

```bash
sudo systemctl start waf-atualiza-geo.service
```

Cuidado com o que esse bloqueio também pega: monitoramentos (ex.: UptimeRobot), webhooks e integrações hospedados em nuvem, VPNs corporativas e empresas cuja saída de internet fica num datacenter. Se precisar liberar um desses, remova o provedor da lista. Nunca inclua a Cloudflare (AS13335) se o WAF ficar atrás dela.

### Falsos positivos

As rotas `/api/auth`, `/api/config` e `/api/info/` estão em modo só-detecção: o WAF registra, mas não bloqueia. Para descobrir o que está sendo bloqueado ou registrado:

```bash
sudo grep -oE 'id "[0-9]+"' /var/log/nginx/modsec/audit.log | sort | uniq -c | sort -rn
```

Com os IDs em mãos, crie exceções pontuais em `/etc/nginx/modsec/exclusoes.conf` (há um exemplo no arquivo) em vez de liberar rotas inteiras.

### HTTPS

Descomente o bloco HTTPS no fim de `/etc/nginx/conf.d/waf.conf` e ajuste os caminhos do certificado, ou use o Certbot (`certbot --nginx`).

### Comandos úteis

```bash
sudo nginx -t                              # valida a configuração
sudo systemctl reload nginx                # aplica mudanças
sudo tail -f /var/log/nginx/modsec/audit.log
systemctl list-timers waf-atualiza-geo.timer
```

### Referências

- IP to ASN Lite by [DB-IP](https://db-ip.com), licenciado sob [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

- https://nginx.org/en/docs/
- https://github.com/owasp-modsecurity/ModSecurity
- https://coreruleset.org/docs/

---

## 🇺🇸 English

# WAF with NGINX + ModSecurity

Installs directly on the host (no Docker) an NGINX reverse proxy with ModSecurity 3 + OWASP Core Rule Set 4, allowing only Brazil and private networks and blocking cloud/datacenter providers (everything else gets 403).

Supported: Ubuntu 24.04+, Debian 12+, Rocky Linux / AlmaLinux / RHEL 9 (via EPEL).

```bash
git clone https://github.com/crisostom0/waf-nginx.git
cd waf-nginx
sudo ./install.sh
```

Then set your application's address in `/etc/nginx/waf/backend.conf` (default `127.0.0.1:8080`) and run `sudo nginx -t && sudo systemctl reload nginx`.

Country ranges come from [LACNIC](https://www.lacnic.net/) delegation data; datacenter ranges come from the providers (ASNs) in `/etc/nginx/waf/asn-datacenters.txt`, using IP to ASN Lite by [DB-IP](https://db-ip.com) (CC BY 4.0). Both are refreshed daily by `waf-atualiza-geo.timer`, with no account needed. Blocked requests are logged to `/var/log/nginx/modsec/audit.log`; add targeted rule exclusions in `/etc/nginx/modsec/exclusoes.conf`.
