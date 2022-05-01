local component_invoke = component.invoke
local function boot_invoke(address, method, ...)
    local result = table.pack(pcall(component_invoke, address, method, ...))
    if not result[1] then
    return nil, result[2]
    else
    return table.unpack(result, 2, result.n)
    end
end

local gpu = component.proxy(component.list("gpu")())
local w, h = gpu.getResolution()
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)
gpu.fill(1, 1, w, h, " ")

gpu.set(1, 1, "Network Boot v1")
gpu.set(1, 2, "Press Left Control to open advanced BIOS mode")

local function getBootable(drive)
    local driveproxy = component.proxy(drive)

    if driveproxy.exists("/init.lua") then
        return "/init.lua"
    elseif driveproxy.exists("/boot/kernel/pipes") then
        return "/boot/kernel/pipes"
    elseif driveproxy.exists("/OS.lua") then
        return "/OS.lua"
    end
end

local function tryLoadFrom(addr)
    computer.setBootAddress(addr)
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0x000000)
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

local eeprom = component.list("eeprom")()
computer.getBootAddress = function()
    return boot_invoke(eeprom, "getData")
end
computer.setBootAddress = function(address)
    return boot_invoke(eeprom, "setData", address)
end

local id, addr, char, code = computer.pullSignal(5)
if not ((id == "key_down") and (code == 0x1D)) then
    -- If the user did not press left control, we go to quick boot
    local init, reason = tryLoadFrom(computer.getBootAddress()) -- Attempt to boot into last boot address

    if init then
        init()
    else
        for fileSys in component.list("filesystem") do
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

local function clearDrive(addr)
    local pickeddriveproxy = component.proxy(addr)
    local files = pickeddriveproxy.list("/")
    for k,v in ipairs(files) do
        pickeddriveproxy.remove(v)
    end
    pickeddriveproxy.setLabel(nil)
end

local fs = {}

local current = "main"
local pointer = 1

local function bootableFS()
    local t = {}
    for _, f in ipairs(fs) do
        if getBootable(f) ~= nil then
            table.insert(t, f)
        end
    end
    return t
end

local function getOptions()
    -- Main screen
    if current == "main" then
        return {
            "Boot",
            "Wipe Drives",
            "Restart",
            "Re-Flash",
            "Change BIOS",
            "Demo BIOS",
            "Cache BIOS",
        }
    end
    -- Boot
    if current == "boot" then
        local t = {}
        for _, f in ipairs(fs) do
            local drive = component.proxy(f)
            if getBootable(f) ~= nil then
                local l = drive.getLabel()
                local selTxt = ""
                if computer.getBootAddress() == f then
                    selTxt = " < Default boot drive"
                end

                if l then
                    table.insert(t, l .. selTxt)
                else
                    table.insert(t, f .. selTxt)
                end
            end
        end
        table.insert(t, "Back")

        return t
    end

    -- Wipe
    if current == "wipe" then
        local t = {}
        for _, f in ipairs(fs) do
            local drive = component.proxy(f)
            local l = drive.getLabel()
            local spaceStr = drive.get
            local usedspace = math.floor((drive.spaceUsed()/1024/1024)*100)/100
            local totalspace = math.floor((drive.spaceTotal()/1024/1024)*100)/100
            local capacityStr = "Size: " .. usedspace .. " MB / " .. totalspace .. " MB"
            if l then
                table.insert(t, l .. " " .. capacityStr)
            else
                table.insert(t, f .. " " .. capacityStr)
            end
        end
        table.insert(t, "Back")

        return t
    end

    -- Change BIOS
    if current == "change_bios" then
        return {
            "NetworkBoot (CURRENT)",
            "CloudBoot",
            "SnowBoot",
            "B-BIOS",
            "Back",
        }
    end

    if current == "demo_bios" then
        return {
            "CloudBoot",
            "SnowBoot",
            "B-BIOS",
            "Back",
        }
    end
end

local function downloadFile(url)
    local internetThing = component.list("internet")()
    if not internetThing then msg = "No internet card available" return end
    local internet = component.proxy(internetThing)
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

local msg

local options = getOptions()

local function clearScreen()
    local w, h = gpu.getResolution()
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0x000000)
    gpu.fill(1, 1, w, h, " ")
end

local function showMsg(msg)
    local w, h = gpu.getResolution()

    gpu.set(1, h, msg or "No message set")
end

