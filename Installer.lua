-- This system will likely get updated with better stuff

local repoPath = "https://raw.githubusercontent.com/lieve-blendi/BOS/main"

local filePaths = {
  "/init.lua",
  "/drivers",
  "/drivers/keyboard.lua",
  "/drivers/rgpu.lua",
  "/drivers/text.lua",
  "/desktops/Bird.lua",
  "/shells/Carrot.lua"
}

local function getComponentAddress(name)
	return component.list(name)() or error("Required " .. name .. " component is missing")
end

local function getComponentProxy(name)
	return component.proxy(getComponentAddress(name))
end

local EEPROMProxy, internetProxy, GPUProxy = 
	getComponentProxy("eeprom"),
	getComponentProxy("internet"),
	getComponentProxy("gpu")

local function isLuaScript(path)
  return (path:sub(-4) == ".lua")
end

local fs = require("filesystem")
local internet = require("internet")

if not internet then
  print("No internet API detected, please make sure you have a internet card installed.")
  return
end

for _, p in ipairs(filePaths) do
  if isLuaScript(p) then
    local result = ""

    local handle = internet.request(repoPath .. p)
    for chunk in handle do result = result .. chunk end
    
    handle.close()
    local f = io.open(p, "w")
    f:write(result)
    f:close()
  else
    fs.makeDirectory(p)
  end
end

do
  local result = ""

  local handle = internet.request(repoPath .. "/firmware.lua")
  for chunk in handle do result = result .. chunk end
  
  handle.close()
  EEPROMProxy.set(result)
  EEPROMProxy.setLabel("B-BIOS")
end

computer.shutdown(true)
