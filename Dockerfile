# ===== builder =====
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
# 依存キャッシュ用（pomが変わらなければ再利用される）
COPY pom.xml .
RUN mvn -q -e -DskipTests dependency:go-offline

# アプリ本体コピー＆ビルド
COPY src ./src
RUN mvn -q -DskipTests package

# ===== runtime =====
FROM eclipse-temurin:17-jre
WORKDIR /app
ENV TZ=Asia/Tokyo \
    JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" \
    SPRING_PROFILES_ACTIVE=prod

# ビルド成果物をコピー（アーティファクト名は実際のjar名に合わせて調整）
COPY --from=builder /app/target/todo-back-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080
# 健康確認がしやすいようにシャットダウンを待つ
STOPSIGNAL SIGTERM
ENTRYPOINT ["java","-jar","/app/app.jar"]
