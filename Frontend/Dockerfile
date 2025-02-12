# Stage 1: Build the React app
FROM node:23-alpine3.20 AS build-stage
WORKDIR /app

# Set npm proxy
ARG NPM_PROXY=http://192.0.2.12:8080
RUN npm config set proxy $NPM_PROXY && npm config set https-proxy $NPM_PROXY

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
