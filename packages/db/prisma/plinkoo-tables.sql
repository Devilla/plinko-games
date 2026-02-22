-- Create Plinkoo tables alongside existing app tables (no drops).
-- Run once; safe to re-run with IF NOT EXISTS.

DO $$ BEGIN
  CREATE TYPE "Game" AS ENUM ('blackjack', 'dice', 'keno', 'mines', 'roulette');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS "plinkoo_users" (
  "id" TEXT NOT NULL,
  "googleId" TEXT,
  "email" TEXT NOT NULL,
  "name" TEXT,
  "password" TEXT,
  "picture" TEXT,
  "balance" TEXT NOT NULL DEFAULT '1000000',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "plinkoo_users_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "plinkoo_users_googleId_key" ON "plinkoo_users"("googleId");
CREATE UNIQUE INDEX IF NOT EXISTS "plinkoo_users_email_key" ON "plinkoo_users"("email");

CREATE TABLE IF NOT EXISTS "provably_fair_states" (
  "id" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "serverSeed" TEXT NOT NULL,
  "clientSeed" TEXT NOT NULL,
  "hashedServerSeed" TEXT NOT NULL DEFAULT '',
  "nonce" INTEGER NOT NULL,
  "revealed" BOOLEAN NOT NULL DEFAULT false,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "provably_fair_states_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "provably_fair_states_userId_revealed_hashedServerSeed_idx"
  ON "provably_fair_states"("userId", "revealed", "hashedServerSeed");

CREATE TABLE IF NOT EXISTS "bets" (
  "id" TEXT NOT NULL,
  "betId" BIGSERIAL NOT NULL,
  "userId" TEXT NOT NULL,
  "game" "Game" NOT NULL,
  "betAmount" INTEGER NOT NULL,
  "payoutAmount" INTEGER NOT NULL,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "betNonce" INTEGER NOT NULL,
  "provablyFairStateId" TEXT NOT NULL,
  "state" JSONB NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "bets_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "bets_betId_key" ON "bets"("betId");
CREATE INDEX IF NOT EXISTS "bets_provablyFairStateId_idx" ON "bets"("provablyFairStateId");
CREATE INDEX IF NOT EXISTS "bets_game_idx" ON "bets"("game");

DO $$ BEGIN
  ALTER TABLE "provably_fair_states" ADD CONSTRAINT "provably_fair_states_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "plinkoo_users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "bets" ADD CONSTRAINT "bets_provablyFairStateId_fkey"
    FOREIGN KEY ("provablyFairStateId") REFERENCES "provably_fair_states"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  ALTER TABLE "bets" ADD CONSTRAINT "bets_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "plinkoo_users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
