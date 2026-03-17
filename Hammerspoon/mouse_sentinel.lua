-- mouse_sentinel: menubar + Beeminder credential setup

local CREDS_PATH = os.getenv("HOME") .. "/.hammerspoon/beeminder.json"

local function creds_load()
  local f = io.open(CREDS_PATH, "r")
  if not f then return nil end
  local raw = f:read("*a")
  f:close()
  local t = hs.json.decode(raw)
  assert(t.username, "beeminder.json missing username")
  assert(t.auth_token, "beeminder.json missing auth_token")
  return t
end

local function creds_save(t)
  assert(t.username, "creds_save: missing username")
  assert(t.auth_token, "creds_save: missing auth_token")
  local f = assert(io.open(CREDS_PATH, "w"))
  f:write(hs.json.encode(t))
  f:close()
end

local function creds_ask()
  -- TODO: translate Latin copy to English
  local scpt_user = 'display dialog "Nomen usoris Beeminder inscribe:" '
    .. 'default answer "" '
    .. 'with title "Mouse Sentinel" '
    .. 'buttons {"Cancellare", "Pergere"} default button "Pergere"'
  local out, status = hs.execute("osascript -e '" .. scpt_user .. "'")
  if not status then return nil end
  local username = assert(out:match("text returned:(.+)"), "failed to parse username from osascript")
  username = username:gsub("%s+$", "")

  -- TODO: translate Latin copy to English
  local scpt_token = 'display dialog "Signum authenticum Beeminder inscribe:" '
    .. 'default answer "" '
    .. 'with hidden answer '
    .. 'with title "Mouse Sentinel" '
    .. 'buttons {"Cancellare", "Pergere"} default button "Pergere"'
  local out2, status2 = hs.execute("osascript -e '" .. scpt_token .. "'")
  if not status2 then return nil end
  local auth_token = assert(out2:match("text returned:(.+)"), "failed to parse auth_token from osascript")
  auth_token = auth_token:gsub("%s+$", "")

  return { username = username, auth_token = auth_token }
end

local creds

local function creds_setup()
  local t = creds_ask()
  if not t then return end
  creds_save(t)
  creds = t
end

-- TODO: translate Latin menu item to English
local mb = hs.menubar.new()
mb:setTitle("MS")
mb:setMenu({
  { title = "Optiones...", fn = creds_setup },
})

creds = creds_load()
if not creds then creds_setup() end
