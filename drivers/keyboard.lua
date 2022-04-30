local Keyboard = {}

function Keyboard:EnsureStorage()
    DriverStore.keyboard.keysPressed = DriverStore.keyboard.keysPressed or {}
    DriverStore.keyboard.listeners = DriverStore.keyboard.listeners or {}
end

function Keyboard:ProcessSignal(signal)
    Keyboard:EnsureStorage()

    if signal[1] == "key_down" then
        local code = signal[4]

        DriverStore.keyboard.keysPressed[code] = true
        local listeners = DriverStore.keyboard.listeners
        for _, l in ipairs(listeners) do
            l(code, true)
        end
    elseif signal[1] == "key_up" then
        local code = signal[4]

        DriverStore.keyboard.keysPressed[code] = false
        local listeners = DriverStore.keyboard.listeners
        for _, l in ipairs(listeners) do
            l(code, false)
        end
    end
end

function Keyboard:AddListener(listener)
    Keyboard:EnsureStorage()
    table.insert(DriverStore.keyboard.listeners, listener)
end

function Keyboard:IsDown(code)
    Keyboard:EnsureStorage()
    return (DriverStore.keyboard.keysPressed[code] == true)
end

function Keyboard:IsUp(code)
    Keyboard:EnsureStorage()
    return (DriverStore.keyboard.keysPressed[code] ~= true)
end

return Keyboard