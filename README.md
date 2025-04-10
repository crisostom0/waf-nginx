## 🇧🇷 Português do Brasil

# WAF com NGINX utilizando Docker 🇧🇷

[![Docker](https://img.shields.io/badge/docker-ready-blue?logo=docker)](https://www.docker.com/)
[![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)](https://github.com/crisostom0/waf-nginx)

Este repositório configura um servidor NGINX com suporte ao ModSecurity (WAF - Web Application Firewall) utilizando Docker e Docker Compose.

## 📌 O que é um WAF?

Um Web Application Firewall (WAF) protege aplicações web contra ataques comuns como XSS, SQL Injection, e muito mais, ao filtrar e monitorar o tráfego HTTP.

## 📁 Estrutura do Projeto

- `config/`: Arquivos de configuração do NGINX
- `modsec/`: Regras e configurações do ModSecurity
- `Dockerfile.nginx`: Dockerfile que monta o NGINX com WAF
- `docker-compose.yml`: Orquestração dos containers

## 🚀 Como Utilizar

### Pré-requisitos

- Docker
- Docker Compose

### Passos

```bash
git clone https://github.com/crisostom0/waf-nginx.git
cd waf-nginx
docker build -t waf-nginx -f Dockerfile.nginx .
docker-compose up -d
```

Acesse via navegador: http://localhost

## 🛠️ Personalização

- Edite arquivos em `config/` para ajustar o NGINX
- Adicione regras personalizadas em `modsec/`

## 🧪 Comandos úteis

```bash
docker-compose logs -f
docker-compose restart
docker-compose down
```

## 🧯 Problemas Comuns

- Verifique conflitos de porta (ex: 80)
- Corrija permissões dos volumes se necessário
- Crie a network proxy

## 🧾 Referências

- https://nginx.org/en/docs/
- https://www.modsecurity.org/documentation.html

---

## 🇺🇸 English (US)

# WAF with NGINX using Docker 🇺🇸

[![Docker](https://img.shields.io/badge/docker-ready-blue?logo=docker)](https://www.docker.com/)
[![Status](https://img.shields.io/badge/status-in%20development-yellow)](https://github.com/crisostom0/waf-nginx)

This repository sets up an NGINX server with ModSecurity (WAF - Web Application Firewall) using Docker and Docker Compose.

## 📌 What is a WAF?

A Web Application Firewall (WAF) protects web apps against common attacks like XSS, SQL Injection, etc., by filtering and monitoring HTTP traffic.

## 📁 Project Structure

- `config/`: NGINX configuration files
- `modsec/`: ModSecurity rules and settings
- `Dockerfile.nginx`: Dockerfile to build NGINX with WAF
- `docker-compose.yml`: Docker container orchestration

## 🚀 How to Use

### Requirements

- Docker
- Docker Compose

### Steps

```bash
git clone https://github.com/crisostom0/waf-nginx.git
cd waf-nginx
docker build -t waf-nginx -f Dockerfile.nginx .
docker-compose up -d
```

Access in browser: http://localhost

## 🛠️ Customization

- Edit `config/` files to adjust NGINX behavior
- Add custom rules in `modsec/`

## 🧪 Useful Commands

```bash
docker-compose logs -f
docker-compose restart
docker-compose down
```

## 🧯 Common Issues

- Check for port conflicts (e.g., 80)
- Fix volume permissions if needed
- Create the proxy network

## 🧾 References

- https://nginx.org/en/docs/
- https://www.modsecurity.org/documentation.html
