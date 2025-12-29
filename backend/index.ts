import { Hono } from "hono";
import { cors } from "hono/cors";
import { serveStatic } from "hono/bun";
import { createClient } from "@libsql/client";

export const turso = createClient({
  url: process.env.TURSO_DATABASE_URL,
  authToken: process.env.TURSO_AUTH_TOKEN,
});

const app = new Hono();

app
  .use(cors())
  .use("/*", serveStatic({ root: "./dist" }))
  .get("/api/health", (c) => {
    return c.text("OK");
  })
  .get("/api/songs", async (c) => {
    const { rows } = await turso.execute({
      sql: "SELECT id,page,name FROM songs ORDER BY page",
      args: [],
    });

    return c.json(rows);
  });

export default {
  port: 8080,
  fetch: app.fetch,
};
