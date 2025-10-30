import { env } from "cloudflare:workers";
import { Elysia, type Context } from "elysia";
import { cors } from '@elysiajs/cors'

import { createClient } from "@libsql/client";

export const turso = createClient({
    url: env.TURSO_DATABASE_URL,
    authToken: env.TURSO_AUTH_TOKEN,
});

const app = new Elysia({ aot: false, prefix: "/api" })
    .use(cors())
    .get("/songs", async (context: Context) => {
        const { rows } = await turso.execute({
            sql: "SELECT id,page,name FROM songs ORDER BY page",
            args: [],
        });

        return rows;
    })

export default {
    fetch(request: Request) {
        return app.fetch(request);
    },
};
