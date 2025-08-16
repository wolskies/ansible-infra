# GitLab Configuration for wolskinet.com

This project installs/runs self-hosted GitLab EE via the Docker setup method.  Specifically:

- GitLab EE run via Docker Compose
- TLS handled by reverse-proxy external to container (nginx or caddy)
- Exposed ports:
    - 8880 for GitLab Web Interface
    - 5050 for GitLab repository
    - 2222 for ssh access to Gitlab

## NGINX Reverse Proxy (Production)

This configuration requires `nginx` and `certbot` packages installed via package installer:

`sudo dnf install nginx certbot`

Follow certbot instructions to install/configure certbot-dns-cloudlflare and request certificate.  Be sure to select the 'nginx' installer.

At a minimum include the following in `/etc/nginx/nginx.conf`:

```
http {

    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot

    ssl_certificate /etc/letsencrypt/live/wolskinet.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/wolskinet.com/privkey.pem;

    server {
	listen 80;
        server_name  wolskinet.com www.wolskinet.com home.wolskinet.com;
        return 301 https://$host$request_uri;

    server {
	listen 443 ssl;
        server_name  gitlab.wolskinet.com;

        location / {
            proxy_pass http://localhost:8880/;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
```

## Caddy Configuration

This configuration assumes caddy is already configured for Letsencrypt certificates and auto-renewal.  Include the following in `/etc/caddy/Caddyfile` :

```
*.wolskinet.com {
	reverse_proxy 127.0.0.1:443
	tls /etc/caddy/fullchain.pem /etc/caddy/privkey.pem

	@gitlab host gitlab.wolskinet.com
	handle @gitlab {
		reverse_proxy localhost:8880
	}
}
```
