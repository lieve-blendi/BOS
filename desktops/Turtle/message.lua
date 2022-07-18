local Message = {}

Message.modem = Components.modem

Message.PrintStack = {}
Message.OldPrintStack = {}
Message.gpu = Drivers.rgpu.gpu
Message.RGPU = Drivers.rgpu
Message.Input = ""
Message.OldInput = nil
Message.Keyboard = Drivers.keyboard
Message.Symbols = Drivers.symbols
Message.Singleize = Drivers.singleize
Message.Text = Drivers.text
Message.Keys = Drivers.keys

Message.print = function(...)
    local w,h = Message.gpu.getResolution()
    local prints = {...}
    for k,v in ipairs(prints) do
        Message.PrintStack[#Message.PrintStack + 1] = v
    end
    while #Message.PrintStack >= h do
        table.remove(Message.PrintStack, 1)
    end
    Message.OldInput = nil
end

Message.Keyboard:AddListener(function(key,down,player)
    if DE.CurrentProgram == "Message" and down then
        key = Message.Keys[key]
        if key == "enter" then
            if #Message.Input > 0 then
                if Message.Input == "exit" then
                    DE.CurrentProgram = "Shell"
                    if Message.modem.isOpen(42069) then
                        Message.modem.close(42069)
                    end
                    Message.Input = ""
                    Message.gpu.setBackground(0x000000)
                    Message.gpu.setForeground(0xc9c9c9)
                    Message.RGPU:clear()
                else
                    Message.print("> " .. Message.Input)
                    Message.modem.broadcast(42069, player .. "> " .. Message.Input)
                    Message.Input = ""
                end
            end
        elseif key == "back" then
            Message.Input = string.sub(Message.Input, 1, #Message.Input - 1)
        elseif key == "space" then
            Message.Input = Message.Input .. " "
        elseif type(key) == "string" and #key == 1 then
            local kkey = key
            if Message.Singleize.Singleize(key) then
                kkey = Message.Singleize.Singleize(key)
            end
            if type(kkey) == "string" and #kkey == 1 then
                if Message.Keyboard:IsDown(Message.Keys["lshift"]) then
                    if Message.Symbols[kkey] then
                        kkey = Message.Symbols[kkey]
                    else
                        kkey = string.upper(kkey)
                    end
                end
                Message.Input = Message.Input .. kkey
            end
        end
    end
end)

local function tablecopy(table)
    local new = {}
    for i,v in ipairs(table) do
        new[i] = v
    end
    return new
end

function Message:load()
    self.gpu.setBackground(0x000000)
    self.gpu.setForeground(0xc9c9c9)
    self.RGPU:clear()
    if not self.modem.isOpen(42069) then
        self.modem.open(42069)
    end
end

function Message:ProcessSignal(signal)
    Message.Keyboard:ProcessSignal(signal)
    if signal[1] == "modem_message" then
        if signal[4] == 42069 then
            Message.print(signal[6])
        end
    end
end

function Message:Render()
    local w,h = self.gpu.getResolution()
    for k,v in ipairs(self.PrintStack) do
        if self.OldPrintStack ~= self.PrintStack then
            self.gpu.set(1,k,v)
            if (#v < w) and (#v < #(self.OldPrintStack[k] or "")) then
                self.gpu.fill(#v+1, k, w, k, " ")
            end
            self.OldPrintStack = tablecopy(self.PrintStack)
        end
    end
    if self.OldInput ~= self.Input then
        self.gpu.set(1,#self.PrintStack+1,"> " .. self.Input)
        if (#self.Input+2 < w) and (#self.Input+2 < #(self.OldInput or "")+2) then
            self.gpu.fill(#self.Input+3, #self.PrintStack+1, w, #self.PrintStack+1, " ")
        end
        self.OldInput = self.Input
    end
end

function Message:Init()
    SH:bindCommand("msg", function()
        Message:load()
        DE.CurrentProgram = "Message"
    end)
end

return Message