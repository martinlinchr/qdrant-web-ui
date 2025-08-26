FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build with Vite
RUN npm run build

# Install nginx and gettext (for envsubst) to act as a reverse proxy
RUN apk add --no-cache nginx gettext

# Create nginx main config
RUN cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    server {
        listen 3000;
        server_name localhost;
        
        # Serve the built React app
        location / {
            root /app/dist;
            try_files $uri $uri/ /index.html;
        }
        
        # Proxy API calls to your Qdrant database
        location /collections {
            proxy_pass $QDRANT_URL;
            proxy_set_header Host qdrant.martin-linde.com;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header api-key $QDRANT_API_KEY;
            proxy_ssl_verify off;
        }
        
        location /cluster {
            proxy_pass $QDRANT_URL;
            proxy_set_header Host qdrant.martin-linde.com;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header api-key $QDRANT_API_KEY;
            proxy_ssl_verify off;
        }
        
        location /telemetry {
            proxy_pass $QDRANT_URL;
            proxy_set_header Host qdrant.martin-linde.com;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header api-key $QDRANT_API_KEY;
            proxy_ssl_verify off;
        }
        
        location /issues {
            proxy_pass $QDRANT_URL;
            proxy_set_header Host qdrant.martin-linde.com;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header api-key $QDRANT_API_KEY;
            proxy_ssl_verify off;
        }
        
        location ~ ^.*$ {
            if ($request_uri ~ ^/(collections|cluster|telemetry|issues|snapshots)) {
                proxy_pass $QDRANT_URL$request_uri;
                proxy_set_header Host qdrant.martin-linde.com;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header api-key $QDRANT_API_KEY;
                proxy_ssl_verify off;
            }
        }
    }
}
EOF

# Create startup script
RUN cat > /app/start.sh << 'EOF'
#!/bin/sh

echo "Starting with QDRANT_URL: $QDRANT_URL"
echo "Starting with QDRANT_API_KEY: $QDRANT_API_KEY"

# Replace environment variables in nginx config
envsubst '$QDRANT_URL $QDRANT_API_KEY' < /etc/nginx/nginx.conf > /tmp/nginx.conf
mv /tmp/nginx.conf /etc/nginx/nginx.conf

echo "Nginx config updated, starting nginx..."

# Start nginx
exec nginx -g 'daemon off;'
EOF

RUN chmod +x /app/start.sh

# Expose port
EXPOSE 3000

# Start nginx with our config
CMD ["/app/start.sh"]
