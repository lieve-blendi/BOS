local Turtle = {}
Turtle.RGPU = Drivers.rgpu
Turtle.gpu = Drivers.rgpu.gpu
Turtle.Keys = Drivers.keys
Turtle.Keyboard = Drivers.keyboard
Turtle.Text = Drivers.text
Turtle.CurrentProgram = "Shell"

local Message = FileSystem:loadfile("apps/message.lua")

Turtle.Keyboard:AddListener(function(key,down)
    if Turtle.CurrentProgram == "Shell" and down then
        key = Turtle.Keys[key]
        if key == "enter" then
            if #Turtle.Input > 0 then
                Turtle.print("> " .. Turtle.Input)
                local spl = Turtle.Text.split(Turtle.Input, " ")
                local cmd = spl[1]
                table.remove(spl, 1)
                SH:run(cmd, spl)
                Turtle.Input = ""
            end
        elseif key == "back" then
            Turtle.Input = string.sub(Turtle.Input, 1, #Turtle.Input - 1)
        elseif key == "space" then
            Turtle.Input = Turtle.Input .. " "
        elseif type(key) == "string" and #key == 1 then
            if Turtle.Keyboard:IsDown(Turtle.Keys["lshift"]) then
                key = string.upper(key)
            end
            Turtle.Input = Turtle.Input .. key
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

    table.insert(Turtle.PrintStack, OS.name .. " v" .. OS.version .. " - Turtle Desktop Environment")
    table.insert(Turtle.PrintStack, "Running " .. SH.name .. " v" .. SH.version)
    table.insert(Turtle.PrintStack, "")

    Message:Init()
end

return Turtle