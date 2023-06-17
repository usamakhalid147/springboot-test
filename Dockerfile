# Use Eclipse Temurin for base image.
FROM eclipse-temurin:17 AS build

# Set the working directory.
WORKDIR /application

# Copy maven executable to the image
COPY mvnw .
COPY .mvn .mvn

# Copy the pom.xml file
COPY pom.xml .

# Build all the dependencies in preparation to go offline. 
# This is a separate step so the dependencies will be cached unless 
# the pom.xml file has changed.
RUN chmod +x ./mvnw
RUN ./mvnw dependency:go-offline -B

# Copy the project source
COPY src src

# Package the application
RUN ./mvnw package -DskipTests
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

# Multi-stage build: create the Docker final image
FROM eclipse-temurin:17

ARG DEPENDENCY=/application/target/dependency

# Copies the project dependencies from the build stage
COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app

# Execute the application
ENTRYPOINT ["java","-cp","app:app/lib/*","com.example.demo.DemoApplication"]
