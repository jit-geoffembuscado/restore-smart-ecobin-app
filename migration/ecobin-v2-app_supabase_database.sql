-- =============================================================================
-- Smart Ecobin — Supabase-Ready PostgreSQL Schema
-- Converted from MySQL dump (2026-03-12)
-- =============================================================================
-- Conventions used:
--   • BIGSERIAL           replaces BIGINT AUTO_INCREMENT
--   • TEXT                replaces VARCHAR(255) / TINYTEXT / LONGTEXT / MEDIUMTEXT
--   • DOUBLE PRECISION    replaces DOUBLE
--   • TIMESTAMPTZ         replaces TIMESTAMP (timezone-aware)
--   • JSONB               replaces JSON/JSONB (already native in Postgres)
--   • SMALLINT            kept as-is
--   • ENUM types          defined once as custom TYPE, reused across tables
--   • updated_at trigger  applied to all tables that have updated_at
--   • Laravel-style tables (cache, sessions, jobs, etc.) kept for compatibility
-- =============================================================================


-- ---------------------------------------------------------------------------
-- Helper: auto-update updated_at on row modification
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =============================================================================
-- ENUM TYPES
-- =============================================================================

CREATE TYPE device_status_enum          AS ENUM ('online', 'offline', 'unknown');
CREATE TYPE game_progress_enum          AS ENUM ('pending', 'in_progress', 'finished');
CREATE TYPE found_us_source_enum        AS ENUM ('facebook','friend','instagram','referral','seb_machine','tiktok','youtube','others','viber','company');
CREATE TYPE upload_status_enum          AS ENUM ('PENDING', 'CREDITED', 'REJECTED');
CREATE TYPE voucher_status_enum         AS ENUM ('preparing_order', 'ready_for_pickup', 'for_delivery', 'reward_claimed');
CREATE TYPE claiming_method_enum        AS ENUM ('pickup', 'delivery');
CREATE TYPE discount_type_enum          AS ENUM ('percentage', 'fixed');
CREATE TYPE reward_option_type_enum     AS ENUM ('default', 'color', 'size');
CREATE TYPE survey_question_type_enum   AS ENUM ('text', 'radio', 'checkbox', 'textarea');
CREATE TYPE user_machine_enum           AS ENUM ('desktop', 'mobile', 'tablet');
CREATE TYPE visit_type_enum             AS ENUM ('login', 'transaction');
CREATE TYPE game_order_status_enum      AS ENUM ('processing', 'done');
CREATE TYPE theme_setting_enum          AS ENUM ('light', 'dark', 'auto');
CREATE TYPE availability_type_enum      AS ENUM ('full-time', 'part-time', 'event-based');
CREATE TYPE ewallet_tx_type_enum        AS ENUM ('0', '1');


-- =============================================================================
-- CORE / AUTH TABLES
-- =============================================================================

-- Note: In Supabase, the `users` table typically lives in the `auth` schema.
-- This creates a `public.users` profile table that mirrors/extends auth.users.
-- If integrating with Supabase Auth, link `id` to `auth.users.id` via FK.

CREATE TABLE users (
  id                      BIGSERIAL PRIMARY KEY,
  code                    VARCHAR(512)        NOT NULL UNIQUE,
  firstname               TEXT                NOT NULL,
  lastname                TEXT                NOT NULL,
  middlename              TEXT,
  index_name              TEXT,
  address                 TEXT,
  birthdate               DATE,
  age_group               TEXT,
  last_bonus_given        TIMESTAMPTZ,
  agreed_terms            BOOLEAN             NOT NULL DEFAULT FALSE,
  show_name_publicity     BOOLEAN             NOT NULL DEFAULT FALSE,
  gender                  TEXT,
  contact_number          TEXT,
  is_contact_viber        BOOLEAN             NOT NULL DEFAULT FALSE,
  is_leaderboard_display  SMALLINT            DEFAULT 1,
  has_visit_viber         INTEGER             NOT NULL DEFAULT 0,
  is_contact_able         INTEGER             NOT NULL DEFAULT 0,
  email                   TEXT                NOT NULL UNIQUE,
  qr_code_path            TEXT,
  avatar                  TEXT,
  email_verified_at       TIMESTAMPTZ,
  last_login              TIMESTAMPTZ,
  password                TEXT                NOT NULL,
  remember_token          VARCHAR(100),
  referral_code           TEXT                UNIQUE,
  admin_code              TEXT                UNIQUE,
  is_brand_admin          BOOLEAN             NOT NULL DEFAULT FALSE,
  is_deleted              SMALLINT            DEFAULT 0,
  social_media_shares     INTEGER             DEFAULT 0,
  is_archived             SMALLINT            DEFAULT 0,
  theme_setting           theme_setting_enum  NOT NULL DEFAULT 'auto',
  is_active               SMALLINT,
  referred_by             BIGINT              REFERENCES users(id) ON DELETE CASCADE,
  delivery_address        TEXT,
  stripe_id               TEXT,
  pm_type                 TEXT,
  pm_last_four            VARCHAR(4),
  trial_ends_at           TIMESTAMPTZ,
  deactivated_at          TIMESTAMPTZ,
  created_at              TIMESTAMPTZ,
  updated_at              TIMESTAMPTZ,
  deleted_at              TIMESTAMPTZ
);

CREATE INDEX idx_users_contact_number            ON users(contact_number);
CREATE INDEX idx_users_stripe_id                 ON users(stripe_id);
CREATE INDEX idx_users_is_active                 ON users(is_active);
CREATE INDEX idx_users_created_at                ON users(created_at);
CREATE INDEX idx_users_deactivated_at            ON users(deactivated_at);
CREATE INDEX idx_users_created_deactivated       ON users(created_at, deactivated_at);
CREATE INDEX idx_users_is_active_created_at      ON users(is_active, created_at);

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ---------------------------------------------------------------------------

CREATE TABLE roles (
  id          BIGSERIAL PRIMARY KEY,
  name        TEXT        NOT NULL,
  guard_name  TEXT        NOT NULL,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ,
  deleted_at  TIMESTAMPTZ,
  UNIQUE (name, guard_name)
);

CREATE TRIGGER trg_roles_updated_at
  BEFORE UPDATE ON roles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE permissions (
  id          BIGSERIAL PRIMARY KEY,
  name        TEXT        NOT NULL,
  guard_name  TEXT        NOT NULL,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ,
  deleted_at  TIMESTAMPTZ,
  UNIQUE (name, guard_name)
);

CREATE TRIGGER trg_permissions_updated_at
  BEFORE UPDATE ON permissions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE model_has_roles (
  role_id     BIGINT  NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  model_type  TEXT    NOT NULL,
  model_id    BIGINT  NOT NULL,
  PRIMARY KEY (role_id, model_id, model_type)
);

CREATE INDEX idx_model_has_roles_model ON model_has_roles(model_id, model_type);


CREATE TABLE model_has_permissions (
  permission_id  BIGINT  NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  model_type     TEXT    NOT NULL,
  model_id       BIGINT  NOT NULL,
  PRIMARY KEY (permission_id, model_id, model_type)
);

CREATE INDEX idx_model_has_permissions_model ON model_has_permissions(model_id, model_type);


CREATE TABLE role_has_permissions (
  permission_id  BIGINT  NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  role_id        BIGINT  NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  PRIMARY KEY (permission_id, role_id)
);


-- =============================================================================
-- LARAVEL FRAMEWORK TABLES
-- =============================================================================

CREATE TABLE migrations (
  id         SERIAL  PRIMARY KEY,
  migration  TEXT    NOT NULL,
  batch      INTEGER NOT NULL
);


CREATE TABLE cache (
  key         TEXT    PRIMARY KEY,
  value       TEXT    NOT NULL,
  expiration  INTEGER NOT NULL
);


CREATE TABLE cache_locks (
  key         TEXT    PRIMARY KEY,
  owner       TEXT    NOT NULL,
  expiration  INTEGER NOT NULL
);


CREATE TABLE sessions (
  id             TEXT    PRIMARY KEY,
  user_id        BIGINT,
  ip_address     VARCHAR(45),
  user_agent     TEXT,
  payload        TEXT    NOT NULL,
  last_activity  INTEGER NOT NULL
);

CREATE INDEX idx_sessions_user_id       ON sessions(user_id);
CREATE INDEX idx_sessions_last_activity ON sessions(last_activity);


CREATE TABLE jobs (
  id            BIGSERIAL PRIMARY KEY,
  queue         TEXT      NOT NULL,
  payload       TEXT      NOT NULL,
  attempts      SMALLINT,
  reserved_at   INTEGER,
  available_at  INTEGER   NOT NULL,
  created_at    INTEGER   NOT NULL
);

