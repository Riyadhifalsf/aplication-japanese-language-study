-- 003_roles: perluas role tanpa merusak data lama (user/admin tetap valid).
-- Idempoten: cek constraint dulu sebelum drop/add.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'app_users_role_check'
  ) THEN
    ALTER TABLE app_users DROP CONSTRAINT app_users_role_check;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'app_users_role_allowed'
  ) THEN
    ALTER TABLE app_users ADD CONSTRAINT app_users_role_allowed
      CHECK (role IN ('user','premium','editor','moderator','admin'));
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'admin_users_role_check'
  ) THEN
    ALTER TABLE admin_users DROP CONSTRAINT admin_users_role_check;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'admin_users_role_allowed'
  ) THEN
    ALTER TABLE admin_users ADD CONSTRAINT admin_users_role_allowed
      CHECK (role IN ('user','premium','editor','moderator','admin'));
  END IF;
END $$;
