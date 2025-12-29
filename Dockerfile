FROM oven/bun:1-alpine

WORKDIR /app

COPY . .

RUN apk add --no-cache curl
RUN curl -sfS https://dotenvx.sh | sh
RUN bun i --frozen-lockfile
RUN dotenvx run -f .env.production -- bun run build

CMD dotenvx run -f .env.production -- bun start