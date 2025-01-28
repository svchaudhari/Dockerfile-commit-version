# Build stage
FROM svchaudhari/alpine-maven-builder-jdk17:master-1 AS build
ARG WORK_DIR
WORKDIR /app

COPY settings.xml /root/.m2/settings.xml
COPY ${WORK_DIR}/pom.xml ./pom.xml
COPY ${WORK_DIR}/src ./src

# Clean Maven cache to avoid corruption
RUN rm -rf /root/.m2/repository

# Pre-fetch dependencies
RUN mvn dependency:go-offline -B

# Build application
RUN mvn clean package -DskipTests -X

# Runtime stage
FROM openjdk:17-alpine
EXPOSE 8080
WORKDIR /opt/egov
COPY --from=build /app/target/*.jar /opt/egov/
COPY --from=build /app/start.sh /opt/egov/
RUN chmod +x /opt/egov/start.sh
CMD ["/opt/egov/start.sh"]