local function handleInput()
    if current == "main" and pointer == 1 then
        current = "boot"
        options = getOptions()
        pointer = 1
        return
    end
    if current == "main" and pointer == 2 then
        current = "wipe"
        options = getOptions()
        pointer = 1
        return
    end
    if current == "main" and pointer == 3 then
        computer.shutdown(true)
        return
    end
    if current == "main" and pointer == 4 then
        local eeprom = component.list("eeprom")()
        if not eeprom then
            msg = "Uhh... did you remove your EEPROM?"
            return
        end
        -- Re-flashing EEPROM
        local internetThing = component.list("internet")()
        if internetThing then
            local internet = component.proxy(internetThing)

            local handle, chunk = internet.request("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/network/NetworkBoot.lua")

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

            boot_invoke(eeprom, "set", result)

            msg = "Reinstalled EEPROM"
        else
            msg = "ERROR: Did you seriously remove your internet card?"
        end
        return
    end
    if current == "main" and pointer == 5 then
        current = "change_bios"
        options = getOptions()
        pointer = 1
        return
    end
    if current == "main" and pointer == 6 then
        current = "demo_bios"
        options = getOptions()
        pointer = 1
        return
    end
    if current == "main" and pointer == 7 then
        local f = downloadFile("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/network/NetworkInit.lua")
        if f then
            local d = computer.getBootAddress()
            local handler = boot_invoke(d, "open", "/networkCache.lua")
            boot_invoke(d, "write", handler, f)
            boot_invoke(d,  "close", handler)

            msg = "Locally cached BIOS in default boot drive (" .. d .. ")"
        end
        return
    end
    if current == "boot" and pointer == ((#bootableFS())+1) then
        current = "main"
        options = getOptions()
        pointer = 1
        return
    end
    if current == "wipe" and pointer == (#fs+1) then
        current = "main"
        options = getOptions()
        pointer = 1
        return
    end

    if current == "boot" then
        local init, initreason = tryLoadFrom(bootableFS()[pointer])

        if init then
            init()
        else
            msg = initreason
        end
    end

    if current == "wipe" then
        clearDrive(fs[pointer])
        options = getOptions()
        pointer = 1

        msg = "Drive wiped! All files are gone!"
    end

    if current == "change_bios" and pointer == 1 then
        showMsg("Downloading NetworkBoot...")
        local f = downloadFile("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/network/NetworkBoot.lua")
        if f then
            showMsg("Flashing NetworkBoot...")
            boot_invoke(eeprom, "set", f)
            boot_invoke(eeprom, "setLabel", "NetworkBoot")
            msg = "Reinstalled NetworkBoot"
            return
        end
    end
    if current == "change_bios" and pointer == 2 then
        showMsg("Downloading CloudBoot...")
        local f = downloadFile("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/CloudBoot/Boot.lua")
        if f then
            showMsg("Flashing CloudBoot...")
            boot_invoke(eeprom, "set", f)
            boot_invoke(eeprom, "setLabel", "CloudBoot")
            msg = "Changed to CloudBoot"
            return
        end
    end
    if current == "change_bios" and pointer == 3 then
        showMsg("Downloading SnowBoot...")
        local f = downloadFile("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/SnowBoot.lua")
        if f then
            showMsg("Flashing SnowBoot...")
            boot_invoke(eeprom, "set", f)
            boot_invoke(eeprom, "setLabel", "SnowBoot")
            msg = "Changed to SnowBoot"
            return
        end
    end
    if current == "change_bios" and pointer == 4 then
        showMsg("Downloading B-BIOS...")
        local f = downloadFile("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/B-BIOS.lua")
        if f then
            showMsg("Flashing B-BIOS...")
            boot_invoke(eeprom, "set", f)
            boot_invoke(eeprom, "setLabel", "B-BIOS")
            msg = "Changed to B-BIOS"
            return
        end
    end
    if current == "change_bios" and pointer == 5 then
        current = "main"
        options = getOptions()
        pointer = 1
        return
    end

    if current == "demo_bios" then

        if pointer == 1 then
            clearScreen()
            local f = downloadFile("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/CloudBoot/Boot.lua")
            if f then
                local result, reason = load(f, "=demo_bios")

                if result then
                    result, reason = xpcall(result, debug.traceback)

                    if not result then
                        msg = reason
                    end
                else
                    msg = reason
                end
                return
            end
        end
        if pointer == 2 then
            clearScreen()
            local f = downloadFile("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/SnowBoot.lua")
            if f then
                local result, reason = load(f, "=demo_bios")

                if result then
                    result, reason = xpcall(result, debug.traceback)

                    if not result then
                        msg = reason
                    end
                else
                    msg = reason
                end
                return
            end
        end
        if pointer == 3 then
            clearScreen()
            local f = downloadFile("https://raw.githubusercontent.com/lieve-blendi/BOS/main/firmware/B-BIOS.lua")
            if f then
                local result, reason = load(f, "=demo_bios")

                if result then
                    result, reason = xpcall(result, debug.traceback)

                    if not result then
                        msg = reason
                    end
                else
                    msg = reason
                end
                return
            end
        end
        if pointer == 4 then
            current = "main"
            options = getOptions()
            pointer = 1
            return
        end
    end
end

local KeyMap = {
    enter = 0x1C,
    up = 0xC8,
    down = 0xD0,
}

local booted = false
repeat

    local w, h = gpu.getResolution()
    gpu.setForeground(0xFFFFFF)
    gpu.setBackground(0x000000)
    gpu.fill(1, 1, w, h, " ")

    gpu.set(1, 1, "NetworkBoot")
    local memText = "Memory Usage: " .. tostring(math.floor((computer.totalMemory() - computer.freeMemory()) / computer.totalMemory()*1000 + 0.5)/10) .. "%"
    gpu.set(w-#memText, 1, memText)

    for i, option in ipairs(options) do
        if pointer == i then
            gpu.setForeground(0x000000)
            gpu.setBackground(0xFFFFFF)
        else
            gpu.setForeground(0xFFFFFF)
            gpu.setBackground(0x000000)
        end
        gpu.set(1, i+2, option)
    end

    if type(msg) == "string" then
        gpu.setForeground(0xFFFFFF)
        gpu.setBackground(0x000000)
        gpu.set(1, h, msg)
    end

    local id, addr, char, code = computer.pullSignal(0.1)

    -- Reload FileSystem in case drives changed
    fs = {}
    for fileSys in component.list("filesystem") do
        if fileSys ~= computer.tmpAddress() then
            table.insert(fs, fileSys)
        end
    end

    if id == "key_down" then
        if code == KeyMap.enter then
            handleInput()
        elseif code == KeyMap.up then
            if pointer > 1 then
                pointer = pointer - 1
            end
        elseif code == KeyMap.down then
            if pointer < #options then
                pointer = pointer + 1
            end
        end
    elseif id == "touch" then
        local y = code-2

        if y > 0 and y <= #options then
            pointer = y
            handleInput()
        end
    end
until booted