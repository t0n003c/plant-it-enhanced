# syntax=docker/dockerfile:1.7

# Build Java and Flutter on the builder architecture. Their outputs are
# platform-independent, so the same stages can feed AMD64 and ARM64 runtimes.
ARG MAVEN_BUILDER=maven:3.9.11-eclipse-temurin-21-alpine@sha256:922927df2c662cdd47ddb116443d6bec4696cfae3de1a0ddac8fcc7b87ce61ae
ARG FLUTTER_BUILDER=ghcr.io/cirruslabs/flutter:3.24.3@sha256:eacde71c879275ed3b11484b1a2a67ca77c4ed461938c3b59b57334f26af0e82
ARG RUNTIME_BASE=eclipse-temurin:21-jre-alpine@sha256:3f08b13888f595cc49edabea7250ba69499ba25602b267da591720769400e08c


FROM --platform=$BUILDPLATFORM ${MAVEN_BUILDER} AS backend-build
WORKDIR /work/backend

COPY backend/pom.xml ./pom.xml
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -ntp -DskipTests -Djacoco.skip=true dependency:go-offline

COPY backend/src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn -B -ntp -DskipTests -Djacoco.skip=true package && \
    cp target/*.jar /work/app.jar


FROM --platform=$BUILDPLATFORM ${FLUTTER_BUILDER} AS frontend-build
WORKDIR /work/frontend

COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN --mount=type=cache,target=/root/.pub-cache flutter pub get

COPY frontend ./
RUN --mount=type=cache,target=/root/.pub-cache flutter build web --release


FROM ${RUNTIME_BASE} AS runtime

LABEL org.opencontainers.image.source="https://github.com/t0n003c/plant-it-enhanced" \
      org.opencontainers.image.description="Self-hosted plant care, trusted search, and private offline trail journal" \
      org.opencontainers.image.licenses="GPL-3.0-only"

RUN apk add --no-cache nginx netcat-openbsd && \
    mkdir -p /opt/app/backend /opt/app/frontend/build/web /run/nginx

COPY --from=backend-build /work/app.jar /opt/app/backend/app.jar
COPY --from=frontend-build /work/frontend/build/web /opt/app/frontend/build/web
COPY deployment/start.sh /opt/app/start.sh
COPY deployment/nginx.conf /etc/nginx/nginx.conf

RUN chmod 0755 /opt/app/start.sh

WORKDIR /opt/app/frontend

EXPOSE 8080 3000

STOPSIGNAL SIGTERM

CMD ["/opt/app/start.sh"]
