local Window = {}

Window.RGPU = Drivers.rgpu -- Driver that needs driver LMAO
Window.windows = {}
Window.lastX = 0
Window.lastY = 0

function Window:clear()
    self.windows = {}
end

function Window:newWindow(title, x, y, width, height, onSignal, render)
    local win = {
        title = title or "Untitled",
        x = x or 0,
        y = y or 0,
        width = width or 20,
        height = height or 20,
        onSignal = onSignal or function() end,
        render = render or function() end,
    }

    table.insert(self.windows, win)
end

function Window:render()
    for _, win in ipairs(self.windows) do
        local x, y = win.x, win.y
        Window.RGPU.gpu.setBackground(0x000000)
        Window.RGPU.gpu.fill(win.x, win.y-1, win.width, 1, " ")
        Window.RGPU.gpu.setBackground(0xFF0000)
        Window.RGPU.gpu.set(win.x + win.width - 1, win.y-1, " ")
        Window.RGPU.gpu.setBackground(0xFFFFFF)
        Window.RGPU.gpu.fill(win.x, win.y, win.width, win.height, " ")
        win:render()
    end
    Window.RGPU.gpu.setForeground(0xFFFFFF)
    Window.RGPU.gpu.setBackground(0x000000)
end

function Window:processSignal(signal)
    if signal[1] == "touch" then
        local x, y = signal[3], signal[4]

        self.lastX = x
        self.lastY = y

        for _, win in ipairs(self.windows) do
            if y == win.y-1 and (x >= win.x) and (x < win.x + win.width) then
                win.selected = true
                return
            elseif y == win.y-1 and (x == win.x + win.width) then
                win.kill = true
                return
            end
        end
    elseif signal[1] == "drag" then
        local x, y, = signal[3], signal[4]

        local dx, dy = x - self.lastX, y - self.lastY
        self.lastX = x
        self.lastY = y

        for _, win in ipairs(self.windows) do
            if win.selected then
                win.x = win.x + dx
                win.y = win.y + dy
                return
            end
        end
    end

    for _, win in ipairs(self.windows) do
        if win.selected then
            win:onSignal(signal)
        end
    end
end

function Window:kill()
    local indexes = {}
    for i, win in pairs(self.windows) do
        if win.kill then table.insert(self.windows, i) end
    end
end

return Window