FROM eclipse-temurin:17-jdk-jammy as builder
WORKDIR /app

COPY ./app .

RUN ./mvnw clean install
 
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
EXPOSE 8081
COPY --from=builder ./app/target/*.jar ./app.jar
CMD ["java", "-jar", "app.jar"]
