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

# Install nginx to act as a reverse proxy
RUN apk add --no-cache nginx

# Create nginx config that proxies API calls to your Qdrant instance
RUN mkdir -p /etc/nginx/conf.d
RUN cat > /etc/nginx/conf.d/default.conf << 'EOF'
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
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header api-key $QDRANT_API_KEY;
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, api-key, Authorization";
    }
    
    location /cluster {
        proxy_pass $QDRANT_URL;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header api-key $QDRANT_API_KEY;
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, api-key, Authorization";
    }
    
    location /telemetry {
        proxy_pass $QDRANT_URL;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header api-key $QDRANT_API_KEY;
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, api-key, Authorization";
    }
    
    location /issues {
        proxy_pass $QDRANT_URL;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header api-key $QDRANT_API_KEY;
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
        add_header Access-Control-Allow-Headers "Content-Type, api-key, Authorization";
    }
    
    # Handle preflight OPTIONS requests
    location ~ ^/(collections|cluster|telemetry|issues) {
        if ($request_method = 'OPTIONS') {
            add_header Access-Control-Allow-Origin *;
            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header Access-Control-Allow-Headers "Content-Type, api-key, Authorization";
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 200;
        }
    }
}
EOF

# Create startup script
RUN cat > /app/start.sh << 'EOF'
#!/bin/sh

# Replace environment variables in nginx config
envsubst '$QDRANT_URL $QDRANT_API_KEY' < /etc/nginx/conf.d/default.conf > /tmp/nginx.conf
mv /tmp/nginx.conf /etc/nginx/conf.d/default.conf

# Start nginx
exec nginx -g 'daemon off;'
EOF

RUN chmod +x /app/start.sh

# Expose port
EXPOSE 3000

# Start nginx with our config
CMD ["/app/start.sh"]
