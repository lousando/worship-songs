FROM oven/bun:1 AS build

WORKDIR /app

COPY . .

RUN bun ci
RUN bun run build
RUN rm -rf node_modules

# =====================================================
FROM golang:1.25.4-trixie AS final

LABEL org.opencontainers.image.source=https://github.com/lousando/worship-songs

EXPOSE 8080

WORKDIR /app

COPY --from=build /app /app

ENV MISE_DATA_DIR="/mise"
ENV MISE_CONFIG_DIR="/mise"
ENV MISE_CACHE_DIR="/mise/cache"
ENV MISE_INSTALL_PATH="/usr/local/bin/mise"
ENV PATH="/mise/shims:$PATH"
ENV MISE_VERSION="v2026.3.4"

RUN apt-get install -y curl
RUN curl https://mise.run | sh
RUN mise trust # trust the mise.toml file
RUN go build -o ./bin/main .

CMD ["mise", "x", "--no-prepare", "--", "./bin/main"]