do

local bootfilenames = {
    "/boot/kernel/pipes",
    "/OS.lua",
    "/init.lua",
}

local c = component
local com = computer
local component_invoke = c.invoke
local function boot_invoke(address, method, ...)
    local result = table.pack(pcall(component_invoke, address, method, ...))
    if not result[1] then
        return nil, result[2]
    else
        return table.unpack(result, 2, result.n)
    end
end

local function getBootable(drive)
    local driveproxy = c.proxy(drive)

    for i,v in ipairs(bootfilenames) do
        if driveproxy.exists(v) then
            return v
        end
    end
end

local function downloadFile(url)
    local internetThing = c.list("internet")()
    if not internetThing then return end
    local internet = c.proxy(internetThing)
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
    local pickeddriveproxy = c.proxy(addr)
    local files = pickeddriveproxy.list("/")
    for k,v in ipairs(files) do
        pickeddriveproxy.remove(v)
    end
    pickeddriveproxy.setLabel(nil)
end

local eeprom = c.list("eeprom")()
com.getBootAddress = function()
    return boot_invoke(eeprom, "getData")
end
com.setBootAddress = function(address)
    return boot_invoke(eeprom, "setData", address)
end

local screen = c.list("screen")()
local gpu = c.proxy(c.list("gpu")())

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

gpu.set(1,1, "Wings BIOS")
gpu.set(1,2, "Press left control to boot BIOS")

local function tryLoadFrom(addr)
    com.setBootAddress(addr)
    gpu.fill(1, 1, w, h, " ")
    gpu.set(1, 1, "Booting in " .. addr .. "...")
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

do
local id, _, _, code = com.pullSignal(3)

if id ~= "key_down" or code ~= 29 then
    -- If the user did not press left control, we go to quick boot
    local init, reason = tryLoadFrom(com.getBootAddress()) -- Attempt to boot into last boot address

    if init then
        init()
    else
        for fileSys in c.list("filesystem") do
            init, reason = tryLoadFrom(fileSys)
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
end

-- time to actually setup cool bios

local currmenu = "main"
local currdrive = ""
local currdrivetxt = ""

while true do
gpu.fill(1, 1, w, h, " ")

local fses = {}
local txt = {}

for fileSys in c.list("filesystem") do
    local proxy = c.proxy(fileSys)
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

if currmenu == "main" then
    local opt = {"Drives", "Update BIOS"}

    for i,v in ipairs(opt) do
        gpu.set(1, i, v)
    end

    local id, _, x, y = com.pullSignal()
    if id == "touch" then
        for i,v in ipairs(opt) do
            if y == i then
                if x >= 1 and x <= #v then
                    if i == 1 then
                        currmenu = "drives"
                    elseif i == 2 then
                        local download = downloadFile("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/Wings/minified.lua")
                        if download then
                        else
                            currmenu = "nointcard"
                        end
                    end
                end
            end
        end
    end
end

if currmenu == "drives" then
    local nboot = "Boot normally"
    local b = "Back"
    for i,v in ipairs(fses) do
        gpu.set(1, i, txt[i])
    end
    gpu.set(1,#fses+1,nboot)
    gpu.set(1,#fses+2,b)

    local id, _, x, y = com.pullSignal()
    if id == "touch" then
        if y >= 1 and y <= #fses then
            if x >= 1 and x <= #txt[y] then
                currdrive = fses[y]
                currdrivetxt = txt[y]
                currmenu = "drivesettings"
            end
        elseif y == #fses+1 then
            if x >= 1 and x <= #nboot then
                local init, reason = tryLoadFrom(com.getBootAddress()) -- Attempt to boot into last boot address

                if init then
                    init()
                else
                    for fileSys in c.list("filesystem") do
                        init, reason = tryLoadFrom(fileSys)
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
        elseif y == #fses+2 then
            if x >= 1 and x <= #b then
                currmenu = "main"
            end
        end
    end
end

if currmenu == "drivesettings" then
    local opt = {currdrivetxt,"","Erase Drive", "Boot Drive", "Back"}

    for i,v in ipairs(opt) do
        gpu.set(1, i, v)
    end

    local id, _, x, y = com.pullSignal()
    if id == "touch" then
        for i,v in ipairs(opt) do
            if y == i then
                if x >= 1 and x <= #v then
                    if i == 3 then
                        currmenu = "erasesure"
                    elseif i == 4 then
                        local init, reason = tryLoadFrom(currdrive) -- Attempt to boot into last boot address
                        if init then
                            init()
                        else
                            currmenu = "bootfail"
                        end
                    elseif i == 5 then
                        currmenu = "drives"
                        currdrive = ""
                    end
                end
            end
        end
    end
end

if currmenu == "erasesure" then
    local opt = {"Are you sure you want to erase this drive?", "", "Yes", "No"}

    for i,v in ipairs(opt) do
        gpu.set(1, i, v)
    end

    local id, _, x, y = com.pullSignal()
    if id == "touch" then
        for i,v in ipairs(opt) do
            if y == i then
                if x >= 1 and x <= #v then
                    if i == 3 then
                        clearDrive(currdrive)
                        currmenu = "drives"
                        currdrive = ""
                    elseif i == 4 then
                        currmenu = "drives"
                        currdrive = ""
                    end
                end
            end
        end
    end
end

if currmenu == "bootfail" then
    local opt = {"Drive failed to boot", "", "Back"}

    for i,v in ipairs(opt) do
        gpu.set(1, i, v)
    end

    local id, _, x, y = com.pullSignal()
    if id == "touch" then
        for i,v in ipairs(opt) do
            if y == i then
                if x >= 1 and x <= #v then
                    if i == 3 then
                        currmenu = "drivesettings"
                    end
                end
            end
        end
    end
end

if currmenu == "nointcard" then
    local opt = {"No internet card detected", "", "Back"}

    for i,v in ipairs(opt) do
        gpu.set(1, i, v)
    end

    local id, _, x, y = com.pullSignal()
    if id == "touch" then
        for i,v in ipairs(opt) do
            if y == i then
                if x >= 1 and x <= #v then
                    if i == 3 then
                        currmenu = "main"
                    end
                end
            end
        end
    end
end

end



end