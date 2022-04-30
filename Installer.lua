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

local drives = {}

for fileSys in component.list("filesystem") do
  if computer.tmpAddress() ~= fileSys then
    local proxy = component.proxy(fileSys)
    if proxy.spaceTotal() > 1024*1024 then
      table.insert(drives, fileSys)
    end
  end
end

print("Welcome to the BOS installer!\nPlease pick a drive to install to:")
for k,v in ipairs(drives) do
  local proxy = component.proxy(v)
  if proxy.getLabel() then
    print(k .. ". " .. math.floor((proxy.spaceUsed()/1024/1024)*100)/100 .. "/" .. math.floor((proxy.spaceTotal()/1024/1024)*100)/100 .. "MB used - " .. proxy.getLabel() .. " (" .. v .. ")")
  else
    print(k .. ". " .. math.floor((proxy.spaceUsed()/1024/1024)*100)/100 .. "/" .. math.floor((proxy.spaceTotal()/1024/1024)*100)/100 .. "MB used - " .. v)
  end
end
local pickeddrive

while pickeddrive == nil do
  local picked = io.read()
  if drives[tonumber(picked)] then
    pickeddrive = drives[tonumber(picked)]
  end
  os.sleep()
end

local pickeddriveproxy = component.proxy(pickeddrive)
print("You picked drive: " .. pickeddrive)

print("Would you like to clear this drive?")
local ans = io.read()
if ans == "Y" or ans == "y" or ans == "Yes" or ans == "yes" then
  local files = pickeddriveproxy.list("/")
  for k,v in ipairs(files) do
    pickeddriveproxy.remove(v)
  end
end

for _, p in ipairs(filePaths) do
  if isLuaScript(p) then
    local result = ""

    local handle = internet.request(repoPath .. p)
    for chunk in handle do result = result .. chunk end
    
    local f = pickeddriveproxy.open(p, "w")
    if f then
      print("Installing file " .. p .. "...")
      pickeddriveproxy.write(f,result)
      pickeddriveproxy.close(f)
    end
  else
    pickeddriveproxy.makeDirectory(p)
  end
end

pickeddriveproxy.setLabel("BOS")

print("Would you like to install our custom BIOS?")
ans = io.read()
if ans == "Y" or ans == "y" or ans == "Yes" or ans == "yes" then
  local result = ""

  local handle = internet.request(repoPath .. "/firmware.lua")
  for chunk in handle do result = result .. chunk end
  
  print("Installing BIOS...")
  eeprom.set(result)
  eeprom.setLabel("B-BIOS")
  print("BIOS installed!")
end

computer.shutdown(true)
