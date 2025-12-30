FROM node:24 AS build

WORKDIR /app

COPY . .

RUN pnpm i --frozen-lockfile
RUN dotenvx run -f .env.production -- pnpm run build

# =====================================================
FROM oven/bun:1-alpine AS final

WORKDIR /app

COPY --from=build /app/node_modules /app/node_modules
COPY --from=build /app/.env.production /app/.env.production

RUN apk add --no-cache curl && curl -sfS https://dotenvx.sh | sh

CMD dotenvx run -f .env.production -- bun start