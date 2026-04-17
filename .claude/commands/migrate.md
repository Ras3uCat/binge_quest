Create a new Supabase migration: $ARGUMENTS

Generate a timestamped migration file with correct RLS boilerplate.

**Input expected:** Migration description (e.g., "add user_profiles table", "add is_premium to profiles")

**Steps:**

1. **Generate timestamp** in format `YYYYMMDDHHMMSS` using current date/time

2. **Derive filename**: `execution/backend/supabase/migrations/<timestamp>_<snake_case_description>.sql`

3. **Detect migration type** from the description:
   - "create" / "add table" → new table template
   - "add column" / "alter" → alter table template
   - "add index" → index template
   - "add policy" / "rls" → RLS-only template

4. **New table template:**
```sql
-- <timestamp>_<description>.sql
-- Purpose: <one-line purpose>

CREATE TABLE IF NOT EXISTS public.<table_name> (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Auto-update updated_at
CREATE TRIGGER <table_name>_updated_at
  BEFORE UPDATE ON public.<table_name>
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE public.<table_name> ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_own" ON public.<table_name>
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "users_insert_own" ON public.<table_name>
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "users_update_own" ON public.<table_name>
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "users_delete_own" ON public.<table_name>
  FOR DELETE USING (auth.uid() = user_id);

-- Rollback: DROP TABLE public.<table_name>;
```

5. **Alter table template:**
```sql
-- Purpose: <one-line purpose>

ALTER TABLE public.<table_name>
  ADD COLUMN IF NOT EXISTS <column_name> <type> <constraints>;

-- Rollback: ALTER TABLE public.<table_name> DROP COLUMN <column_name>;
```

6. **Create the file** at the correct path

7. **Output:**
   - Full path of created file
   - Contents of the file
   - Reminder: run `supabase db reset` locally to test before pushing
