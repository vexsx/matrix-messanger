server {
    listen 443 ssl;
    listen [::]:443 ssl;

    # For the federation port
    listen 8008 ssl default_server;
    listen [::]:8008 ssl default_server;

    # SSL configuration
    ssl_certificate /etc/nginx/ssl/fullchain1.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey1.pem;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    server_name matrix-srv.xaas.ir;

    location ~ ^(/_matrix|/_synapse/client) {
        # note: do not add a path (even a single /) after the port in `proxy_pass`,
        # otherwise nginx will canonicalise the URI and cause signature verification
        # errors.
        proxy_pass http://synapse:8008;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Content-Security-Policy "frame-ancestors 'self'";

        #add_header X-Frame-Options SAMEORIGIN;
        #add_header 'Access-Control-Allow-Origin' '*';
        #add_header 'Access-Control-Allow-Methods' '*';
        #add_header 'Access-Control-Allow-Headers' 'Authorization, Origin, X-Requested-With, Content-Type, Accept';
        #add_header X-Content-Type-Options nosniff;
        ##add_header X-XSS-Protection "1; mode=block";
        #add_header Content-Security-Policy "frame-ancestors 'none'";
        # Nginx by default only allows file uploads up to 1M in size
        # Increase client_max_body_size to match max_upload_size defined in homeserver.yaml
        client_max_body_size 50M;

    # Synapse responses may be chunked, which is an HTTP/1.1 feature.
    proxy_http_version 1.1;
    }
}
#