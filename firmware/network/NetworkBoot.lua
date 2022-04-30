local component_invoke = component.invoke
local function boot_invoke(address, method, ...)
    local result = table.pack(pcall(component_invoke, address, method, ...))
    if not result[1] then
    return nil, result[2]
    else
    return table.unpack(result, 2, result.n)
    end
end

local eeprom = component.list("eeprom")()
computer.getBootAddress = function()
    return boot_invoke(eeprom, "getData")
end
computer.setBootAddress = function(address)
    return boot_invoke(eeprom, "setData", address)
end

local screen = component.list("screen")()
local gpu = component.list("gpu")()
if gpu and screen then
    boot_invoke(gpu, "bind", screen)
end

local internet = component.list("internet")()
if not internet then
    error("NetworkBoot requires internet to run. Please add an internet card")
end

local ref = "https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/network/NetworkBoot.lua"
boot_invoke(gpu, "set", 1, 1, "Downloading Network file...")

local result = ""
local handle = boot_invoke(internet, "request", ref)
for chunk in handle do result = result .. chunk end

local init, initreason = load(result, '=NetworkBoot.lua', 'bt', _G)
if init then
    init()
else
    error("Failed to load BIOS over network: " .. initreason)
end