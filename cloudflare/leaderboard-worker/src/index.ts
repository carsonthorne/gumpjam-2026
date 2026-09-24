export interface Env {
  DB: D1Database;
  ALLOWED_ORIGIN?: string;
  SUBMIT_TOKEN?: string;
}

type SubmitScoreBody = {
  playerName?: unknown;
  collection?: unknown;
  level?: unknown;
  score?: unknown;
  metadata?: unknown;
  token?: unknown;
};

const JSON_HEADERS = {
  "content-type": "application/json; charset=utf-8",
};

export default {
  async fetch(request, env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return withCors(new Response(null, { status: 204 }), env);
    }

    try {
      if (request.method === "GET" && url.pathname === "/") {
        return json({
          ok: true,
          service: "gumpjam-leaderboard",
          endpoints: ["GET /health", "GET /scores", "POST /scores"],
        }, env);
      }

      if (request.method === "GET" && url.pathname === "/health") {
        return json({ ok: true }, env);
      }

      if (request.method === "GET" && url.pathname === "/scores") {
        return listScores(url, env);
      }

      if (request.method === "POST" && url.pathname === "/scores") {
        return submitScore(request, env);
      }

      return json({ error: "Not found" }, env, 404);
    } catch (error) {
      console.error(error);
      return json({ error: "Internal server error" }, env, 500);
    }
  },
} satisfies ExportedHandler<Env>;

async function listScores(url: URL, env: Env): Promise<Response> {
  const collection = optionalString(url.searchParams.get("collection"), 120);
  const level = optionalInt(url.searchParams.get("level"), 1, 9999);
  const limit = optionalInt(url.searchParams.get("limit"), 1, 100) ?? 10;

  let query = `
    SELECT player_name AS playerName, collection, level, score, metadata, created_at AS createdAt
    FROM scores
  `;
  const bindings: Array<string | number> = [];

  if (collection !== null && level !== null) {
    query += " WHERE collection = ? AND level = ?";
    bindings.push(collection, level);
  }

  query += " ORDER BY score DESC, created_at ASC LIMIT ?";
  bindings.push(limit);

  const { results } = await env.DB.prepare(query).bind(...bindings).all();

  return json({
    scores: results.map((row) => ({
      ...row,
      metadata: parseMetadata(row.metadata),
    })),
  }, env);
}

async function submitScore(request: Request, env: Env): Promise<Response> {
  const body = await request.json<SubmitScoreBody>().catch(() => null);
  if (body === null) {
    return json({ error: "Invalid JSON" }, env, 400);
  }

  if (env.SUBMIT_TOKEN && body.token !== env.SUBMIT_TOKEN) {
    return json({ error: "Unauthorized" }, env, 401);
  }

  const playerName = optionalString(body.playerName, 24);
  const collection = optionalString(body.collection, 120);
  const level = optionalInt(body.level, 1, 9999);
  const score = optionalInt(body.score, 0, 2147483647);

  if (playerName === null || collection === null || level === null || score === null) {
    return json({ error: "playerName, collection, level, and score are required" }, env, 400);
  }

  const metadata = serializeMetadata(body.metadata);

  await env.DB.prepare(`
    INSERT INTO scores (player_name, collection, level, score, metadata)
    VALUES (?, ?, ?, ?, ?)
  `).bind(playerName, collection, level, score, metadata).run();

  return json({ ok: true }, env, 201);
}

function optionalString(value: unknown, maxLength: number): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const trimmed = value.trim();
  if (trimmed.length < 1 || trimmed.length > maxLength) {
    return null;
  }

  return trimmed;
}

function optionalInt(value: unknown, min: number, max: number): number | null {
  const parsed = typeof value === "number" ? value : Number(value);
  if (!Number.isInteger(parsed) || parsed < min || parsed > max) {
    return null;
  }

  return parsed;
}

function serializeMetadata(value: unknown): string {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return "{}";
  }

  return JSON.stringify(value).slice(0, 1000);
}

function parseMetadata(value: unknown): unknown {
  if (typeof value !== "string") {
    return {};
  }

  try {
    return JSON.parse(value);
  } catch {
    return {};
  }
}

function json(body: unknown, env: Env, status = 200): Response {
  return withCors(Response.json(body, { status, headers: JSON_HEADERS }), env);
}

function withCors(response: Response, env: Env): Response {
  const headers = new Headers(response.headers);
  headers.set("access-control-allow-origin", env.ALLOWED_ORIGIN || "*");
  headers.set("access-control-allow-methods", "GET, POST, OPTIONS");
  headers.set("access-control-allow-headers", "content-type");
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}
