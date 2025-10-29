import { env } from "cloudflare:workers";
import { Elysia, type Context } from "elysia";

import { createClient } from "@libsql/client";

export const turso = createClient({
    url: env.TURSO_DATABASE_URL,
    authToken: env.TURSO_AUTH_TOKEN,
});

const app = new Elysia({ aot: false, prefix: "/api" })
    .get("/songs", async (context: Context) => {
        const { rows } = await turso.execute({
            sql: "SELECT page,name FROM songs",
            args: [],
        });

        return rows;
    })

export default {
    fetch(request: Request) {
        return app.fetch(request);
    },
};
