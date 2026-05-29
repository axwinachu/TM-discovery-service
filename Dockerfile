# ── Stage 1: BUILD ──────────────────────────────────────────────
FROM maven:3.9.6-eclipse-temurin-17 AS builder

WORKDIR /app

# Copy pom.xml first — Docker caches this layer
# Maven deps are NOT re-downloaded if only source code changes
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Now copy source and build the JAR
COPY src ./src
RUN mvn clean package -DskipTests -B

# ── Stage 2: RUNTIME ────────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Copy ONLY the JAR from builder stage
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8761

ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-jar", "app.jar"]