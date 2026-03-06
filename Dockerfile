FROM oven/bun:1 AS build

WORKDIR /app

COPY . .

RUN bun ci
RUN bun run build
RUN rm -rf node_modules

# =====================================================
FROM golang:1.25.4-alpine AS final

LABEL org.opencontainers.image.source=https://github.com/lousando/worship-songs

EXPOSE 8080

WORKDIR /app

COPY --from=build /app /app

RUN apk add --no-cache curl mise
RUN go build -o ./bin/main .

CMD ["mise", "x", "--", "./bin/main"]