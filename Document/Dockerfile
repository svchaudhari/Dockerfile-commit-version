# Build stage
FROM svchaudhari/a  lpine-maven-builder-jdk17:master-1 AS build
ARG WORK_DIR
WORKDIR /app

COPY settings.xml /root/.m2/settings.xml

# Copy the project files
COPY ${WORK_DIR}/pom.xml ./pom.xml
COPY start.sh ./start.sh

# Clean Maven cache to avoid corruption
RUN rm -rf /root/.m2/repository

# Not useful for stateless builds
RUN mvn -B dependency:go-offline

COPY ${WORK_DIR}/src ./src

RUN mvn clean package -DskipTests -U

# ----------------- Runtime Stage ----------------- #
FROM openjdk:17-alpine

# Set proxy environment variables
ARG NPM_PROXY=http://192.0.2.12:8080
ENV HTTP_PROXY=$NPM_PROXY
ENV HTTPS_PROXY=$NPM_PROXY

# Ensure curl is installed using the proxy
# RUN export http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY && \
#     apk update && \
#     apk add --no-cache curl && \
#     rm -rf /var/cache/apk/*

EXPOSE 8080

WORKDIR /opt/egov

# Copy application and startup script from the build stage
COPY --from=build /app/target/*.jar /opt/egov/
COPY --from=build /app/start.sh /opt/egov/

# Make the startup script executable
RUN chmod +x /opt/egov/start.sh

# Start the application
CMD ["/opt/egov/start.sh"]
