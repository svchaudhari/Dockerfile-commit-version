# Stage 1: Build the React app
FROM node:23-alpine3.20 AS build
WORKDIR /app
ARG NPM_PROXY=http://192.0.2.12:8080
ARG NPM_HTTPS_PROXY=http://192.0.2.12:8080
RUN npm config set proxy $NPM_PROXY && npm config set proxy $NPM_HTTPS_PROXY

# Leverage caching by installing dependencies first
COPY package.json package-lock.json ./

RUN npm install --verbose

# Copy the rest of the application code and build for production
COPY . ./
RUN npm run build

# Stage 2: Development environment
FROM node:23-alpine3.20 AS development
WORKDIR /app

# Install dependencies again for development
COPY package.json package-lock.json ./
RUN npm install --verbose

# Copy the full source code
COPY . ./

# Expose port for the development server
EXPOSE 3000
CMD ["npm", "start"]

# Stage 3: Production environment
FROM nginx:alpine AS production

# Copy the production build artifacts from the build stage
COPY --from=build /app/build /usr/share/nginx/html

# Copy custom NGINX configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose the default NGINX port
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
