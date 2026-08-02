local CONFIG_FILE = ".ccget"
local MAX_RETRIES = 4
local RETRY_WAIT = 1.5
local REQUEST_COOLDOWN = 0.8

local function usage()
  print("CC GitHub Code Hub")
  print("ccget setup <owner> <repo> [branch] [folder]")
  print("ccget list")
  print("ccget pull <remote.lua> [local]")
  print("ccget pull-all [delay_seconds]")
  print("ccget run <remote.lua> [args...]")
  print("ccget url <remote.lua>")
  print("ccget update")
end

local function save_config(cfg)
  local h = fs.open(CONFIG_FILE, "w")
  h.write(textutils.serialize(cfg))
  h.close()
end

local function load_config()
  if not fs.exists(CONFIG_FILE) then
    error("Not configured. Run: ccget setup <owner> <repo> [branch] [folder]", 0)
  end
  local h = fs.open(CONFIG_FILE, "r")
  local text = h.readAll()
  h.close()
  local cfg = textutils.unserialize(text)
  if type(cfg) ~= "table" or not cfg.owner or not cfg.repo then
    error("Bad config. Run setup again.", 0)
  end
  cfg.branch = cfg.branch or "main"
  cfg.folder = cfg.folder or "scripts"
  return cfg
end

local function encode_path(s)
  return tostring(s):gsub(" ", "%%20"):gsub("#", "%%23"):gsub("%?", "%%3F")
end

local function normalize_name(name)
  if not name or name == "" then error("Missing file name", 0) end
  if not name:match("%.lua$") then name = name .. ".lua" end
  return name
end

local function raw_base(cfg)
  return "https://raw.githubusercontent.com/" .. cfg.owner .. "/" .. cfg.repo .. "/" .. cfg.branch .. "/"
end

local function script_url(cfg, name)
  name = normalize_name(name)
  local folder = cfg.folder
  if folder ~= "" and folder:sub(-1) ~= "/" then folder = folder .. "/" end
  return raw_base(cfg) .. encode_path(folder .. name)
end

local function wait(seconds)
  if sleep then sleep(seconds) end
end

local function open_http(url)
  local last_err = nil
  for attempt = 1, MAX_RETRIES do
    local h, err = http.get(url, { ["User-Agent"] = "ccget" })
    if h then return h end
    last_err = err or "connection failed"
    print("HTTP failed (" .. attempt .. "/" .. MAX_RETRIES .. "): " .. last_err)
    wait(RETRY_WAIT * attempt)
  end
  error(last_err or ("HTTP failed: " .. url), 0)
end

local function get(url)
  local h = open_http(url)
  local text = h.readAll()
  h.close()
  wait(REQUEST_COOLDOWN)
  return text
end

local function download_to_file(url, path)
  local tmp = path .. ".tmp"
  if fs.exists(tmp) then fs.delete(tmp) end
  local last_err = nil
  for attempt = 1, MAX_RETRIES do
    local ok, result = pcall(function()
      local h = open_http(url)
      local out = fs.open(tmp, "w")
      local total = 0
      while true do
        local chunk = h.read(8192)
        if not chunk then break end
        out.write(chunk)
        total = total + #chunk
        if total % 65536 == 0 then wait(0) end
      end
      out.close()
      h.close()
      return total
    end)
    if ok then
      if fs.exists(path) then fs.delete(path) end
      fs.move(tmp, path)
      wait(REQUEST_COOLDOWN)
      return result
    end
    last_err = tostring(result)
    if fs.exists(tmp) then fs.delete(tmp) end
    print("Download retry (" .. attempt .. "/" .. MAX_RETRIES .. "): " .. last_err)
    wait(RETRY_WAIT * attempt)
  end
  error(last_err or ("Download failed: " .. url), 0)
end

local function manifest_names(text)
  local names = {}
  for line in text:gmatch("[^\r\n]+") do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" then table.insert(names, normalize_name(line)) end
  end
  return names
end

local args = {...}
local cmd = args[1]

if cmd == "setup" then
  local owner, repo = args[2], args[3]
  if not owner or not repo then return usage() end
  local cfg = {
    owner = owner,
    repo = repo,
    branch = args[4] or "main",
    folder = args[5] or "scripts"
  }
  save_config(cfg)
  print("Configured " .. owner .. "/" .. repo)
elseif cmd == "list" then
  local cfg = load_config()
  print(get(raw_base(cfg) .. "manifest.txt"))
elseif cmd == "pull" then
  local cfg = load_config()
  local remote = normalize_name(args[2])
  local local_path = args[3] or remote
  local bytes = download_to_file(script_url(cfg, remote), local_path)
  print("Saved " .. local_path .. " (" .. bytes .. " bytes)")
elseif cmd == "pull-all" then
  local cfg = load_config()
  local delay = tonumber(args[2]) or 2
  local names = manifest_names(get(raw_base(cfg) .. "manifest.txt"))
  for i, name in ipairs(names) do
    print("Pulling " .. name .. " (" .. i .. "/" .. #names .. ")")
    local bytes = download_to_file(script_url(cfg, name), name)
    print("Saved " .. name .. " (" .. bytes .. " bytes)")
    wait(delay)
  end
elseif cmd == "run" then
  local cfg = load_config()
  local remote = normalize_name(args[2])
  local temp = ".ccget_run"
  download_to_file(script_url(cfg, remote), temp)
  local run_args = {}
  for i = 3, #args do table.insert(run_args, args[i]) end
  shell.run(temp, table.unpack(run_args))
elseif cmd == "url" then
  local cfg = load_config()
  print(script_url(cfg, args[2]))
elseif cmd == "update" then
  local cfg = load_config()
  download_to_file(raw_base(cfg) .. "ccget.lua", "ccget")
  print("Updated ccget")
else
  usage()
end
