-- This system will likely get updated with better stuff

local repoPath = "https://raw.githubusercontent.com/lieve-blendi/BOS/main"

local filePaths = {
  "/init.lua",
  "/drivers",
  "/drivers/keyboard.lua",
  "/drivers/rgpu.lua",
  "/drivers/text.lua",
  "/desktops",
  "/desktops/Bird.lua",
  "/shells",
  "/shells/Carrot.lua"
}

local component = require("component")
local computer = require("computer")

local eeprom = component.eeprom

local function isLuaScript(path)
  return (path:sub(-4) == ".lua")
end

local fs = require("filesystem")
local internet = require("internet")

if not internet then
  print("No internet API detected, please make sure you have a internet card installed.")
  return
end

-- should we make people select what drive?

for _, p in ipairs(filePaths) do
  if isLuaScript(p) then
    local result = ""

    local handle = internet.request(repoPath .. p)
    for chunk in handle do result = result .. chunk end
    
    local f = io.open(p, "w")
    if f then
      f:write(result)
      f:close()
    end
  else
    fs.makeDirectory(p)
  end
end

-- How do i set drive label?

print("Would you like to install our custom BIOS?")
ans = io.read()
if ans == "Y" or ans == "y" or ans == "Yes" or ans == "yes" then
  local result = ""

  local handle = internet.request(repoPath .. "/firmware.lua")
  for chunk in handle do result = result .. chunk end
  
  eeprom.set(result)
  eeprom.setLabel("B-BIOS")
end

computer.shutdown(true)
