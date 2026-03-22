--- mouse_sentinel.lua
--- Hammerspoon module to discourage mouse usage.
---
--- Tracks the ratio of MOUSE EPISODES to ALL INPUT EPISODES.
--- An "episode" is a burst of same-kind input with gaps < debounce_seconds.
--- e.g. moving the mouse for 3 seconds = 1 mouse episode,
---      typing a sentence = 1 keyboard episode,
---      a single click = 1 mouse episode.
---
--- Usage: put this file next to your init.lua, then:
---   local sentinel = require("mouse_sentinel")
---   sentinel.start()

local M = {}

-- ─────────────────────────────────────────────────
-- CONFIG
-- ─────────────────────────────────────────────────
M.config = {
	-- Rolling window for ratio calculation (seconds)
	window_seconds = 300, -- 5 min

	-- Episode debounce: max gap (seconds) between raw events
	-- of the same kind to be grouped into one episode.
	-- 0.3s works well: fast enough to merge a mouse drag or
	-- typing burst, slow enough to split distinct actions.
	debounce_seconds = 0.3,

	-- Idle detection: gap (seconds) between *any* input events
	-- that counts as "user went idle".
	idle_gap_seconds = 30,

	-- How often to refresh the menu bar + finalize stale episodes (seconds)
	tick_interval = 2,

	-- Notification thresholds (mouse episode ratio)
	notify_warn = 0.40, -- nudge
	notify_crit = 0.60, -- stronger nudge
	notify_cooldown = 120, -- seconds between notifications

	-- Beeminder integration (leave token empty to disable)
	beeminder_token = "",
	beeminder_user = "",
	beeminder_goal = "keyboard-ratio", -- "do more" odometer: kb% should stay above road
	beeminder_interval = 900, -- post every 15 min
	beeminder_min_episodes = 15, -- don't post unless this many episodes in window

	-- Menu bar icon/text
	menubar_idle_text = "🖱️ —",

	-- CSV log path (set to nil to disable local logging)
	log_path = os.getenv("HOME") .. "/.hammerspoon/mouse_sentinel.csv",

	-- Beeminder samples log (append-only, survives restarts)
	samples_path = os.getenv("HOME") .. "/.hammerspoon/mouse_sentinel_samples.csv",

	-- Adaptive idle detection (set to true once you have data)
	adaptive_idle = false,
}

local CONFIG_FILE = os.getenv("HOME") .. "/.hammerspoon/mouse_sentinel_config.json"
local PERSISTED_KEYS = { "beeminder_user", "beeminder_token", "beeminder_goal" }

-- ─────────────────────────────────────────────────
-- STATE
-- ─────────────────────────────────────────────────

-- Episode buffer: completed episodes within the rolling window
-- Each entry: { t = timestamp_when_episode_ended, kind = "mouse"|"kb" }
local episode_buffer = {}

-- Current (in-progress) episode
local current_episode = nil -- { kind = "mouse"|"kb", start_t = ..., last_t = ... }

-- General state
local last_event_time = 0
local is_idle = true
local last_notify_time = 0
local last_beeminder_time = 0
local menubar = nil
local tick_timer = nil
local mouse_tap = nil
local kb_tap = nil

-- Beeminder: daily running mean of kb% snapshots (file-backed)
local session_kb_episodes = 0
local session_mouse_episodes = 0

-- ─────────────────────────────────────────────────
-- SAMPLES PERSISTENCE (append-only log, reload by date)
-- ─────────────────────────────────────────────────

--- Append a kb% sample to the samples log file.
--- Format: date,timestamp,kb_pct,kb_n,mouse_n,total
local function append_sample(kb_pct, kb_n, mouse_n, total)
	local path = M.config.samples_path
	if not path then
		return
	end

	local f = io.open(path, "a")
	if not f then
		print("[mouse_sentinel] Could not open samples file:", path)
		return
	end

	-- Write header if file is empty
	local size = f:seek("end")
	if size == 0 then
		f:write("date,timestamp,kb_pct,kb_episodes,mouse_episodes,total_episodes\n")
	end

	f:write(
		string.format(
			"%s,%s,%d,%d,%d,%d\n",
			os.date("%Y-%m-%d"),
			os.date("!%Y-%m-%dT%H:%M:%SZ"),
			kb_pct,
			kb_n,
			mouse_n,
			total
		)
	)
	f:close()
end

