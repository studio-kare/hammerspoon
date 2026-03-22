local sentinel = require("mouse_sentinel")

-- ── Optional overrides ──────────────────────────────────────────────────────
-- sentinel.config.window_seconds    = 300   -- rolling window (seconds)
-- sentinel.config.idle_gap_seconds  = 30    -- idle threshold (seconds)
-- sentinel.config.adaptive_idle     = false -- set true once you have data
-- sentinel.config.notify_warn       = 0.40
-- sentinel.config.notify_crit       = 0.60
-- sentinel.config.notify_cooldown   = 120   -- seconds between nudges

-- ── Beeminder (optional) ─────────────────────────────────────────────────────
-- Credentials can be configured from the menubar (Beeminder → Configure…).
-- To set them in code instead (takes precedence over saved config):
-- sentinel.config.beeminder_user     = "your_username"
-- sentinel.config.beeminder_token    = "your_auth_token"
-- sentinel.config.beeminder_goal     = "keyboard-ratio"
-- sentinel.config.beeminder_interval = 900  -- seconds between posts

sentinel.start()
