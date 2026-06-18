-- ════════════════════════════════════════════════════════════════════════
--  Veriify — Supabase schema provisioning
--  Run this ONCE in the Supabase dashboard → SQL Editor, as the project
--  owner (the built-in postgres role). It is idempotent — safe to re-run.
--
--  Why: the app connects with a least-privilege role (veriify_app) that has
--  NO DDL rights, so it can't create tables or add columns itself. This
--  script provisions the schema and grants veriify_app exactly what it needs.
-- ════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    salt VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP,
    interview_count INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS interview_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(255),
    company VARCHAR(255),
    round_type VARCHAR(100),
    interviewer_name VARCHAR(255),
    interviewer_title VARCHAR(255),
    overall_score FLOAT,
    verdict VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    report JSONB
);

-- Bring older/existing tables up to date (these two columns were added later).
ALTER TABLE interview_history ADD COLUMN IF NOT EXISTS interviewer_name VARCHAR(255);
ALTER TABLE interview_history ADD COLUMN IF NOT EXISTS interviewer_title VARCHAR(255);

-- Indexes (foreign-key / lookup columns; email & token already unique-indexed).
CREATE INDEX IF NOT EXISTS idx_sessions_user_id   ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_history_user_id    ON interview_history(user_id);
CREATE INDEX IF NOT EXISTS idx_history_created_at ON interview_history(created_at DESC);

-- Least-privilege grants for the app role (no DDL).
GRANT USAGE ON SCHEMA public TO veriify_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO veriify_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO veriify_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO veriify_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO veriify_app;
