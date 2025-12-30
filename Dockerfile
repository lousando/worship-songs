FROM node:24 AS build

WORKDIR /app

COPY . .

RUN corepack enable pnpm
RUN pnpm i --frozen-lockfile
RUN curl -sfS https://dotenvx.sh | sh
RUN dotenvx run -f .env.production -- pnpm run build

# =====================================================
FROM oven/bun:1-alpine AS final

WORKDIR /app

COPY --from=build /app /app

RUN apk add --no-cache curl && curl -sfS https://dotenvx.sh | sh

CMD dotenvx run -f .env.production -- bun start