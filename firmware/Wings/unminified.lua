do

local bootfilenames = {
    "/boot/kernel/pipes",
    "/OS.lua",
    "/init.lua",
}

local c = component
local com = computer
local component_invoke = c.invoke
local cl = c.list
local cp = c.proxy
local function boot_invoke(address, method, ...)
    local result = table.pack(pcall(component_invoke, address, method, ...))
    if not result[1] then
        return nil, result[2]
    else
        return table.unpack(result, 2, result.n)
    end
end

local function getBootable(drive)
    local driveproxy = cp(drive)

    for i,v in ipairs(bootfilenames) do
        if driveproxy.exists(v) then
            return v
        end
    end
end

local function downloadFile(url)
    local internetThing = cl("internet")()
    if not internetThing then return end
    local internet = cp(internetThing)
    local handle, chunk = internet.request(url)

    local result = ""

    while true do
        chunk = handle.read(math.huge)
        
        if chunk then
            result = result .. chunk
        else
            break
        end
    end

    handle.close()

    return result
end

local function clearDrive(addr)
    local pickeddriveproxy = cp(addr)
    local files = pickeddriveproxy.list("/")
    for k,v in ipairs(files) do
        pickeddriveproxy.remove(v)
    end
    pickeddriveproxy.setLabel(nil)
end

local eeprom = cl("eeprom")()
com.getBootAddress = function()
    return boot_invoke(eeprom, "getData")
end
com.setBootAddress = function(address)
    return boot_invoke(eeprom, "setData", address)
end

local screen = cl("screen")()
local gpu = cp(cl("gpu")())

if gpu and screen then
    boot_invoke(gpu, "bind", screen)
end

if not gpu then
    error("No graphics card available")
end

local w, h = gpu.getResolution()
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0)
gpu.fill(1, 1, w, h, " ")

local gs = gpu.set

gs(1,1, "Wings BIOS")
gs(1,2, "Press left control to boot BIOS")

local function tryLoadFrom(addr)
    com.setBootAddress(addr)
    gpu.fill(1, 1, w, h, " ")
    gs(1, 1, "Booting in " .. addr .. "...")
    local f = getBootable(addr)
    local handle, reason = boot_invoke(addr, "open", f)
    if not handle then
        return nil, reason
    end
    local buffer = ""
    repeat
        local data, reason = boot_invoke(addr, "read", handle, math.huge)
        if not data and reason then
            return nil, reason
        end
        buffer = buffer .. (data or "")
    until not data
    boot_invoke(addr, "close", handle)
    return load(buffer, "=" .. f)
end

local function BootDefault()
    local init = tryLoadFrom(com.getBootAddress()) -- Attempt to boot into last boot address

    if init then
        init()
    else
        for fileSys in cl("filesystem") do
            init = tryLoadFrom(fileSys)
            if init then
                return init()
            end
        end

        if init then
            init()
        else
            error("No bootable device found")
        end
    end
end

local pullsig = com.pullSignal

do

local id, _, _, code = pullsig(3)

if id ~= "key_down" or code ~= 29 then
    -- If the user did not press left control, we go to quick boot
    BootDefault()
end

end

-- time to actually setup cool bios

local t = "touch"

local currmenu = "m"
local currdrive = ""
local currdrivetxt = ""
local err = ""
local goback = ""

while true do
gpu.fill(1, 1, w, h, " ")

local fses = {}
local txt = {}

for fileSys in cl("filesystem") do
    local proxy = cp(fileSys)
    if com.tmpAddress() ~= fileSys then
        table.insert(fses, fileSys)
        local selTxt = ""
        if com.getBootAddress() == fileSys then
            selTxt = " < Default boot drive"
        end
        local label = proxy.getLabel()
        local usedspace = math.floor((proxy.spaceUsed()/1048576)*100)/100
        local totalspace = math.floor((proxy.spaceTotal()/1048576)*100)/100
        if label then
            table.insert(txt, label .. " (" .. string.sub(fileSys,1,8) .. ") (" .. usedspace .. "/" .. totalspace .. "MB used)" .. selTxt)
        else
            table.insert(txt, string.sub(fileSys,1,8) .. " (" .. usedspace .. "/" .. totalspace .. "MB used)" .. selTxt)
        end
    end
end

if currmenu == "m" then
    local opt = {"Wings BIOS", "", "Drives", "Update BIOS"}

    for i,v in ipairs(opt) do
        gs(1, i, v)
    end

    local id, _, x, y = pullsig()
    if id == t then
        for i,v in ipairs(opt) do
            if y == i then
                if x >= 1 and x <= #v then
                    if i == 3 then
                        currmenu = "d"
                    elseif i == 4 then
                        local download = downloadFile("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/Wings/minified.lua")
                        if download then
                            boot_invoke(eeprom, "set", download)
                            err = "Sucessfully updated!"
                            goback = "m"
                            currmenu = "e"
                        else
                            err = "No internet card detected"
                            goback = "m"
                            currmenu = "e"
                        end
                    end
                end
            end
        end
    end
end

if currmenu == "d" then
    local opt = {"Boot normally","Back"}
    for i = #txt,1,-1 do table.insert(opt,1,txt[i]) end

    for i,v in ipairs(opt) do
        gs(1, i, v)
    end

    local id, _, x, y = pullsig()
    if id == t then
        for i,v in ipairs(opt) do
            if y == i then
                if x >= 1 and x <= #v then
                    if i <= #txt then
                        currdrive = fses[i]
                        currdrivetxt = txt[i]
                        currmenu = "ds"
                    elseif i == #txt+1 then
                        BootDefault()
                    elseif i == #txt+2 then
                        currmenu = "m"
                    end
                end
            end
        end
    end
end

if currmenu == "ds" then
    local opt = {currdrivetxt,"","Erase Drive", "Boot Drive", "Back"}

    for i,v in ipairs(opt) do
        gs(1, i, v)
    end

    local id, _, x, y = pullsig()
    if id == t then
        for i,v in ipairs(opt) do
            if y == i then
                if x >= 1 and x <= #v then
                    if i == 3 then
                        currmenu = "es"
                    elseif i == 4 then
                        local init = tryLoadFrom(currdrive) -- Attempt to boot into last boot address
                        if init then
                            init()
                        else
                            err = "Drive failed to boot"
                            goback = "ds"
                            currmenu = "e"
                        end
                    elseif i == 5 then
                        currmenu = "d"
                        currdrive = ""
                    end
                end
            end
        end
    end
end

if currmenu == "es" then
    local opt = {"Are you sure you want to erase this drive?", "", "Yes", "No"}

    for i,v in ipairs(opt) do
        gs(1, i, v)
    end

    local id, _, x, y = pullsig()
    if id == t then
        for i,v in ipairs(opt) do
            if y == i then
                if x >= 1 and x <= #v then
                    if i == 3 then
                        clearDrive(currdrive)
                        currmenu = "d"
                        currdrive = ""
                    elseif i == 4 then
                        currmenu = "d"
                        currdrive = ""
                    end
                end
            end
        end
    end
end

if currmenu == "e" then
    local opt = {err, "", "Back"}

    for i,v in ipairs(opt) do
        gs(1, i, v)
    end

    local id, _, x, y = pullsig()
    if id == t then
        for i,v in ipairs(opt) do
            if y == i then
                if x >= 1 and x <= #v then
                    if i == 3 then
                        currmenu = goback
                    end
                end
            end
        end
    end
end

end



end