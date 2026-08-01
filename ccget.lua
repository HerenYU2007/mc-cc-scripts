local CONFIG_FILE = ".ccget"

local function usage()
  print("CC GitHub Code Hub")
  print("ccget setup <owner> <repo> [branch] [folder]")
  print("ccget list")
  print("ccget pull <remote.lua> [local]")
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

local function get(url)
  local h, err = http.get(url)
  if not h then error(err or ("HTTP failed: " .. url), 0) end
  local text = h.readAll()
  h.close()
  return text
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
  local text = get(script_url(cfg, remote))
  local h = fs.open(local_path, "w")
  h.write(text)
  h.close()
  print("Saved " .. local_path)
elseif cmd == "run" then
  local cfg = load_config()
  local remote = normalize_name(args[2])
  local temp = ".ccget_run"
  local text = get(script_url(cfg, remote))
  local h = fs.open(temp, "w")
  h.write(text)
  h.close()
  local run_args = {}
  for i = 3, #args do table.insert(run_args, args[i]) end
  shell.run(temp, table.unpack(run_args))
elseif cmd == "url" then
  local cfg = load_config()
  print(script_url(cfg, args[2]))
elseif cmd == "update" then
  local cfg = load_config()
  local text = get(raw_base(cfg) .. "ccget.lua")
  local h = fs.open("ccget", "w")
  h.write(text)
  h.close()
  print("Updated ccget")
else
  usage()
end
