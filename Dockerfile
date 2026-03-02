FROM node:24 AS build

WORKDIR /app

COPY . .

RUN corepack enable pnpm
RUN pnpm i --frozen-lockfile
RUN curl -sfS https://dotenvx.sh | sh
RUN dotenvx run -f .env.production -- pnpm run build
RUN rm -rf node_modules

# =====================================================
FROM golang:1.25.4-alpine AS final

EXPOSE 8080

WORKDIR /app

COPY --from=build /app /app

RUN apk add --no-cache curl && curl -sfS https://dotenvx.sh | sh
RUN go build -o ./bin/main .

CMD dotenvx run -f .env.production -- ./bin/main