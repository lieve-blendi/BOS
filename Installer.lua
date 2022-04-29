-- This system will likely get updated with better stuff

local repoPath = "https://raw.githubusercontent.com/IonutParau/KOCOS/main"

local filePaths = {
  "/init.lua",
  "/libs",
  "/libs/prints.lua",
}

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
    
    local f = io.open(p, "w")
    f:write(result)
    f:close()
  else
    fs.makeDirectory(p)
  end
end

computer.shutdown(true)