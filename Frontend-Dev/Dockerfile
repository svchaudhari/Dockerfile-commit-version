# Stage 1: Build the React app
# Author: Swapnil
FROM node:20-alpine AS build
WORKDIR /app

ARG NPM_PROXY=http://192.0.2.12:8080
ENV HTTP_PROXY=$NPM_PROXY
ENV HTTPS_PROXY=$NPM_PROXY
# ENV NODE_OPTIONS=--max-old-space-size=4096

# Leverage caching by installing dependencies first
COPY package.json package-lock.json ./

RUN export NODE_OPTIONS=--openssl-legacy-provider

RUN export http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY && \
    npm install --verbose

# Copy the rest of 
COPY . ./
RUN npm run build

# Stage 2: Development environment
FROM node:20-alpine AS development
WORKDIR /app

# Install dependencies again for development
COPY package.json package-lock.json ./


RUN export NODE_OPTIONS=--openssl-legacy-provider

RUN export http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY && \
    npm install --verbose

# Copy the full source code
COPY . ./

# Expose port for the development server
EXPOSE 3000
# CMD ["npm", "start"]

# Stage 3: Production environment
FROM nginx:alpine AS production

# Copy the production build artifacts from the build stage
COPY --from=build /app/build /usr/share/nginx/html

# Copy custom NGINX configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Set correct permissions for Nginx
RUN chown -R nginx:nginx /usr/share/nginx/html && chmod -R 755 /usr/share/nginx/html

# Expose the default NGINX port
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
