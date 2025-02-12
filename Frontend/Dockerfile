# Stage 1: Build the React app
FROM node:23-alpine3.20 AS build

ARG NPM_PROXY=http://192.0.2.12:8080
ARG NPM_HTTPS_PROXY=http://192.0.2.12:8080
RUN npm config set proxy $NPM_PROXY && npm config set proxy $NPM_HTTPS_PROXY
WORKDIR /app

# Debug: Ensure directory is created
RUN mkdir -p /app && ls -l /


# Copy package.json and install dependencies first (leveraging cache)
COPY package.json package-lock.json ./

COPY package.json package-lock.json ./
RUN export NODE_OPTIONS=--openssl-legacy-provider
RUN npm install --verbose

# Copy the rest of the app and build for production
COPY . ./
RUN npm run build

# Debug: List contents of /app/build

# Stage 2: Development environment
FROM node:23-alpine3.20 AS development
WORKDIR /app

# Copy package.json and install dependencies again
COPY package.json package-lock.json ./
RUN export NODE_OPTIONS=--openssl-legacy-provider
RUN npm install --verbose

# Copy the full source code
COPY . ./

# Expose port for the development server
EXPOSE 3000

# Stage 3: Production environment
FROM nginx:alpine AS production

# Debug: Ensure nginx default.conf is copied
RUN mkdir -p /usr/share/nginx/html && ls -l /usr/share/nginx/html

# Copy the production build artifacts from the build stage
COPY --from=build /app/build /usr/share/nginx/html

# Copy custom NGINX configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Debug: Verify files inside nginx html directory
RUN ls -l /usr/share/nginx/html

# Expose the default NGINX port
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
