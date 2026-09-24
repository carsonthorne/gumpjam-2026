CREATE TABLE IF NOT EXISTS scores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  player_name TEXT NOT NULL,
  collection TEXT NOT NULL,
  level INTEGER NOT NULL,
  score INTEGER NOT NULL,
  metadata TEXT NOT NULL DEFAULT '{}',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_scores_global_rank
  ON scores (score DESC, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_scores_level_rank
  ON scores (collection, level, score DESC, created_at ASC);
