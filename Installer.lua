local repoPath = "https://raw.githubusercontent.com/lieve-blendi/BOS/main"

local filePaths = {
  "/init.lua",
  "/drivers",
  "/drivers/keyboard.lua",
  "/drivers/rgpu.lua",
  "/drivers/text.lua",
  "/drivers/window.lua",
  "/drivers/keys.lua",
  "/desktops",
  "/desktops/Turtle",
  "/desktops/Turtle/run.lua",
  "/desktops/Turtle/message.lua",
  "/desktops/Bird",
  "/desktops/Bird/run.lua",
  "/shells",
  "/shells/Carrot.lua",
  "/apps",
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
    print("Deleting " .. v .. "...")
    pickeddriveproxy.remove(v)
  end
end

print("Downloading known files...")
for _, p in ipairs(filePaths) do
  if isLuaScript(p) then
    print("Downloading " .. p .. "...")
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
  print("Which BIOS would you like to install?")
  print("Available options:")
  print("1. B-BIOS (minimal, fast, handles multi-booting)")
  print("2. SnowBoot (more powerful than B-BIOS but slower)")
  print("3. CloudBoot (SnowBoot but improved, requires an internet card and internet connection)")
  print("4. NetworkBoot (The most powerful BIOS yet, requires an internet card and internet connection)")
  print("Input the number associated with the BIOS:")
  ans = io.read()
  if ans == "1" then
    local result = ""

    print("Downloading B-BIOS...")
    local handle = internet.request(repoPath .. "/firmware/B-BIOS.lua")
    for chunk in handle do result = result .. chunk end
  
    print("Installing B-BIOS...")
    eeprom.set(result)
    eeprom.setLabel("B-BIOS")
    print("B-BIOS installed!")
  elseif ans == "2" then
    local result = ""

    print("Downloading SnowBoot...")
    local handle = internet.request(repoPath .. "/firmware/SnowBoot.lua")
    for chunk in handle do result = result .. chunk end
    
    print("Installing SnowBoot...")
    eeprom.set(result)
    eeprom.setLabel("SnowBoot")
    print("SnowBoot installed!")
  elseif ans == "3" then
    local result = ""

    print("Downloading CloudBoot...")
    local handle = internet.request(repoPath .. "/firmware/CloudBoot/Boot.lua")
    for chunk in handle do result = result .. chunk end
    
    print("Installing CloudBoot...")
    eeprom.set(result)
    eeprom.setLabel("CloudBoot")
    print("CloudBoot installed!")
  elseif ans == "4" then
    local result = ""

    print("Downloading NetworkBoot...")
    local handle = internet.request(repoPath .. "/firmware/network/NetworkBoot.lua")
    for chunk in handle do result = result .. chunk end
    
    print("Installing NetworkBoot...")
    eeprom.set(result)
    eeprom.setLabel("NetworkBoot")
    print("NetworkBoot installed!")
  end
end

computer.shutdown(true)
