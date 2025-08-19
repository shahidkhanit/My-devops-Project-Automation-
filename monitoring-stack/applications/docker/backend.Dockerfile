FROM openjdk:17-jdk-slim AS build
WORKDIR /app
COPY applications/backend/pom.xml ./
COPY applications/backend/src ./src
RUN apt-get update && apt-get install -y maven
RUN mvn clean package -DskipTests

FROM openjdk:17-jre-slim
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]