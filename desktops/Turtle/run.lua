local Turtle = {}
Turtle.RGPU = Drivers.rgpu
Turtle.gpu = Drivers.rgpu.gpu
Turtle.Keys = Drivers.keys
Turtle.Keyboard = Drivers.keyboard
Turtle.Symbols = Drivers.symbols
Turtle.Singleize = Drivers.singleize
Turtle.Text = Drivers.text
Turtle.CurrentProgram = "Shell"

Turtle.version = "0.0.1"

local Message = FileSystem:loadfile("desktops/Turtle/message.lua")

local function splitcmd(cmd)
    local split = {}
    local currindex = 1
    local i = 0
    while i < #cmd do
        if split[currindex] == nil then split[currindex] = "" end
        i = i + 1
        local char = cmd:sub(i,i)
        if char == '"' then
            local found = false
            local foundpos = 0
            for j = i+1,#cmd do
                local char2 = cmd:sub(j,j)
                if char2 == '"' then
                    found = true
                    foundpos = j
                    break
                end
            end
            if not found then
                Turtle.print('Unfinished " found.')
                return
            end
            if split[currindex] == nil then split[currindex] = "" end
            local spos,epos = i,foundpos
            if spos < epos-1 and epos > spos+1 then
                split[currindex] = split[currindex] .. string.sub(cmd,spos+1,epos-1)
            end
            i = foundpos
        elseif char == " " then
            currindex = currindex + 1
        else
            if split[currindex] == nil then split[currindex] = "" end
            split[currindex] = split[currindex] .. char
        end
    end
    return split
end

Turtle.Keyboard:AddListener(function(key,down)
    if Turtle.CurrentProgram == "Shell" and down then
        key = Turtle.Keys[key]
        if key == "enter" then
            if #Turtle.Input > 0 then
                Turtle.print("> " .. Turtle.Input)
                local spl = splitcmd(Turtle.Input)
                if not spl then Turtle.Input = "" return end
                local cmd = spl[1]
                table.remove(spl, 1)
                SH:run(cmd, spl)
                Turtle.Input = ""
            end
        elseif key == "back" then
            Turtle.Input = string.sub(Turtle.Input, 1, #Turtle.Input - 1)
        elseif key == "space" then
            Turtle.Input = Turtle.Input .. " "
        else
            local kkey = key
            if Turtle.Singleize.Singleize(key) then
                kkey = Turtle.Singleize.Singleize(key)
            end
            if type(kkey) == "string" and #kkey == 1 then
                if Turtle.Keyboard:IsDown(Turtle.Keys["lshift"]) then
                    if Turtle.Symbols[kkey] then
                        kkey = Turtle.Symbols[kkey]
                    else
                        kkey = string.upper(kkey)
                    end
                end
                Turtle.Input = Turtle.Input .. kkey
            end
        end
    end
end)

Turtle.PrintStack = {}
Turtle.OldPrintStack = {}
Turtle.Input = ""
Turtle.OldInput = nil

local function tablecopy(table)
    local new = {}
    for i,v in ipairs(table) do
        new[i] = v
    end
    return new
end

Turtle.print = function(...)
    local w,h = Turtle.gpu.getResolution()
    local prints = {...}
    for k,v in ipairs(prints) do
        Turtle.PrintStack[#Turtle.PrintStack + 1] = v
    end
    while #Turtle.PrintStack >= h do
        table.remove(Turtle.PrintStack, 1)
    end
    Message.OldInput = nil
end

function Turtle:show()
    if Turtle.CurrentProgram == "Shell" then
        local w,h = Turtle.gpu.getResolution()
        for k,v in ipairs(Turtle.PrintStack) do
            if Turtle.OldPrintStack ~= Turtle.PrintStack then
                self.gpu.set(1,k,v)
                if (#v < w) and (#v < #(Turtle.OldPrintStack[k] or "")) then
                    self.gpu.fill(#v+1, k, w, k, " ")
                end
                Turtle.OldPrintStack = tablecopy(Turtle.PrintStack)
            end
        end
        if Turtle.OldInput ~= Turtle.Input then
            self.gpu.set(1,#Turtle.PrintStack+1,"> " .. Turtle.Input)
            if (#Turtle.Input+2 < w) and (#Turtle.Input+2 < #(Turtle.OldInput or "")+2) then
                self.gpu.fill(#Turtle.Input+3, #Turtle.PrintStack+1, w, #Turtle.PrintStack+1, " ")
            end
            Turtle.OldInput = Turtle.Input
        end
    elseif Turtle.CurrentProgram == "Message" then
        Message:Render()
    end
end

function Turtle:processSignal(signal)
    if Turtle.CurrentProgram == "Shell" then
        Turtle.Keyboard:ProcessSignal(signal)
    end
    if Turtle.CurrentProgram == "Message" then
        Message:ProcessSignal(signal)
    end
end

function Turtle:load()
    self.gpu.setBackground(0x000000)
    self.gpu.setForeground(0xc9c9c9)
    self.RGPU:clear()

    table.insert(Turtle.PrintStack, OS.name .. " v" .. OS.version .. " - Turtle Desktop Environment v" .. Turtle.version)
    table.insert(Turtle.PrintStack, "Running " .. SH.name .. " v" .. SH.version)
    table.insert(Turtle.PrintStack, "")

    Message:Init()
end

return Turtle