CREATE INDEX idx_jobs_queue ON jobs(queue);


CREATE TABLE job_batches (
  id              TEXT    PRIMARY KEY,
  name            TEXT    NOT NULL,
  total_jobs      INTEGER NOT NULL,
  pending_jobs    INTEGER NOT NULL,
  failed_jobs     INTEGER NOT NULL,
  failed_job_ids  TEXT    NOT NULL,
  options         TEXT,
  cancelled_at    INTEGER,
  created_at      INTEGER NOT NULL,
  finished_at     INTEGER
);


CREATE TABLE failed_jobs (
  id         BIGSERIAL   PRIMARY KEY,
  uuid       TEXT        NOT NULL UNIQUE,
  connection TEXT        NOT NULL,
  queue      TEXT        NOT NULL,
  payload    TEXT        NOT NULL,
  exception  TEXT        NOT NULL,
  failed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE TABLE personal_access_tokens (
  id              BIGSERIAL   PRIMARY KEY,
  tokenable_type  TEXT        NOT NULL,
  tokenable_id    BIGINT      NOT NULL,
  name            TEXT        NOT NULL,
  token           VARCHAR(64) NOT NULL UNIQUE,
  abilities       TEXT,
  last_used_at    TIMESTAMPTZ,
  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ
);

CREATE INDEX idx_personal_access_tokens_tokenable
  ON personal_access_tokens(tokenable_type, tokenable_id);

CREATE TRIGGER trg_personal_access_tokens_updated_at
  BEFORE UPDATE ON personal_access_tokens
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE password_reset_tokens (
  email       TEXT        PRIMARY KEY,
  token       TEXT        NOT NULL,
  created_at  TIMESTAMPTZ
);


CREATE TABLE password_resets (
  email       TEXT        NOT NULL,
  token       TEXT        NOT NULL,
  created_at  TIMESTAMPTZ
);

CREATE INDEX idx_password_resets_email ON password_resets(email);


-- =============================================================================
-- STRIPE / SUBSCRIPTION TABLES
-- =============================================================================

CREATE TABLE subscriptions (
  id             BIGSERIAL   PRIMARY KEY,
  user_id        BIGINT      NOT NULL REFERENCES users(id),
  type           TEXT        NOT NULL,
  stripe_id      TEXT        NOT NULL UNIQUE,
  stripe_status  TEXT        NOT NULL,
  stripe_price   TEXT,
  quantity       INTEGER,
  trial_ends_at  TIMESTAMPTZ,
  ends_at        TIMESTAMPTZ,
  created_at     TIMESTAMPTZ,
  updated_at     TIMESTAMPTZ
);

CREATE INDEX idx_subscriptions_user_status ON subscriptions(user_id, stripe_status);

CREATE TRIGGER trg_subscriptions_updated_at
  BEFORE UPDATE ON subscriptions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE subscription_items (
  id               BIGSERIAL PRIMARY KEY,
  subscription_id  BIGINT    NOT NULL REFERENCES subscriptions(id),
  stripe_id        TEXT      NOT NULL UNIQUE,
  stripe_product   TEXT      NOT NULL,
  stripe_price     TEXT      NOT NULL,
  quantity         INTEGER,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ
);

CREATE INDEX idx_subscription_items_sub_price
  ON subscription_items(subscription_id, stripe_price);

CREATE TRIGGER trg_subscription_items_updated_at
  BEFORE UPDATE ON subscription_items
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- MACHINES & DEVICES
-- =============================================================================

CREATE TABLE machines (
  id                          BIGSERIAL   PRIMARY KEY,
  code                        TEXT        NOT NULL UNIQUE,
  title                       TEXT,
  qr_backdoor                 VARCHAR(7)  NOT NULL,
  maintenance_incentive_limit SMALLINT    NOT NULL DEFAULT 2,
  maintenance_end_time        TIME        NOT NULL DEFAULT '23:59:00',
  maintenance_start_time      TIME        NOT NULL DEFAULT '00:00:00',
  description                 TEXT,
  address                     TEXT,
  location_prefix             VARCHAR(9),
  under_maintenance           SMALLINT    DEFAULT 0,
  show_leaderboard            SMALLINT    DEFAULT 0,
  contact_person              TEXT,
  contact_number              TEXT,
  contact_email               TEXT,
  active                      SMALLINT    NOT NULL DEFAULT 1,
  client_logo                 TEXT,
  primary_color_hex           TEXT        DEFAULT '#1ab8a5',
  secondary_color_hex         TEXT        DEFAULT '#f2f3f5',
  created_at                  TIMESTAMPTZ,
  updated_at                  TIMESTAMPTZ,
  deleted_at                  TIMESTAMPTZ
);

CREATE TRIGGER trg_machines_updated_at
  BEFORE UPDATE ON machines
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE devices (
  id               BIGSERIAL          PRIMARY KEY,
  machine_id       BIGINT             REFERENCES machines(id) ON DELETE CASCADE,
  user_id          BIGINT             REFERENCES users(id)    ON DELETE CASCADE,
  code             TEXT               NOT NULL UNIQUE,
  name             TEXT               NOT NULL,
  certificate_path TEXT               NOT NULL,
  private_key_path TEXT               NOT NULL,
  status           device_status_enum NOT NULL DEFAULT 'unknown',
  last_contact_at  TIMESTAMPTZ,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_devices_updated_at
  BEFORE UPDATE ON devices
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE device_status_logs (
  id            BIGSERIAL   PRIMARY KEY,
  device_id     BIGINT      NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
  user_id       BIGINT      REFERENCES users(id) ON DELETE CASCADE,
  status        TEXT        NOT NULL,
  message       TEXT        NOT NULL,
  power_status  TEXT,
  received_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ,
  updated_at    TIMESTAMPTZ
);

CREATE TRIGGER trg_device_status_logs_updated_at
  BEFORE UPDATE ON device_status_logs
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE machine_online_logs (
  id          BIGSERIAL   PRIMARY KEY,
  machine_id  BIGINT      NOT NULL REFERENCES machines(id),
  code        TEXT        NOT NULL,
  time_log    TIMESTAMPTZ NOT NULL,
  is_online   BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ
);

CREATE INDEX idx_machine_online_logs_machine_id ON machine_online_logs(machine_id);

CREATE TRIGGER trg_machine_online_logs_updated_at
  BEFORE UPDATE ON machine_online_logs
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE machine_machine_online_logs (
  id                    BIGSERIAL PRIMARY KEY,
  machine_id            BIGINT    NOT NULL REFERENCES machines(id)            ON DELETE CASCADE,
  machine_online_log_id BIGINT    NOT NULL REFERENCES machine_online_logs(id) ON DELETE CASCADE,
  created_at            TIMESTAMPTZ,
  updated_at            TIMESTAMPTZ
);

CREATE TRIGGER trg_machine_machine_online_logs_updated_at
  BEFORE UPDATE ON machine_machine_online_logs
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE machine_maintenance_audits (
  id              BIGSERIAL   PRIMARY KEY,
  machine_id      BIGINT      NOT NULL,
  user_id         BIGINT      NOT NULL,
  date_time       TIMESTAMPTZ,
  number_of_times INTEGER     DEFAULT 1,
  created_at      TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ
);

CREATE TRIGGER trg_machine_maintenance_audits_updated_at
  BEFORE UPDATE ON machine_maintenance_audits
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE report_machines (
  id                        BIGSERIAL PRIMARY KEY,
  machine_id                BIGINT    NOT NULL REFERENCES machines(id),
  user_id                   BIGINT    NOT NULL DEFAULT 1,
  code                      TEXT      NOT NULL,
  error_type                TEXT      NOT NULL,
  message                   TEXT,
  resolved                  BOOLEAN   NOT NULL DEFAULT FALSE,
  is_online                 SMALLINT  DEFAULT 0,
  is_qrscanner_working      SMALLINT  DEFAULT 0,
  is_conveyor_working       SMALLINT  DEFAULT 0,
  is_camera_working         SMALLINT  DEFAULT 0,
  is_bin_full               SMALLINT  DEFAULT 0,
  capacity_percentage       DOUBLE PRECISION NOT NULL DEFAULT 0,
  is_conveyor_sachet_stuck  SMALLINT  DEFAULT 0,
  created_at                TIMESTAMPTZ,
  updated_at                TIMESTAMPTZ
);

CREATE TRIGGER trg_report_machines_updated_at
  BEFORE UPDATE ON report_machines
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE software_versions (
  id            BIGSERIAL PRIMARY KEY,
  machine_id    BIGINT    NOT NULL REFERENCES machines(id) ON DELETE CASCADE,
  version       TEXT      NOT NULL,
  file_path     TEXT      NOT NULL,
  checksum      TEXT,
  file_size     TEXT,
  is_latest     SMALLINT  NOT NULL DEFAULT 0,
  release_notes TEXT,
  file_hash     TEXT,
  created_at    TIMESTAMPTZ,
  updated_at    TIMESTAMPTZ,
  deleted_at    TIMESTAMPTZ
);

CREATE TRIGGER trg_software_versions_updated_at
  BEFORE UPDATE ON software_versions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE dashboard_videos (
  id          BIGSERIAL PRIMARY KEY,
  machine_id  BIGINT    NOT NULL REFERENCES machines(id) ON DELETE CASCADE,
  file_path   TEXT      NOT NULL,
  file_name   TEXT      NOT NULL,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ,
  deleted_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_dashboard_videos_updated_at
  BEFORE UPDATE ON dashboard_videos
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- PRODUCTS
-- =============================================================================

CREATE TABLE product_categories (
  id          BIGSERIAL PRIMARY KEY,
  title       TEXT        NOT NULL,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ,
  deleted_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_product_categories_updated_at
  BEFORE UPDATE ON product_categories
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE products (
  id                  BIGSERIAL        PRIMARY KEY,
  title               TEXT             NOT NULL,
  barcode             TEXT             NOT NULL,
  sku                 TEXT             NOT NULL UNIQUE,
  description         TEXT,
  status              TEXT             NOT NULL,
  srp                 DOUBLE PRECISION NOT NULL,
  points              DOUBLE PRECISION NOT NULL,
  item_size_threshold INTEGER,
  active              SMALLINT         NOT NULL DEFAULT 1,
  created_at          TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ,
  deleted_at          TIMESTAMPTZ
);

CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE category_products (
  id                  BIGSERIAL PRIMARY KEY,
  product_id          BIGINT    NOT NULL REFERENCES products(id),
  product_category_id BIGINT    NOT NULL REFERENCES product_categories(id),
  created_at          TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ
);

CREATE INDEX idx_category_products_product_id          ON category_products(product_id);
CREATE INDEX idx_category_products_product_category_id ON category_products(product_category_id);

CREATE TRIGGER trg_category_products_updated_at
  BEFORE UPDATE ON category_products
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE machine_products (
  id          BIGSERIAL PRIMARY KEY,
  product_id  BIGINT    NOT NULL REFERENCES products(id),
  machine_id  BIGINT    NOT NULL REFERENCES machines(id),
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ
);

CREATE INDEX idx_machine_products_product_id ON machine_products(product_id);
CREATE INDEX idx_machine_products_machine_id ON machine_products(machine_id);

CREATE TRIGGER trg_machine_products_updated_at
  BEFORE UPDATE ON machine_products
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- TRANSACTIONS
-- =============================================================================

CREATE TABLE transactions (
  id                   BIGSERIAL        PRIMARY KEY,
  user_id              BIGINT           NOT NULL REFERENCES users(id),
  machine_id           BIGINT           NOT NULL REFERENCES machines(id),
  transaction_type     SMALLINT,
  reference_number     TEXT,
  transaction_points   DOUBLE PRECISION,
  transaction_quantity INTEGER,
  transaction_date     TIMESTAMPTZ,
  ip_address           TEXT,
  acknowledged         BOOLEAN          NOT NULL DEFAULT FALSE,
  cleared_from_bin     SMALLINT         DEFAULT 0,
  status               TEXT,
  created_at           TIMESTAMPTZ,
  updated_at           TIMESTAMPTZ,
  deleted_at           TIMESTAMPTZ
);

CREATE INDEX idx_transactions_user_id              ON transactions(user_id);
CREATE INDEX idx_transactions_machine_id           ON transactions(machine_id);
CREATE INDEX idx_transactions_dates                ON transactions(created_at, transaction_date);
CREATE INDEX idx_transactions_user_created         ON transactions(user_id, created_at);
CREATE INDEX idx_transactions_machine_date         ON transactions(machine_id, transaction_date);
CREATE INDEX idx_transactions_machine_date_deleted ON transactions(machine_id, transaction_date, deleted_at);

CREATE TRIGGER trg_transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE transaction_products (
  id            BIGSERIAL        PRIMARY KEY,
  transaction_id BIGINT          NOT NULL REFERENCES transactions(id),
  product_id     BIGINT          NOT NULL REFERENCES products(id),
  quantity       INTEGER         NOT NULL,
  points         DOUBLE PRECISION NOT NULL,
  total_points   DOUBLE PRECISION NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ,
  updated_at     TIMESTAMPTZ,
  deleted_at     TIMESTAMPTZ
);

CREATE INDEX idx_transaction_products_transaction_id ON transaction_products(transaction_id);
CREATE INDEX idx_transaction_products_product_id     ON transaction_products(product_id);

CREATE TRIGGER trg_transaction_products_updated_at
  BEFORE UPDATE ON transaction_products
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE machine_point_logs (
  id              BIGSERIAL    PRIMARY KEY,
  user_id         BIGINT       NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
  machine_id      BIGINT       NOT NULL REFERENCES machines(id) ON DELETE CASCADE,
  transaction_id  BIGINT       NOT NULL DEFAULT 0,
  name            TEXT,
  -- TIMESTAMP(3) precision preserved using TIMESTAMPTZ(3)
  log_datetime    TIMESTAMPTZ(3) NOT NULL,
  points          INTEGER      NOT NULL,
  -- point_type: 1=start, 2=end
  point_type      SMALLINT     NOT NULL CHECK (point_type IN (1, 2)),
  created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,
  UNIQUE (user_id, machine_id, log_datetime, point_type)
);

CREATE INDEX idx_machine_point_logs_user_time    ON machine_point_logs(user_id, log_datetime);
CREATE INDEX idx_machine_point_logs_machine_time ON machine_point_logs(machine_id, log_datetime);
CREATE INDEX idx_machine_point_logs_time         ON machine_point_logs(log_datetime);
CREATE INDEX idx_machine_point_logs_transaction  ON machine_point_logs(transaction_id);


CREATE TABLE uploaded_offline_transactions (
  id                  BIGSERIAL         PRIMARY KEY,
  user_id             BIGINT            NOT NULL,
  machine_id          BIGINT            NOT NULL,
  reference_number    TEXT,
  file_receipt_image  TEXT,
  transaction_points  DOUBLE PRECISION,
  status              upload_status_enum NOT NULL,
  credited_at         TIMESTAMPTZ,
  created_at          TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ,
  deleted_at          TIMESTAMPTZ
);

CREATE TRIGGER trg_uploaded_offline_transactions_updated_at
  BEFORE UPDATE ON uploaded_offline_transactions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- REWARDS
-- =============================================================================

CREATE TABLE reward_brands (
  id          BIGSERIAL PRIMARY KEY,
  title       TEXT      NOT NULL,
  brand_logo  TEXT,
  active      BOOLEAN   NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ,
  deleted_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_reward_brands_updated_at
  BEFORE UPDATE ON reward_brands
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE reward_categories (
  id             BIGSERIAL PRIMARY KEY,
  title          TEXT      NOT NULL,
  category_icon  TEXT      NOT NULL,
  active         BOOLEAN   NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ,
  updated_at     TIMESTAMPTZ,
  deleted_at     TIMESTAMPTZ
);

CREATE TRIGGER trg_reward_categories_updated_at
  BEFORE UPDATE ON reward_categories
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE reward_pickup_locations (
  id               BIGSERIAL        PRIMARY KEY,
  title            TEXT,
  address          TEXT,
  location_prefix  VARCHAR(9),
  latitude         DECIMAL(9,6),
  longitude        DECIMAL(9,6),
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ,
  deleted_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_reward_pickup_locations_updated_at
  BEFORE UPDATE ON reward_pickup_locations
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE reward_products (
  id                 BIGSERIAL        PRIMARY KEY,
  title              TEXT             NOT NULL,
  image              TEXT             NOT NULL,
  specification      TEXT,
  points             DOUBLE PRECISION NOT NULL DEFAULT 0,
  promo_intro_points DOUBLE PRECISION NOT NULL DEFAULT 0,
  has_options        SMALLINT         DEFAULT 0,
  fiat_currency_sign TEXT             DEFAULT '₱',
  fiat_currency      TEXT             DEFAULT 'philippine_pesos',
  fiat_value         DOUBLE PRECISION,
  -- NOTE: was VARCHAR('1') in MySQL — using BOOLEAN for clarity
  active             BOOLEAN          NOT NULL DEFAULT TRUE,
  shopee_link        TEXT,
  created_at         TIMESTAMPTZ,
  updated_at         TIMESTAMPTZ,
  deleted_at         TIMESTAMPTZ
);

CREATE TRIGGER trg_reward_products_updated_at
  BEFORE UPDATE ON reward_products
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE reward_product_options (
  id                 BIGSERIAL               PRIMARY KEY,
  reward_product_id  BIGINT                  NOT NULL,
  option_title       TEXT                    DEFAULT 'default',
  option_type        reward_option_type_enum NOT NULL DEFAULT 'default',
  points             DOUBLE PRECISION,
  fiat_value         DOUBLE PRECISION,
  fiat_currency      TEXT                    DEFAULT 'philippine_pesos',
  fiat_currency_sign TEXT                    DEFAULT '₱',
  created_at         TIMESTAMPTZ,
  updated_at         TIMESTAMPTZ
);

CREATE TRIGGER trg_reward_product_options_updated_at
  BEFORE UPDATE ON reward_product_options
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE reward_product_brands (
  id                BIGSERIAL PRIMARY KEY,
  reward_brand_id   BIGINT    NOT NULL,
  reward_product_id BIGINT    NOT NULL
);


CREATE TABLE reward_product_categories (
  id                 BIGSERIAL PRIMARY KEY,
  reward_category_id BIGINT    NOT NULL,
  reward_product_id  BIGINT    NOT NULL
);


CREATE TABLE reward_product_reward_pickup_locations (
  id                       BIGSERIAL PRIMARY KEY,
  reward_product_id        BIGINT    NOT NULL,
  reward_pickup_location_id BIGINT   NOT NULL,
  created_at               TIMESTAMPTZ,
  updated_at               TIMESTAMPTZ
);

CREATE TRIGGER trg_reward_product_pickup_updated_at
  BEFORE UPDATE ON reward_product_reward_pickup_locations
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE reward_thresholds (
  id                    BIGSERIAL        PRIMARY KEY,
  reward_product_id     BIGINT           NOT NULL REFERENCES reward_products(id) ON DELETE CASCADE,
  redemption_count_level INTEGER         NOT NULL,
  redemption_count      INTEGER          NOT NULL,
  increase_percent      DOUBLE PRECISION NOT NULL,
  created_at            TIMESTAMPTZ,
  updated_at            TIMESTAMPTZ
);

CREATE TRIGGER trg_reward_thresholds_updated_at
  BEFORE UPDATE ON reward_thresholds
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE reward_vouchers (
  id                    BIGSERIAL           PRIMARY KEY,
  code                  VARCHAR(50)         NOT NULL UNIQUE,
  title                 TEXT                NOT NULL,
  description           TEXT,
  discount_type         discount_type_enum,
  discount_value        DECIMAL(10,2),
  max_discount          DECIMAL(10,2),
  usage_limit           INTEGER             NOT NULL DEFAULT 1,
  usage_count           INTEGER             NOT NULL DEFAULT 0,
  user_limit            INTEGER             NOT NULL DEFAULT 1,
  start_date            DATE,
  end_date              DATE,
  is_redeemed           INTEGER             NOT NULL DEFAULT 0,
  is_claimed            INTEGER             NOT NULL DEFAULT 0,
  is_active             BOOLEAN             NOT NULL DEFAULT TRUE,
  minimum_order_value   DECIMAL(10,2),
  eligible_products     JSONB,
  eligible_user_ids     JSONB,
  created_at            TIMESTAMPTZ,
  updated_at            TIMESTAMPTZ,
  deleted_at            TIMESTAMPTZ
);

CREATE TRIGGER trg_reward_vouchers_updated_at
  BEFORE UPDATE ON reward_vouchers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE reward_product_reward_vouchers (
  id                BIGSERIAL PRIMARY KEY,
  reward_product_id BIGINT    NOT NULL REFERENCES reward_products(id),
  reward_voucher_id BIGINT    NOT NULL REFERENCES reward_vouchers(id)
);


CREATE TABLE reward_user_rewards (
  id                       BIGSERIAL             PRIMARY KEY,
  -- NOTE: was INT in MySQL — corrected to BIGINT for FK consistency
  user_id                  BIGINT                NOT NULL,
  reward_id                BIGINT                NOT NULL,
  voucher_id               BIGINT                NOT NULL,
  reward_pickup_location_id BIGINT               NOT NULL DEFAULT 1,
  delivery_address         TEXT,
  date_redeemed            TIMESTAMPTZ           NOT NULL,
  voucher_status           voucher_status_enum   DEFAULT 'preparing_order',
  delivery_date_estimate   DATE,
  points                   DOUBLE PRECISION      NOT NULL,
  claiming_method          claiming_method_enum,
  created_at               TIMESTAMPTZ,
  updated_at               TIMESTAMPTZ,
  deleted_at               TIMESTAMPTZ
);

CREATE TRIGGER trg_reward_user_rewards_updated_at
  BEFORE UPDATE ON reward_user_rewards
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE reward_user_debits (
  id                    BIGSERIAL        PRIMARY KEY,
  user_id               BIGINT           NOT NULL REFERENCES users(id),
  reward_id             BIGINT           NOT NULL REFERENCES reward_products(id),
  reward_user_rewards_id BIGINT          NOT NULL REFERENCES reward_user_rewards(id),
  points                DOUBLE PRECISION NOT NULL DEFAULT 0,
  created_at            TIMESTAMPTZ,
  updated_at            TIMESTAMPTZ
);

CREATE INDEX idx_reward_user_debits_user_id              ON reward_user_debits(user_id);
CREATE INDEX idx_reward_user_debits_reward_id            ON reward_user_debits(reward_id);
CREATE INDEX idx_reward_user_debits_reward_user_rewards  ON reward_user_debits(reward_user_rewards_id);

CREATE TRIGGER trg_reward_user_debits_updated_at
  BEFORE UPDATE ON reward_user_debits
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- USER LABELS / SEGMENTS
-- =============================================================================

CREATE TABLE user_labels (
  id          BIGSERIAL PRIMARY KEY,
  code        TEXT      NOT NULL UNIQUE,
  title       TEXT      NOT NULL,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_user_labels_updated_at
  BEFORE UPDATE ON user_labels
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_user_labels (
  id             BIGSERIAL PRIMARY KEY,
  user_id        BIGINT    NOT NULL REFERENCES users(id)        ON DELETE CASCADE,
  user_label_id  BIGINT    NOT NULL REFERENCES user_labels(id)  ON DELETE CASCADE,
  created_at     TIMESTAMPTZ,
  updated_at     TIMESTAMPTZ
);

CREATE TRIGGER trg_user_user_labels_updated_at
  BEFORE UPDATE ON user_user_labels
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE reward_product_user_labels (
  id                BIGSERIAL PRIMARY KEY,
  reward_product_id BIGINT    NOT NULL REFERENCES reward_products(id) ON DELETE CASCADE,
  user_label_id     BIGINT    NOT NULL REFERENCES user_labels(id)     ON DELETE CASCADE,
  created_at        TIMESTAMPTZ,
  updated_at        TIMESTAMPTZ
);

CREATE TRIGGER trg_reward_product_user_labels_updated_at
  BEFORE UPDATE ON reward_product_user_labels
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE image_banner_user_labels (
  id               BIGSERIAL PRIMARY KEY,
  image_banner_id  BIGINT    NOT NULL,
  user_label_id    BIGINT    NOT NULL REFERENCES user_labels(id) ON DELETE CASCADE,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_image_banner_user_labels_updated_at
  BEFORE UPDATE ON image_banner_user_labels
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- ACHIEVEMENTS / GAMIFICATION
-- =============================================================================

CREATE TABLE achievements (
  id                  BIGSERIAL PRIMARY KEY,
  code                TEXT      NOT NULL,
  title               TEXT      NOT NULL,
  subtitle            TEXT      NOT NULL,
  rule                TEXT      NOT NULL,
  milestone_threshold INTEGER   NOT NULL DEFAULT 1,
  image               TEXT      NOT NULL,
  created_at          TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ,
  deleted_at          TIMESTAMPTZ
);

CREATE TRIGGER trg_achievements_updated_at
  BEFORE UPDATE ON achievements
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_achievements (
  id              BIGSERIAL   PRIMARY KEY,
  user_id         BIGINT      NOT NULL,
  achievement_id  BIGINT      NOT NULL,
  acknowledged    BOOLEAN     NOT NULL DEFAULT FALSE,
  acquired_on     TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ
);

CREATE TRIGGER trg_user_achievements_updated_at
  BEFORE UPDATE ON user_achievements
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE gamify_achievements (
  id                  BIGSERIAL        PRIMARY KEY,
  title               TEXT,
  description         TEXT,
  image               TEXT,
  class_name          TEXT,
  milestone_threshold DOUBLE PRECISION NOT NULL DEFAULT 1,
  created_at          TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ,
  deleted_at          TIMESTAMPTZ
);

CREATE TRIGGER trg_gamify_achievements_updated_at
  BEFORE UPDATE ON gamify_achievements
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_gamify_achievements (
  id                    BIGSERIAL   PRIMARY KEY,
  user_id               BIGINT      NOT NULL,
  gamify_achievement_id BIGINT      NOT NULL,
  acknowledged          BOOLEAN     NOT NULL DEFAULT FALSE,
  acquired_on           TIMESTAMPTZ NOT NULL,
  created_at            TIMESTAMPTZ,
  updated_at            TIMESTAMPTZ,
  deleted_at            TIMESTAMPTZ
);

CREATE TRIGGER trg_user_gamify_achievements_updated_at
  BEFORE UPDATE ON user_gamify_achievements
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE rank_achievements (
  id                  BIGSERIAL PRIMARY KEY,
  title               TEXT      NOT NULL,
  number_of_tiers     INTEGER   NOT NULL,
  threshold_per_tier  INTEGER   NOT NULL,
  image               TEXT,
  level_number        INTEGER   NOT NULL UNIQUE,
  is_active           SMALLINT,
  created_at          TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ
);

CREATE TRIGGER trg_rank_achievements_updated_at
  BEFORE UPDATE ON rank_achievements
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE class_divisions (
  id               BIGSERIAL PRIMARY KEY,
  title            TEXT      NOT NULL UNIQUE,
  description      TEXT,
  image            TEXT,
  rank_order       INTEGER   NOT NULL,
  next_rank_id     INTEGER   NOT NULL DEFAULT 0,
  previous_rank_id INTEGER   NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ,
  deleted_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_class_divisions_updated_at
  BEFORE UPDATE ON class_divisions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE class_division_levels (
  id                 BIGSERIAL PRIMARY KEY,
  class_division_id  BIGINT    NOT NULL REFERENCES class_divisions(id),
  title              TEXT      NOT NULL,
  description        TEXT,
  image_male         TEXT      DEFAULT '',
  image_female       TEXT      DEFAULT '',
  tier_level         INTEGER   NOT NULL,
  points_threshold   INTEGER   NOT NULL DEFAULT 0,
  created_at         TIMESTAMPTZ,
  updated_at         TIMESTAMPTZ,
  deleted_at         TIMESTAMPTZ
);

CREATE INDEX idx_class_division_levels_division_id
  ON class_division_levels(class_division_id);

CREATE TRIGGER trg_class_division_levels_updated_at
  BEFORE UPDATE ON class_division_levels
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_class_division_class_division_levels (
  id                       BIGSERIAL PRIMARY KEY,
  user_id                  BIGINT    NOT NULL,
  class_division_id        BIGINT    NOT NULL,
  class_division_level_id  BIGINT    NOT NULL,
  created_at               TIMESTAMPTZ,
  updated_at               TIMESTAMPTZ,
  deleted_at               TIMESTAMPTZ
);

CREATE TRIGGER trg_user_cdl_updated_at
  BEFORE UPDATE ON user_class_division_class_division_levels
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- GAMES
-- =============================================================================

CREATE TABLE game_lists (
  id          BIGSERIAL PRIMARY KEY,
  title       TEXT,
  description TEXT,
  image       TEXT,
  route       TEXT,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ,
  deleted_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_game_lists_updated_at
  BEFORE UPDATE ON game_lists
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE games (
  id               BIGSERIAL          PRIMARY KEY,
  user_id          BIGINT             NOT NULL,
  word             TEXT               NOT NULL,
  transaction_date DATE,
  attempts         SMALLINT,
  progress         game_progress_enum NOT NULL,
  is_win           BOOLEAN            NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_games_updated_at
  BEFORE UPDATE ON games
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_game_histories (
  id               BIGSERIAL          PRIMARY KEY,
  user_id          BIGINT             NOT NULL,
  word             TEXT,
  transaction_date TIMESTAMPTZ,
  progress         game_progress_enum NOT NULL,
  is_win           BOOLEAN            NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_user_game_histories_updated_at
  BEFORE UPDATE ON user_game_histories
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE video_games (
  id               BIGSERIAL PRIMARY KEY,
  name             TEXT,
  image            TEXT,
  ingame_currency  TEXT,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ,
  deleted_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_video_games_updated_at
  BEFORE UPDATE ON video_games
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE video_game_recharges (
  id               BIGSERIAL        PRIMARY KEY,
  video_game_id    BIGINT           NOT NULL REFERENCES video_games(id) ON DELETE CASCADE,
  points           DOUBLE PRECISION,
  game_points      DOUBLE PRECISION,
  has_discount     SMALLINT         NOT NULL DEFAULT 0,
  discount_percent DOUBLE PRECISION,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ,
  deleted_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_video_game_recharges_updated_at
  BEFORE UPDATE ON video_game_recharges
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_video_game_recharges (
  id                     BIGSERIAL              PRIMARY KEY,
  user_id                BIGINT                 NOT NULL,
  video_game_recharge_id BIGINT                 NOT NULL,
  ingame_user_id         TEXT                   NOT NULL,
  order_status           game_order_status_enum NOT NULL DEFAULT 'processing',
  points                 DOUBLE PRECISION,
  has_discount           SMALLINT               NOT NULL DEFAULT 0,
  discount_percent       DOUBLE PRECISION,
  created_at             TIMESTAMPTZ,
  updated_at             TIMESTAMPTZ,
  deleted_at             TIMESTAMPTZ
);

CREATE TRIGGER trg_user_video_game_recharges_updated_at
  BEFORE UPDATE ON user_video_game_recharges
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- GEOFENCES & BANNERS
-- =============================================================================

CREATE TABLE geofences (
  id             BIGSERIAL     PRIMARY KEY,
  name           TEXT          NOT NULL,
  address        TEXT          NOT NULL,
  latitude       DECIMAL(10,7) NOT NULL,
  longitude      DECIMAL(10,7) NOT NULL,
  radius_meters  INTEGER       NOT NULL,
  created_at     TIMESTAMPTZ,
  updated_at     TIMESTAMPTZ,
  deleted_at     TIMESTAMPTZ
);

CREATE TRIGGER trg_geofences_updated_at
  BEFORE UPDATE ON geofences
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE image_banners (
  id               BIGSERIAL PRIMARY KEY,
  title            TEXT,
  module           TEXT,
  link_module      TEXT,
  image            TEXT,
  expiration_date  DATE,
  is_geofence      BOOLEAN   NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_image_banners_updated_at
  BEFORE UPDATE ON image_banners
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE geofence_image_banners (
  id               BIGSERIAL PRIMARY KEY,
  image_banner_id  BIGINT    NOT NULL REFERENCES image_banners(id) ON DELETE CASCADE,
  geofence_id      BIGINT    NOT NULL REFERENCES geofences(id)     ON DELETE CASCADE,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ,
  deleted_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_geofence_image_banners_updated_at
  BEFORE UPDATE ON geofence_image_banners
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE dashboard_announcements (
  id                BIGSERIAL PRIMARY KEY,
  icon              TEXT      NOT NULL DEFAULT 'fa-solid fa-circle-info',
  greet_title       TEXT      NOT NULL,
  subtitle          TEXT      NOT NULL,
  link              TEXT,
  color             TEXT      NOT NULL DEFAULT 'green',
  icon_color        TEXT      NOT NULL DEFAULT 'green',
  link_placeholder  TEXT      NOT NULL DEFAULT 'click here',
  module_index      TEXT               DEFAULT 'dashboard',
  published         BOOLEAN   NOT NULL DEFAULT TRUE,
  for_everyone      BOOLEAN   NOT NULL DEFAULT TRUE,
  is_geofence       BOOLEAN   NOT NULL DEFAULT FALSE,
  can_animate       BOOLEAN   NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ,
  updated_at        TIMESTAMPTZ
);

CREATE TRIGGER trg_dashboard_announcements_updated_at
  BEFORE UPDATE ON dashboard_announcements
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE dashboard_announcement_geofences (
  id                         BIGSERIAL PRIMARY KEY,
  dashboard_announcement_id  BIGINT    NOT NULL,
  geofence_id                BIGINT    NOT NULL,
  UNIQUE (dashboard_announcement_id, geofence_id)
);


CREATE TABLE user_dashboard_announcements (
  id                         BIGSERIAL PRIMARY KEY,
  user_id                    BIGINT    NOT NULL,
  dashboard_announcement_id  BIGINT    NOT NULL,
  created_at                 TIMESTAMPTZ,
  updated_at                 TIMESTAMPTZ
);

CREATE TRIGGER trg_user_dashboard_announcements_updated_at
  BEFORE UPDATE ON user_dashboard_announcements
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE home_popups (
  id          BIGSERIAL PRIMARY KEY,
  title       TEXT,
  path        TEXT,
  filename    TEXT,
  link        TEXT,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_home_popups_updated_at
  BEFORE UPDATE ON home_popups
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- SURVEYS
-- =============================================================================

CREATE TABLE surveys (
  id             BIGSERIAL        PRIMARY KEY,
  user_label_id  BIGINT           NOT NULL DEFAULT 1,
  title          TEXT             NOT NULL,
  description    TEXT,
  points_bonus   DOUBLE PRECISION,
  created_at     TIMESTAMPTZ,
  updated_at     TIMESTAMPTZ,
  deleted_at     TIMESTAMPTZ
);

CREATE TRIGGER trg_surveys_updated_at
  BEFORE UPDATE ON surveys
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE survey_questions (
  id          BIGSERIAL                 PRIMARY KEY,
  survey_id   BIGINT                    NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
  question    VARCHAR(300)              NOT NULL,
  type        survey_question_type_enum NOT NULL,
  options     JSONB,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_survey_questions_updated_at
  BEFORE UPDATE ON survey_questions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE survey_responses (
  id          BIGSERIAL PRIMARY KEY,
  survey_id   BIGINT    NOT NULL REFERENCES surveys(id)  ON DELETE CASCADE,
  user_id     BIGINT    NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_survey_responses_updated_at
  BEFORE UPDATE ON survey_responses
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE survey_answers (
  id                  BIGSERIAL PRIMARY KEY,
  survey_response_id  BIGINT    NOT NULL REFERENCES survey_responses(id) ON DELETE CASCADE,
  survey_question_id  BIGINT    NOT NULL REFERENCES survey_questions(id) ON DELETE CASCADE,
  answer              TEXT,
  created_at          TIMESTAMPTZ,
  updated_at          TIMESTAMPTZ
);

CREATE TRIGGER trg_survey_answers_updated_at
  BEFORE UPDATE ON survey_answers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- WALLETS & E-WALLET
-- =============================================================================

CREATE TABLE wallets (
  id          BIGSERIAL PRIMARY KEY,
  title       TEXT      NOT NULL,
  description TEXT,
  api_key     TEXT,
  api_url     TEXT,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ,
  deleted_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_wallets_updated_at
  BEFORE UPDATE ON wallets
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE conversion_rates (
  id          BIGSERIAL        PRIMARY KEY,
  wallet_id   BIGINT           NOT NULL REFERENCES wallets(id),
  rate        DOUBLE PRECISION,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ,
  deleted_at  TIMESTAMPTZ
);

CREATE INDEX idx_conversion_rates_wallet_id ON conversion_rates(wallet_id);

CREATE TRIGGER trg_conversion_rates_updated_at
  BEFORE UPDATE ON conversion_rates
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_wallets (
  id              BIGSERIAL PRIMARY KEY,
  user_id         BIGINT    NOT NULL REFERENCES users(id),
  wallet_id       BIGINT    NOT NULL REFERENCES wallets(id),
  account_number  TEXT,
  created_at      TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ,
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_user_wallets_user_id   ON user_wallets(user_id);
CREATE INDEX idx_user_wallets_wallet_id ON user_wallets(wallet_id);

CREATE TRIGGER trg_user_wallets_updated_at
  BEFORE UPDATE ON user_wallets
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE ewallet_transactions (
  id               BIGSERIAL            PRIMARY KEY,
  user_wallet_id   BIGINT               NOT NULL REFERENCES user_wallets(id),
  points           DOUBLE PRECISION,
  -- NOTE: typo 'convertion_rate' preserved as-is; rename to conversion_rate when ready
  convertion_rate  DOUBLE PRECISION,
  amount           DOUBLE PRECISION,
  transaction_type ewallet_tx_type_enum NOT NULL,
  description      TEXT,
  status           SMALLINT             NOT NULL,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ,
  deleted_at       TIMESTAMPTZ
);

CREATE INDEX idx_ewallet_transactions_user_wallet_id
  ON ewallet_transactions(user_wallet_id);

CREATE TRIGGER trg_ewallet_transactions_updated_at
  BEFORE UPDATE ON ewallet_transactions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- USER PROFILE / MISC
-- =============================================================================

CREATE TABLE user_balances (
  id              BIGSERIAL        PRIMARY KEY,
  user_id         BIGINT           NOT NULL REFERENCES users(id),
  points_balance  DOUBLE PRECISION,
  created_at      TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ,
  deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_user_balances_user_id ON user_balances(user_id);

CREATE TRIGGER trg_user_balances_updated_at
  BEFORE UPDATE ON user_balances
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_points_caches (
  id                          BIGSERIAL PRIMARY KEY,
  user_id                     BIGINT    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  total_transaction_quantity  BIGINT    NOT NULL DEFAULT 0,
  total_transaction_points    BIGINT    NOT NULL DEFAULT 0,
  total_allowance_points      BIGINT    NOT NULL DEFAULT 0,
  total_points                BIGINT    NOT NULL DEFAULT 0,
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_points_caches_user_id ON user_points_caches(user_id);

CREATE TRIGGER trg_user_points_caches_updated_at
  BEFORE UPDATE ON user_points_caches
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_allowances (
  id              BIGSERIAL        PRIMARY KEY,
  user_id         BIGINT           NOT NULL,
  context         TEXT             NOT NULL,
  points_balance  DOUBLE PRECISION,
  acknowledged    SMALLINT         NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ
);

CREATE TRIGGER trg_user_allowances_updated_at
  BEFORE UPDATE ON user_allowances
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_referrals (
  id               BIGSERIAL   PRIMARY KEY,
  user_id          BIGINT      NOT NULL REFERENCES users(id),
  referrer_user_id BIGINT      NOT NULL,
  acknowledged     BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ,
  deleted_at       TIMESTAMPTZ
);

CREATE INDEX idx_user_referrals_user_id ON user_referrals(user_id);

CREATE TRIGGER trg_user_referrals_updated_at
  BEFORE UPDATE ON user_referrals
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_reward_brands (
  id               BIGSERIAL PRIMARY KEY,
  user_id          BIGINT    NOT NULL REFERENCES users(id),
  reward_brand_id  BIGINT    NOT NULL REFERENCES reward_brands(id),
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_user_reward_brands_updated_at
  BEFORE UPDATE ON user_reward_brands
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_sachet_goals (
  id               BIGSERIAL   PRIMARY KEY,
  user_id          BIGINT      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  year             SMALLINT    NOT NULL,
  target_quantity  INTEGER     NOT NULL,
  current_quantity INTEGER     NOT NULL DEFAULT 0,
  status           TEXT        NOT NULL DEFAULT 'ongoing',
  achieved_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ,
  deleted_at       TIMESTAMPTZ,
  UNIQUE (user_id, year)
);

CREATE TRIGGER trg_user_sachet_goals_updated_at
  BEFORE UPDATE ON user_sachet_goals
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_track_devices (
  id               BIGSERIAL         PRIMARY KEY,
  user_id          BIGINT            NOT NULL,
  device           TEXT              DEFAULT '',
  platform         TEXT              DEFAULT '',
  platform_version TEXT              DEFAULT '',
  browser          TEXT              DEFAULT '',
  browser_version  TEXT              DEFAULT '',
  user_machine     user_machine_enum DEFAULT 'mobile',
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ,
  deleted_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_user_track_devices_updated_at
  BEFORE UPDATE ON user_track_devices
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_visits (
  id          BIGSERIAL        PRIMARY KEY,
  user_id     BIGINT           NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  visit_type  visit_type_enum  NOT NULL,
  visited_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ,
  deleted_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_user_visits_updated_at
  BEFORE UPDATE ON user_visits
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE found_us (
  id           BIGSERIAL            PRIMARY KEY,
  found_us     found_us_source_enum,
  visitor_type TEXT,
  -- NOTE: was INT in MySQL — corrected to BIGINT for FK consistency
  user_id      BIGINT,
  created_at   TIMESTAMPTZ,
  updated_at   TIMESTAMPTZ
);

CREATE TRIGGER trg_found_us_updated_at
  BEFORE UPDATE ON found_us
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- BRAND AMBASSADORS
-- =============================================================================

CREATE TABLE registered_brand_ambassadors (
  id                   BIGSERIAL              PRIMARY KEY,
  user_id              BIGINT                 NOT NULL REFERENCES users(id),
  short_bio            TEXT,
  fields_of_interest   JSONB,
  instagram_url        TEXT,
  tiktok_url           TEXT,
  personal_website     TEXT,
  available_start_date DATE,
  availability_type    availability_type_enum,
  created_at           TIMESTAMPTZ,
  updated_at           TIMESTAMPTZ,
  deleted_at           TIMESTAMPTZ
);

CREATE INDEX idx_registered_brand_ambassadors_user_id
  ON registered_brand_ambassadors(user_id);

CREATE TRIGGER trg_registered_brand_ambassadors_updated_at
  BEFORE UPDATE ON registered_brand_ambassadors
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- MISC / UTILITY
-- =============================================================================

CREATE TABLE audit_trails (
  id          BIGSERIAL   PRIMARY KEY,
  user_id     BIGINT      REFERENCES users(id) ON DELETE CASCADE,
  action      TEXT        NOT NULL,
  url         TEXT        NOT NULL,
  details     TEXT,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ
);

CREATE INDEX idx_audit_trails_user_id_created_at ON audit_trails(user_id, created_at);

CREATE TRIGGER trg_audit_trails_updated_at
  BEFORE UPDATE ON audit_trails
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE documents (
  id          BIGSERIAL PRIMARY KEY,
  name        TEXT      NOT NULL,
  content     TEXT,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE email_notifications (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT    NOT NULL REFERENCES users(id),
  email_to    TEXT      NOT NULL,
  subject     TEXT,
  content     TEXT,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ,
  deleted_at  TIMESTAMPTZ
);

CREATE INDEX idx_email_notifications_user_id ON email_notifications(user_id);

CREATE TRIGGER trg_email_notifications_updated_at
  BEFORE UPDATE ON email_notifications
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- NOTE: email_recipients had no PK in the original — added surrogate key
CREATE TABLE email_recipients (
  id          BIGSERIAL PRIMARY KEY,
  email       TEXT,
  name        TEXT,
  deleted_at  TIMESTAMPTZ
);


CREATE TABLE inconvenience_fees (
  id          BIGSERIAL        PRIMARY KEY,
  code        TEXT             NOT NULL UNIQUE,
  title       TEXT,
  description TEXT,
  qr_image    TEXT,
  one_to_many BOOLEAN          NOT NULL DEFAULT TRUE,
  times_used  INTEGER          DEFAULT 1,
  points      DOUBLE PRECISION NOT NULL,
  created_at  TIMESTAMPTZ,
  updated_at  TIMESTAMPTZ,
  deleted_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_inconvenience_fees_updated_at
  BEFORE UPDATE ON inconvenience_fees
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE redirect_links (
  id               BIGSERIAL PRIMARY KEY,
  slug             TEXT      NOT NULL UNIQUE,
  title            TEXT,
  destination_url  TEXT      NOT NULL,
  visits           BIGINT    NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ,
  updated_at       TIMESTAMPTZ,
  deleted_at       TIMESTAMPTZ
);

CREATE TRIGGER trg_redirect_links_updated_at
  BEFORE UPDATE ON redirect_links
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE guest_transaction_vouchers (
  id            BIGSERIAL        PRIMARY KEY,
  voucher_code  TEXT,
  points        DOUBLE PRECISION,
  date_used     DATE,
  created_at    TIMESTAMPTZ,
  updated_at    TIMESTAMPTZ,
  deleted_at    TIMESTAMPTZ
);

CREATE TRIGGER trg_guest_transaction_vouchers_updated_at
  BEFORE UPDATE ON guest_transaction_vouchers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


CREATE TABLE user_guest_transaction_vouchers (
  id                           BIGSERIAL PRIMARY KEY,
  user_id                      BIGINT    NOT NULL,
  guest_transaction_voucher_id BIGINT    NOT NULL,
  created_at                   TIMESTAMPTZ,
  updated_at                   TIMESTAMPTZ
);

CREATE TRIGGER trg_user_guest_transaction_vouchers_updated_at
  BEFORE UPDATE ON user_guest_transaction_vouchers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- RLS enabled queries
-- =============================================================================
-- Enable RLS on all Smart Ecobin tables
-- Run this in the Supabase SQL Editor
-- =============================================================================

-- Step 1: Enable RLS on every table
-- ---------------------------------------------------------------------------

ALTER TABLE users                                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles                                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions                                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_has_roles                              ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_has_permissions                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_has_permissions                         ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_access_tokens                       ENABLE ROW LEVEL SECURITY;
ALTER TABLE password_reset_tokens                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE password_resets                              ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions                                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions                                ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_items                           ENABLE ROW LEVEL SECURITY;

ALTER TABLE machines                                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices                                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_status_logs                           ENABLE ROW LEVEL SECURITY;
ALTER TABLE machine_online_logs                          ENABLE ROW LEVEL SECURITY;
ALTER TABLE machine_machine_online_logs                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE machine_maintenance_audits                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE machine_point_logs                           ENABLE ROW LEVEL SECURITY;
ALTER TABLE machine_products                             ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_machines                              ENABLE ROW LEVEL SECURITY;
ALTER TABLE software_versions                            ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_videos                             ENABLE ROW LEVEL SECURITY;

ALTER TABLE products                                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories                           ENABLE ROW LEVEL SECURITY;
ALTER TABLE category_products                            ENABLE ROW LEVEL SECURITY;

ALTER TABLE transactions                                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_products                         ENABLE ROW LEVEL SECURITY;
ALTER TABLE uploaded_offline_transactions                ENABLE ROW LEVEL SECURITY;

ALTER TABLE reward_brands                                ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_categories                            ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_pickup_locations                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_products                              ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_product_options                       ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_product_brands                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_product_categories                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_product_reward_pickup_locations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_product_reward_vouchers               ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_product_user_labels                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_thresholds                            ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_vouchers                              ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_user_rewards                          ENABLE ROW LEVEL SECURITY;
ALTER TABLE reward_user_debits                           ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_labels                                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_user_labels                             ENABLE ROW LEVEL SECURITY;
ALTER TABLE image_banner_user_labels                     ENABLE ROW LEVEL SECURITY;

ALTER TABLE achievements                                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements                            ENABLE ROW LEVEL SECURITY;
ALTER TABLE gamify_achievements                          ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_gamify_achievements                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE rank_achievements                            ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_divisions                              ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_division_levels                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_class_division_class_division_levels    ENABLE ROW LEVEL SECURITY;

ALTER TABLE game_lists                                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE games                                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_game_histories                          ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_games                                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_game_recharges                         ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_video_game_recharges                    ENABLE ROW LEVEL SECURITY;

ALTER TABLE geofences                                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE image_banners                                ENABLE ROW LEVEL SECURITY;
ALTER TABLE geofence_image_banners                       ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_announcements                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE dashboard_announcement_geofences             ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_dashboard_announcements                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE home_popups                                  ENABLE ROW LEVEL SECURITY;

ALTER TABLE surveys                                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_questions                             ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_responses                             ENABLE ROW LEVEL SECURITY;
ALTER TABLE survey_answers                               ENABLE ROW LEVEL SECURITY;

ALTER TABLE wallets                                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversion_rates                             ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_wallets                                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE ewallet_transactions                         ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_balances                                ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_points_caches                           ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_allowances                              ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_referrals                               ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reward_brands                           ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sachet_goals                            ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_track_devices                           ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_visits                                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_guest_transaction_vouchers              ENABLE ROW LEVEL SECURITY;

ALTER TABLE found_us                                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE registered_brand_ambassadors                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_trails                                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents                                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_notifications                          ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_recipients                             ENABLE ROW LEVEL SECURITY;
ALTER TABLE inconvenience_fees                           ENABLE ROW LEVEL SECURITY;
ALTER TABLE redirect_links                               ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_transaction_vouchers                   ENABLE ROW LEVEL SECURITY;

-- Laravel framework tables — typically only accessed by your backend service role,
-- so lock them down completely (no public access).
ALTER TABLE migrations                                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE cache                                        ENABLE ROW LEVEL SECURITY;
ALTER TABLE cache_locks                                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs                                         ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_batches                                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE failed_jobs                                  ENABLE ROW LEVEL SECURITY;


-- =============================================================================
-- Step 2: Audit — verify which tables still have RLS disabled
-- Run this after Step 1 to confirm everything is covered.
-- =============================================================================

SELECT
  schemaname,
  tablename,
  rowsecurity AS rls_enabled,
  CASE
    WHEN rowsecurity THEN '✓ enabled'
    ELSE '✗ DISABLED — action needed'
  END AS status
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY rls_enabled ASC, tablename ASC;


-- =============================================================================
-- Step 3: Audit — list all existing RLS policies per table
-- Useful to see tables that have RLS on but no policies defined yet
-- (those will block ALL access until you add a policy).
-- =============================================================================

SELECT
  t.tablename,
  t.rowsecurity                                     AS rls_enabled,
  COUNT(p.policyname)                               AS policy_count,
  COALESCE(
    STRING_AGG(p.policyname, ', ' ORDER BY p.policyname),
    '— no policies —'
  )                                                 AS policies
FROM pg_tables t
LEFT JOIN pg_policies p
  ON p.schemaname = t.schemaname
  AND p.tablename = t.tablename
WHERE t.schemaname = 'public'
GROUP BY t.tablename, t.rowsecurity
ORDER BY t.rowsecurity ASC, policy_count ASC, t.tablename;


-- =============================================================================
-- Step 4: Starter RLS policy templates
-- Copy-paste and adjust the USING / WITH CHECK expressions per table.
-- =============================================================================

-- -----------------------------------------------------------------------
-- Pattern A: User can only see/modify their own rows
-- Use for: transactions, user_balances, user_wallets, user_visits, etc.
-- -----------------------------------------------------------------------
/*
CREATE POLICY "users_own_rows" ON <table_name>
  FOR ALL
  USING       (user_id = auth.uid())
  WITH CHECK  (user_id = auth.uid());
*/

-- -----------------------------------------------------------------------
-- Pattern B: Authenticated users can read; only owner can write
-- Use for: reward_products, products, machines (public catalog data)
-- -----------------------------------------------------------------------
/*
CREATE POLICY "public_read" ON <table_name>
  FOR SELECT
  USING (true);

CREATE POLICY "owner_write" ON <table_name>
  FOR ALL
  USING       (auth.role() = 'authenticated')
  WITH CHECK  (auth.role() = 'authenticated');
*/

-- -----------------------------------------------------------------------
-- Pattern C: Service role only (no direct client access)
-- Use for: audit_trails, failed_jobs, jobs, cache, migrations
-- -----------------------------------------------------------------------
/*
CREATE POLICY "service_role_only" ON <table_name>
  FOR ALL
  USING (auth.role() = 'service_role');
*/

-- -----------------------------------------------------------------------
-- Pattern D: Admin role (via JWT claim or a roles table lookup)
-- Use for: machines, users (admin panel operations)
-- -----------------------------------------------------------------------
/*
CREATE POLICY "admin_full_access" ON <table_name>
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM model_has_roles mr
      JOIN roles r ON r.id = mr.role_id
      WHERE mr.model_id = auth.uid()::bigint
        AND mr.model_type = 'App\\Models\\User'
        AND r.name = 'admin'
    )
  );
*/
-- =============================================================================
-- public.profiles — Supabase-ready conversion of the MySQL `users` table
-- Links to auth.users via UUID (Supabase Auth manages email + password)
-- =============================================================================

CREATE TABLE public.profiles (

  -- -------------------------------------------------------------------------
  -- Primary key: references Supabase Auth user
  -- Supabase Auth owns: email, password, email_verified_at, remember_token
  -- Everything else lives here in profiles
  -- -------------------------------------------------------------------------
  id                    UUID          PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- -------------------------------------------------------------------------
  -- Identity
  -- -------------------------------------------------------------------------
  code                  VARCHAR(512)  NOT NULL UNIQUE,
  firstname             TEXT          NOT NULL,
  lastname              TEXT          NOT NULL,
  middlename            TEXT,
  index_name            TEXT,
  gender                TEXT,
  birthdate             DATE,
  age_group             TEXT,
  address               TEXT,
  delivery_address      TEXT,
  avatar                TEXT,
  qr_code_path          TEXT,

  -- -------------------------------------------------------------------------
  -- Contact & social
  -- -------------------------------------------------------------------------
  contact_number        TEXT,
  is_contact_viber      BOOLEAN       NOT NULL DEFAULT FALSE,
  is_contact_able       INTEGER       NOT NULL DEFAULT 0,
  has_visit_viber       INTEGER       NOT NULL DEFAULT 0,

  -- -------------------------------------------------------------------------
  -- Referral
  -- -------------------------------------------------------------------------
  referral_code         TEXT          UNIQUE,
  referred_by           UUID          REFERENCES public.profiles(id) ON DELETE SET NULL,

  -- -------------------------------------------------------------------------
  -- Gamification / ranking
  -- -------------------------------------------------------------------------
  current_rank_id       BIGINT        REFERENCES class_divisions(id) ON DELETE SET NULL,

  -- -------------------------------------------------------------------------
  -- App preferences & flags
  -- -------------------------------------------------------------------------
  agreed_terms          BOOLEAN       NOT NULL DEFAULT FALSE,
  show_name_publicity   BOOLEAN       NOT NULL DEFAULT FALSE,
  is_leaderboard_display BOOLEAN      NOT NULL DEFAULT TRUE,
  theme_setting         theme_setting_enum NOT NULL DEFAULT 'auto',

  -- -------------------------------------------------------------------------
  -- Admin & roles
  -- -------------------------------------------------------------------------
  admin_code            TEXT          UNIQUE,
  is_brand_admin        BOOLEAN       NOT NULL DEFAULT FALSE,

  -- -------------------------------------------------------------------------
  -- Account state
  -- -------------------------------------------------------------------------
  is_active             BOOLEAN,
  is_deleted            BOOLEAN       NOT NULL DEFAULT FALSE,
  is_archived           BOOLEAN       NOT NULL DEFAULT FALSE,
  last_bonus_given      TIMESTAMPTZ,
  last_login            TIMESTAMPTZ,
  deactivated_at        TIMESTAMPTZ,

  -- -------------------------------------------------------------------------
  -- Stripe / billing
  -- -------------------------------------------------------------------------
  stripe_id             TEXT,
  pm_type               TEXT,
  pm_last_four          VARCHAR(4),
  trial_ends_at         TIMESTAMPTZ,

  -- -------------------------------------------------------------------------
  -- Social media
  -- -------------------------------------------------------------------------
  social_media_shares   INTEGER       NOT NULL DEFAULT 0,

  -- -------------------------------------------------------------------------
  -- Timestamps
  -- -------------------------------------------------------------------------
  created_at            TIMESTAMPTZ   DEFAULT NOW(),
  updated_at            TIMESTAMPTZ   DEFAULT NOW(),
  deleted_at            TIMESTAMPTZ

);

-- =============================================================================
-- Indexes (mirrored from the MySQL original)
-- =============================================================================

CREATE INDEX idx_profiles_contact_number     ON public.profiles(contact_number);
CREATE INDEX idx_profiles_stripe_id          ON public.profiles(stripe_id);
CREATE INDEX idx_profiles_is_active          ON public.profiles(is_active);
CREATE INDEX idx_profiles_created_at         ON public.profiles(created_at);
CREATE INDEX idx_profiles_deactivated_at     ON public.profiles(deactivated_at);
CREATE INDEX idx_profiles_referred_by        ON public.profiles(referred_by);
CREATE INDEX idx_profiles_created_deactivated ON public.profiles(created_at, deactivated_at);
CREATE INDEX idx_profiles_is_active_created  ON public.profiles(is_active, created_at);


-- =============================================================================
-- Auto-update updated_at trigger
-- =============================================================================

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- =============================================================================
-- Auto-create a profile row when a new auth.users record is inserted
-- This fires on every new Supabase Auth signup
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, created_at, updated_at)
  VALUES (NEW.id, NOW(), NOW());
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- =============================================================================
-- RLS
-- =============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read all profiles (e.g. leaderboard, public names)
CREATE POLICY "profiles_public_read"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);

-- Users can only update their own profile
CREATE POLICY "profiles_owner_update"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING       (id = auth.uid())
  WITH CHECK  (id = auth.uid());

-- Only service role can insert/delete (handled by the trigger above)
CREATE POLICY "profiles_service_insert"
  ON public.profiles
  FOR INSERT
  TO service_role
  WITH CHECK (true);

CREATE POLICY "profiles_service_delete"
  ON public.profiles
  FOR DELETE
  TO service_role
  USING (true);

-- Create an enum for roles (optional but recommended)
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'user');

-- Add the role column to your existing profiles table
ALTER TABLE public.profiles 
ADD COLUMN role user_role DEFAULT 'user';

-- =============================================================================
-- Notes on columns intentionally excluded
-- =============================================================================
-- `email`            → managed by auth.users (auth.users.email)
-- `password`         → managed by auth.users (Supabase Auth handles hashing)
-- `remember_token`   → managed by auth.users / Supabase session tokens
-- `email_verified_at`→ managed by auth.users (email_confirmed_at in Supabase)
-- `id` (BIGINT)      → replaced by UUID from auth.users