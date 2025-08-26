FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (including devDependencies needed for build)
RUN npm ci

# Copy source code
COPY . .

# Build with Vite
RUN npm run build

# Install serve globally to host the built files
RUN npm install -g serve

# Expose port
EXPOSE 3000

# Serve the built files from the dist directory (Vite default)
CMD ["serve", "-s", "dist", "-l", "3000"]
