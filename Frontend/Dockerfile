# ----------------- Base Stage ----------------- #
# Use a lightweight Node.js image
FROM node:20-slim AS base-stage

# Set working directory
WORKDIR /app

# Set up proxy (if required)
ARG NPM_PROXY=http://192.0.2.12:8080
ENV HTTP_PROXY=$NPM_PROXY
ENV HTTPS_PROXY=$NPM_PROXY

# Set npm proxy (Remove if not needed)
RUN npm config set proxy $NPM_PROXY \
    && npm config set https-proxy $NPM_PROXY || true

# ----------------- Dependencies Stage ----------------- #
FROM base-stage AS dependencies-stage

# Copy only package files to install dependencies
COPY package*.json ./

# Install dependencies with production flag
RUN npm ci --only=production --silent

# ----------------- Build Stage ----------------- #
FROM base-stage AS build-stage

# Copy dependencies and source files
COPY --from=dependencies-stage /app/node_modules ./node_modules
COPY . .

# Build React app with production optimizations
RUN npm run build

# ----------------- Production Stage ----------------- #
FROM nginx:alpine AS production-stage

# Copy built React app to NGINX
COPY --from=build-stage /app/build /usr/share/nginx/html

# Add custom NGINX configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start NGINX server
CMD ["nginx", "-g", "daemon off;"]
