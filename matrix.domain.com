# 1) Redirect all HTTP traffic on port 80 to HTTPS (443)
server {
    listen 80;
    server_name matrix.xaas.ir;

    # Return a 301 redirect to the corresponding HTTPS URL
    return 301 https://$host$request_uri;
}

# 2) Serve content via HTTPS on port 443
server {
    listen 443 ssl;
    server_name matrix.xaas.ir;

    # SSL configuration
    ssl_certificate /etc/nginx/ssl/fullchain1.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey1.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Proxy to Element Web (as in your example)
    location / {
        proxy_pass http://element-web:80;
       # proxy_set_header Host $host;
       # proxy_set_header X-Forwarded-For $remote_addr;
       # proxy_set_header X-Forwarded-Proto https;

       add_header X-Frame-Options SAMEORIGIN;
       add_header X-Content-Type-Options nosniff;
       add_header X-XSS-Protection "1; mode=block";
       add_header Content-Security-Policy "frame-ancestors 'none'";
    }

    access_log /var/log/nginx/matrix.xaas.ir.access.log;
    error_log  /var/log/nginx/matrix.xaas.ir.error.log;
}