# Stage 1: Build the React app
FROM node:23-alpine3.20 AS build
WORKDIR /app
ARG NPM_PROXY=http://192.0.2.12:8080
ARG NPM_HTTPS_PROXY=http://192.0.2.12:8080
RUN npm config set proxy $NPM_PROXY && npm config set https-proxy $NPM_HTTPS_PROXY

# Set environment variables
ENV BASE_URL=http://10.192.111.177:30004 \
    ADMIN_SERVICE=http://10.192.111.177:30004/admin \
    WORKFLOW_SERVICE=http://10.192.111.177:30004/workflow \
    RCMS_SERVICE=http://10.192.111.177:30004/rcms \
    FPS_SERVICE=http://10.192.111.177:30004/fps \
    NOTIFY_SERVICE=http://10.192.111.177:30004/notify \
    DOCUMENT_SERVICE=http://10.192.111.177:30004/doc \
    VITE_API_BASE_RATION_CARD_URL=http://10.192.111.177:30004/rcms \
    VITE_API_BASE_DASHBOARD_URL=http://10.192.111.177:30004/workflow \
    VITE_API_BASE_RATION_CARD_PERSONAL_DETAILS_SERVICE='/personalDetails' \
    VITE_API_BASE_RATION_CARD_OTHERS_SERVICE='/others' \
    VITE_API_BASE_RATION_CARD_ADDRESS_SERVICE='/address' \
    VITE_API_SERVICES=auth \
    VITE_API_VERSION=v1 \
    VITE_API_BASE_MASTER_MANAGEMENT_SERVICE=http://10.192.111.177:30004/admin \
    VITE_API_BASE_MASTER_MANAGEMENT_STATE_SERVICE='/state' \
    VITE_API_BASE_LOGIN_SERVICE=http://10.192.111.177:30004/admin \
    VITE_API_AUTH_SERVICE="auth" \
    VITE_API_GENDER_SERVICE="/gender" \
    VITE_API_DISABLITY_SERVICE="/disability" \
    VITE_API_RELATIONSHIP_SERVICE="/relationship" \
    VITE_API_APPLICATION_SERVICE="/application" \
    VITE_API_APPLICATION_INBOX_SERVICE="/application/inbox" \
    VITE_API_CASTE_CATEGORY_SERVICE="/casteCategory"

# Install dependencies
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
