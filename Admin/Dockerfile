# Build stage
FROM svchaudhari/alpine-maven-builder-jdk17:master-1 AS build
ARG WORK_DIR
WORKDIR /app

COPY settings.xml /root/.m2/settings.xml

# Copy the project files
COPY ${WORK_DIR}/pom.xml ./pom.xml

COPY start.sh ./start.sh

# Install curl in the build image
#RUN apk add --no-cache curl && \
#rm -rf /var/cache/apk/*

# Clean Maven cache to avoid corruption
RUN rm -rf /root/.m2/repository

# Not useful for stateless builds
RUN mvn -B dependency:go-offline

COPY ${WORK_DIR}/src ./src

RUN export http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY && apk add --no-cache curl && \
    rm -rf /var/cache/apk/*
    
RUN mvn clean package -DskipTests -U





# Create runtime image
FROM openjdk:17-alpine

# Install curl in the runtime image
RUN export http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY && apk add --no-cache curl && \
    rm -rf /var/cache/apk/*


EXPOSE 8080

WORKDIR /opt/egov

# Copy application and startup script from the build stage
COPY --from=build /app/target/*.jar /opt/egov/
COPY --from=build /app/start.sh /opt/egov/

# Make the startup script executable
RUN chmod +x /opt/egov/start.sh

# Start the application
CMD ["/opt/egov/start.sh"]