--- Load all kb_pct samples for a given date from the log file.
--- Returns a list of integers.
local function load_samples_for_date(date_str)
	local path = M.config.samples_path
	if not path then
		return {}
	end

	local f = io.open(path, "r")
	if not f then
		return {}
	end

	local samples = {}
	local first_line = true
	for line in f:lines() do
		if first_line then
			first_line = false -- skip header
		else
			local d, _ts, pct = line:match("^([^,]+),([^,]+),([^,]+)")
			if d == date_str and pct then
				samples[#samples + 1] = tonumber(pct)
			end
		end
	end
	f:close()
	return samples
end

-- ─────────────────────────────────────────────────
-- CONFIG PERSISTENCE
-- ─────────────────────────────────────────────────

local function save_config()
	local data = {}
	for _, key in ipairs(PERSISTED_KEYS) do
		data[key] = M.config[key]
	end
	local encoded = hs.json.encode(data)
	if not encoded then return end
	local f = io.open(CONFIG_FILE, "w")
	if not f then return end
	f:write(encoded)
	f:close()
end

local function load_saved_config()
	local f = io.open(CONFIG_FILE, "r")
	if not f then return end
	local raw = f:read("*a")
	f:close()
	if not raw or raw == "" then return end
	local ok, data = pcall(hs.json.decode, raw)
	if not ok or type(data) ~= "table" then return end
	for _, key in ipairs(PERSISTED_KEYS) do
		if M.config[key] == "" and data[key] and data[key] ~= "" then
			M.config[key] = data[key]
		end
	end
end

-- Adaptive idle: collect inter-episode gaps for fitting
local gap_history = {} -- recent inter-episode gaps (seconds)
local gap_history_max = 2000
local adaptive_threshold = nil

-- ─────────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────────
local function now()
	return hs.timer.secondsSinceEpoch()
end

--- Finalize the current episode: push it onto the buffer.
local function finalize_episode()
	if not current_episode then
		return
	end

	-- Record the inter-episode gap for adaptive idle
	if #episode_buffer > 0 then
		local gap = current_episode.start_t - episode_buffer[#episode_buffer].t
		if gap > 0 and gap < 300 then
			gap_history[#gap_history + 1] = gap
			if #gap_history > gap_history_max then
				local new_hist = {}
				for i = math.floor(gap_history_max * 0.25), #gap_history do
					new_hist[#new_hist + 1] = gap_history[i]
				end
				gap_history = new_hist
			end
		end
	end

	episode_buffer[#episode_buffer + 1] = {
		t = current_episode.last_t,
		kind = current_episode.kind,
	}

	-- Increment Beeminder cumulative counters
	if current_episode.kind == "kb" then
		session_kb_episodes = session_kb_episodes + 1
	else
		session_mouse_episodes = session_mouse_episodes + 1
	end

	current_episode = nil
end

local function prune_buffer()
	local cutoff = now() - M.config.window_seconds
	local first_valid = nil
	for i, ep in ipairs(episode_buffer) do
		if ep.t >= cutoff then
			first_valid = i
			break
		end
	end
	if first_valid and first_valid > 1 then
		local new_buf = {}
		for i = first_valid, #episode_buffer do
			new_buf[#new_buf + 1] = episode_buffer[i]
		end
		episode_buffer = new_buf
	elseif not first_valid then
		episode_buffer = {}
	end
end

local function compute_ratio()
	local cutoff = now() - M.config.window_seconds
	local mouse_episodes = 0
	local total_episodes = 0

	for _, ep in ipairs(episode_buffer) do
		if ep.t >= cutoff then
			total_episodes = total_episodes + 1
			if ep.kind == "mouse" then
				mouse_episodes = mouse_episodes + 1
			end
		end
	end

	-- Include the in-progress episode if it exists and is within window
	if current_episode and current_episode.start_t >= cutoff then
		total_episodes = total_episodes + 1
		if current_episode.kind == "mouse" then
			mouse_episodes = mouse_episodes + 1
		end
	end

	if total_episodes == 0 then
		return nil, 0, 0
	end
	return mouse_episodes / total_episodes, total_episodes, mouse_episodes
end

local function update_adaptive_threshold()
	if #gap_history < 100 then
		return
	end
	local sorted = {}
	for i, g in ipairs(gap_history) do
		sorted[i] = g
	end
	table.sort(sorted)
	local idx = math.floor(#sorted * 0.95)
	adaptive_threshold = sorted[idx]
end

-- ─────────────────────────────────────────────────
-- EVENT HANDLING (episode-based)
-- ─────────────────────────────────────────────────
local function record_event(kind)
	local t = now()
	last_event_time = t
	is_idle = false

	if current_episode then
		local gap = t - current_episode.last_t

		if current_episode.kind == kind and gap <= M.config.debounce_seconds then
			-- Same kind, within debounce window → extend current episode
			current_episode.last_t = t
			return
		else
			-- Different kind, or gap too large → finalize old, start new
			finalize_episode()
		end
	end

	-- Start a new episode
	current_episode = { kind = kind, start_t = t, last_t = t }
end

-- ─────────────────────────────────────────────────
-- BEEMINDER CONFIGURATION WIZARD
-- ─────────────────────────────────────────────────

local function configure_beeminder_wizard()
	-- Step 1: username
	local btn1, user = hs.dialog.textPrompt(
		"Beeminder — Step 1 of 3",
		"Enter your Beeminder username:",
		M.config.beeminder_user,
		"Next", "Cancel"
	)
	if btn1 == "Cancel" then return end
	user = user:match("^%s*(.-)%s*$")
	if user == "" then
		hs.dialog.blockAlert("Invalid input", "Username cannot be empty.", "OK")
		return
	end

	-- Step 2: auth token
	local btn2, token = hs.dialog.textPrompt(
		"Beeminder — Step 2 of 3",
		"Enter your Beeminder auth token:",
		M.config.beeminder_token,
		"Next", "Cancel"
	)
	if btn2 == "Cancel" then return end
	token = token:match("^%s*(.-)%s*$")
	if token == "" then
		hs.dialog.blockAlert("Invalid input", "Auth token cannot be empty.", "OK")
		return
	end

	-- Step 3: goal slug
	local btn3, goal = hs.dialog.textPrompt(
		"Beeminder — Step 3 of 3",
		"Enter your Beeminder goal slug:",
		M.config.beeminder_goal,
		"Save", "Cancel"
	)
	if btn3 == "Cancel" then return end
	goal = goal:match("^%s*(.-)%s*$")
	if goal == "" then
		hs.dialog.blockAlert("Invalid input", "Goal cannot be empty.", "OK")
		return
	end

	M.config.beeminder_user = user
	M.config.beeminder_token = token
	M.config.beeminder_goal = goal
	save_config()
end

local function clear_beeminder_config()
	local btn = hs.dialog.blockAlert(
		"Clear Beeminder credentials",
		"This will remove your saved Beeminder username and token. Continue?",
		"Clear", "Cancel"
	)
	if btn ~= "Clear" then return end
	M.config.beeminder_user = ""
	M.config.beeminder_token = ""
	save_config()
end

-- ─────────────────────────────────────────────────
-- MENU BAR
-- ─────────────────────────────────────────────────
local function ratio_to_color(r)
	if r < 0.20 then
		return { green = 0.7, alpha = 1 }
	elseif r < 0.40 then
		return { green = 0.5, yellow = 0.3, alpha = 1 }
	elseif r < 0.60 then
		return { red = 0.8, green = 0.6, alpha = 1 }
	else
		return { red = 0.9, alpha = 1 }
	end
end

local function update_menubar()
	if not menubar then
		return
	end

	local ratio, total, mouse_n = compute_ratio()

	if ratio == nil or total < 3 then
		menubar:setTitle(M.config.menubar_idle_text)
		return
	end

	local pct = math.floor(ratio * 100)
	local text = string.format("🖱️ %d%%", pct)
	local color = ratio_to_color(ratio)

	menubar:setTitle(hs.styledtext.new(text, {
		color = color,
		font = { name = "Menlo", size = 12 },
	}))

	local threshold = adaptive_threshold or M.config.idle_gap_seconds
	menubar:setTooltip(
		string.format(
			"Mouse ratio: %d%% (%d/%d episodes in %ds window)\nIdle threshold: %.1fs%s\nDebounce: %dms",
			pct,
			mouse_n,
			total,
			M.config.window_seconds,
			threshold,
			adaptive_threshold and " (adaptive)" or " (fixed)",
			M.config.debounce_seconds * 1000
		)
	)
end

local function build_menu()
	local ratio, total, mouse_n = compute_ratio()
	local pct = ratio and math.floor(ratio * 100) or 0
	local kb_n = total - (mouse_n or 0)

	return {
		{ title = string.format("Mouse ratio: %d%%", pct), disabled = true },
		{ title = string.format("  🖱️  %d mouse episodes", mouse_n or 0), disabled = true },
		{ title = string.format("  ⌨️  %d keyboard episodes", kb_n), disabled = true },
		{ title = string.format("  Σ  %d total episodes", total), disabled = true },
		{ title = "-" },
		{ title = string.format("Window: %ds", M.config.window_seconds), disabled = true },
		{ title = string.format("Debounce: %dms", M.config.debounce_seconds * 1000), disabled = true },
		{
			title = string.format(
				"Idle threshold: %.1fs%s",
				adaptive_threshold or M.config.idle_gap_seconds,
				adaptive_threshold and " (adaptive)" or ""
			),
			disabled = true,
		},
		{ title = "-" },
		{
			title = "Adaptive idle: " .. (M.config.adaptive_idle and "ON" or "OFF"),
			fn = function()
				M.config.adaptive_idle = not M.config.adaptive_idle
				if not M.config.adaptive_idle then
					adaptive_threshold = nil
				end
			end,
		},
		{ title = "-" },
		{
			title = "Session total: " .. session_kb_episodes .. " kb, " .. session_mouse_episodes .. " mouse",
			disabled = true,
		},
		{
			title = (function()
				local samples = load_samples_for_date(os.date("%Y-%m-%d"))
				if #samples == 0 then
					return "Today: no samples yet"
				end
				local sum = 0
				for _, v in ipairs(samples) do
					sum = sum + v
				end
				return string.format("Today: mean kb %d%% (%d samples)", math.floor(sum / #samples), #samples)
			end)(),
			disabled = true,
		},
		{
			title = "Export CSV log",
			fn = function()
				M.export_log()
			end,
		},
		{
			title = "Beeminder",
			menu = (function()
				local configured = M.config.beeminder_user ~= "" and M.config.beeminder_token ~= ""
				local status_line
				if configured then
					status_line = string.format("user: %s / goal: %s", M.config.beeminder_user, M.config.beeminder_goal)
				else
					status_line = "Beeminder: disabled"
				end
				local items = {
					{ title = status_line, disabled = true },
					{ title = "-" },
				}
				if configured then
					items[#items + 1] = {
						title = "Post to Beeminder now",
						fn = function() M.post_beeminder(true) end,
					}
				end
				items[#items + 1] = {
					title = "Configure Beeminder...",
					fn = configure_beeminder_wizard,
				}
				if configured then
					items[#items + 1] = {
						title = "Clear Beeminder credentials",
						fn = clear_beeminder_config,
					}
				end
				return items
			end)(),
		},
		{ title = "-" },
		{
			title = "Stop Mouse Sentinel",
			fn = function()
				M.stop()
			end,
		},
	}
end

-- ─────────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────────
local function maybe_notify()
	local ratio, total = compute_ratio()
	if ratio == nil or total < 5 then
		return
	end

	local t = now()
	if (t - last_notify_time) < M.config.notify_cooldown then
		return
	end

	local msg = nil
	if ratio >= M.config.notify_crit then
		msg = string.format("🚨 Mouse ratio at %d%% — time to use the keyboard!", math.floor(ratio * 100))
	elseif ratio >= M.config.notify_warn then
		msg = string.format("⚠️ Mouse ratio at %d%% — can you do that with a shortcut?", math.floor(ratio * 100))
	end

	if msg then
		hs.notify.new({ title = "Mouse Sentinel", informativeText = msg }):send()
		last_notify_time = t
	end
end

-- ─────────────────────────────────────────────────
-- BEEMINDER
-- ─────────────────────────────────────────────────
function M.post_beeminder(force)
	local cfg = M.config
	if cfg.beeminder_token == "" then
		return
	end

	local t = now()
	if not force and (t - last_beeminder_time) < cfg.beeminder_interval then
		return
	end

	local ratio, total, mouse_n = compute_ratio()
	if ratio == nil then
		return
	end

	-- Gate: don't record noisy readings from low-activity windows
	if total < cfg.beeminder_min_episodes then
		return
	end

	local kb_pct = math.floor((1 - ratio) * 100)
	local kb_n = total - mouse_n
	local today = os.date("%Y-%m-%d")

	-- Persist this sample to disk
	append_sample(kb_pct, kb_n, mouse_n, total)

	-- Reload all of today's samples (survives restarts)
	local samples = load_samples_for_date(today)
	if #samples == 0 then
		return
	end

	local sum = 0
	for _, v in ipairs(samples) do
		sum = sum + v
	end
	local daily_mean = math.floor(sum / #samples)

	local url = string.format(
		"https://www.beeminder.com/api/v1/users/%s/goals/%s/datapoints.json",
		cfg.beeminder_user,
		cfg.beeminder_goal
	)

	-- Upsert: requestid scoped to today's date.
	-- If a datapoint with this requestid exists, Beeminder updates it.
	local request_id = "mouse_sentinel_" .. today
	local n_samples = #samples

	local payload = hs.json.encode({
		auth_token = cfg.beeminder_token,
		value = daily_mean,
		comment = string.format(
			"auto: mean kb %d%% (%d samples today, latest: kb %d%% from %d kb / %d mouse / %d total)",
			daily_mean,
			n_samples,
			kb_pct,
			kb_n,
			mouse_n,
			total
		),
		requestid = request_id,
	})

	hs.http.asyncPost(url, payload, {
		["Content-Type"] = "application/json",
	}, function(status, body, _headers)
		if status == 200 then
			last_beeminder_time = now()
			print(
				string.format("[mouse_sentinel] Beeminder: upserted kb mean %d%% (%d samples)", daily_mean, n_samples)
			)
		else
			print("[mouse_sentinel] Beeminder POST failed:", status, body)
		end
	end)
end

-- ─────────────────────────────────────────────────
-- CSV LOGGING
-- ─────────────────────────────────────────────────
function M.export_log()
	if not M.config.log_path then
		return
	end
	local f = io.open(M.config.log_path, "a")
	if not f then
		print("[mouse_sentinel] Could not open log file:", M.config.log_path)
		return
	end

	local size = f:seek("end")
	if size == 0 then
		f:write(
			"timestamp,mouse_ratio,mouse_episodes,kb_episodes,total_episodes,idle_threshold,adaptive,session_kb,session_mouse\n"
		)
	end

	local ratio, total, mouse_n = compute_ratio()
	if ratio then
		local kb_n = total - mouse_n
		f:write(
			string.format(
				"%s,%.4f,%d,%d,%d,%.1f,%s,%d,%d\n",
				os.date("!%Y-%m-%dT%H:%M:%SZ"),
				ratio,
				mouse_n,
				kb_n,
				total,
				adaptive_threshold or M.config.idle_gap_seconds,
				adaptive_threshold and "true" or "false",
				session_kb_episodes,
				session_mouse_episodes
			)
		)
	end
	f:close()
end

-- ─────────────────────────────────────────────────
-- TICK (periodic update)
-- ─────────────────────────────────────────────────
local tick_count = 0

local function tick()
	-- Finalize stale episode (no new events within debounce window)
	if current_episode then
		local gap = now() - current_episode.last_t
		if gap > M.config.debounce_seconds then
			finalize_episode()
		end
	end

	prune_buffer()
	update_menubar()
	maybe_notify()

	tick_count = tick_count + 1

	-- Adaptive threshold: re-fit every ~30 seconds
	if M.config.adaptive_idle and tick_count % 15 == 0 then
		update_adaptive_threshold()
	end

	-- CSV log every 5 minutes
	if M.config.log_path and tick_count % 150 == 0 then
		M.export_log()
	end

	-- Beeminder
	M.post_beeminder(false)

	-- Detect idle
	local threshold = adaptive_threshold or M.config.idle_gap_seconds
	if last_event_time > 0 and (now() - last_event_time) >= threshold then
		is_idle = true
	end
end

-- ─────────────────────────────────────────────────
-- START / STOP
-- ─────────────────────────────────────────────────
function M.start()
	load_saved_config()
	print("[mouse_sentinel] Starting (episode mode)...")

	menubar = hs.menubar.new()
	menubar:setTitle(M.config.menubar_idle_text)
	menubar:setMenu(build_menu)

	-- Mouse event tap: mouseMoved, clicks, scroll
	mouse_tap = hs.eventtap.new({
		hs.eventtap.event.types.mouseMoved,
		hs.eventtap.event.types.leftMouseDown,
		hs.eventtap.event.types.rightMouseDown,
		hs.eventtap.event.types.scrollWheel,
	}, function(_event)
		record_event("mouse")
		return false
	end)
	mouse_tap:start()

	-- Keyboard event tap
	kb_tap = hs.eventtap.new({
		hs.eventtap.event.types.keyDown,
	}, function(_event)
		record_event("kb")
		return false
	end)
	kb_tap:start()

	-- Periodic tick
	tick_timer = hs.timer.doEvery(M.config.tick_interval, tick)

	hs.notify.new({ title = "Mouse Sentinel", informativeText = "Tracking started (episode mode)." }):send()
end

function M.stop()
	print("[mouse_sentinel] Stopping...")
	if current_episode then
		finalize_episode()
	end
	if mouse_tap then
		mouse_tap:stop()
		mouse_tap = nil
	end
	if kb_tap then
		kb_tap:stop()
		kb_tap = nil
	end
	if tick_timer then
		tick_timer:stop()
		tick_timer = nil
	end
	if menubar then
		menubar:delete()
		menubar = nil
	end
	hs.notify.new({ title = "Mouse Sentinel", informativeText = "Tracking stopped." }):send()
end

return M
