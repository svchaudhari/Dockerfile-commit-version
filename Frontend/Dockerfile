# Use a stable Node.js version
FROM node:20-alpine AS build-stage

# Set working directory
WORKDIR /app

# Set up proxy (if required)
ARG NPM_PROXY=http://192.0.2.12:8080
ENV HTTP_PROXY=$NPM_PROXY
ENV HTTPS_PROXY=$NPM_PROXY

# Ensure CA certificates are installed with proxy
RUN export http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY && \
    apk update && apk add --no-cache ca-certificates && update-ca-certificates && apk add --no-cache curl

# Set npm proxy (Remove if not needed)
RUN npm config set proxy $NPM_PROXY && npm config set https-proxy $NPM_PROXY || true

# Ensure TLS 1.2+ is used
RUN npm config set registry https://registry.npmjs.org/ \
    && npm config set strict-ssl true
ENV NODE_OPTIONS="--tls-min-v1.2"

# Copy package files separately for better caching
COPY package.json package-lock.json ./

# Run npm install with SSL workarounds
RUN npm cache clean --force && npm install --verbose

# Copy source files and build the React app
COPY . .
RUN npm run build

# ----------------- Production Stage ----------------- #
FROM nginx:alpine AS production-stage

# Copy built React app from build-stage
COPY --from=build-stage /app/build /usr/share/nginx/html

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80 for web access
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
