local Keyboard = {}

function Keyboard:ProcessSignal(signal)
    if signal[1] == "key_down" then
        local code = signal[4]

        DriverStore["keyboard"]["code"] = true
    elseif signal[1] == "key_up" then
        local code = signal[4]

        DriverStore["keyboard"]["code"] = false
    end
end

function Keyboard:IsDown()
    return (DriverStore["keyboard"]["code"] == true)
end

function Keyboard:IsUp()
    return (DriverStore["keyboard"]["code"] ~= true)
end

return Keyboard