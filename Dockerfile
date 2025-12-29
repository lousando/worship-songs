FROM oven/bun:1-debian

WORKDIR /app

COPY . .

RUN apt install curl -y
RUN curl -sfS https://dotenvx.sh | sh
RUN bun i --frozen-lockfile
RUN bun run build

CMD dotenvx run -f .env.production -- bun start