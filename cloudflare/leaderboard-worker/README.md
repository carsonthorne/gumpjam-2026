# Gumpjam Leaderboard Worker

Tiny Cloudflare Worker + D1 API for global highscores.

## Endpoints

- `GET /health`
- `GET /scores?limit=10`
- `GET /scores?collection=res://levels/wikipedia.txt&level=1&limit=10`
- `POST /scores`

Example score submission:

```json
{
  "playerName": "CARSON",
  "collection": "res://levels/wikipedia.txt",
  "level": 1,
  "score": 12345,
  "metadata": {
    "seconds": 91.4,
    "moves": 37
  }
}
```

The current ranking treats higher `score` as better. If you want fastest time or fewest moves, either invert the score in Godot or change the SQL ordering from `DESC` to `ASC`.

## Setup

Install dependencies:

```sh
npm install
```

Log into Cloudflare:

```sh
npx wrangler login
```

Create the D1 database:

```sh
npm run db:create
```

Copy the returned `database_id` into `wrangler.toml`, replacing `REPLACE_WITH_D1_DATABASE_ID`.

Initialize local D1:

```sh
npm run db:init:local
```

Run locally:

```sh
npm run dev
```

Initialize production D1:

```sh
npm run db:init:remote
```

Deploy:

```sh
npm run deploy
```

## Optional Submission Token

For a jam game, a public API is usually fine. If you want a lightweight speed bump against casual spam, set a secret:

```sh
npx wrangler secret put SUBMIT_TOKEN
```

Then include `"token": "your-token"` in score submissions. Do not treat this as strong anti-cheat for a public client build.
