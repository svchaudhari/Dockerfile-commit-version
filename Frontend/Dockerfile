FROM node:18 AS build-stage
WORKDIR /app

# Set npm proxy
ARG NPM_PROXY=http://your-proxy-address:port
RUN npm config set proxy $NPM_PROXY && npm config set https-proxy $NPM_PROXY

# Ensure TLS 1.2+ is used
RUN npm config set registry https://registry.npmjs.org/
RUN npm config set strict-ssl true
ENV NODE_OPTIONS="--tls-min-v1.2"

# Install dependencies and build React app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# Use Nginx to serve the built files
FROM nginx:alpine AS production-stage
COPY --from=build-stage /app/build /usr/share/nginx/html

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
