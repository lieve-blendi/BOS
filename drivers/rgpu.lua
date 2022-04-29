local RGPU = {}

RGPU.gpu = Components.gpu
RGPU.version = "0.1"

function RGPU:line(x, y, dx, dy, length, char)
    for i=1,l do
        x = x + dx
        y = y + dy

        self.gpu.set(math.floor(x), math.floor(y), char)
    end
end

function RGPU:pixel(color, character, isPallete)
    return {
        co = color,
        ca = character,
        p = isPallete,
    }
end

function RGPU:drawWithShader(x, y, width, height, shaderFunc)
    local ex = x + width - 1
    local ey = y + height - 1

    for i=x,ex do
        for j=y,ey do
            local pixel = shaderFunc(i-x, j-y) -- Get pixel from shader
            if type(pixel) == "table" then
                -- If we got a pixel, display it
                local oldColor, isPallete = self.gpu.getForeground()

                self.gpu.setForeground(pixel.co, pixel.p)
                self.gpu.set(i, j, pixel.ca)

                self.gpu.setForeground(oldColor, isPallete)
            end
        end
    end
end

function RGPU:clear()
    local width, height = self.gpu.getResolution()

    self.gpu.fill(0, 0, width, height)
end

function RGPU:drawWithInstructions(x, y, instructions)
    for _, ins in ipairs(instructions) do
        if ins.type == "rect" then
            local oldColor, isPallete = self.gpu.getForeground()

            self.gpu.setForeground(ins.pixel.co, ins.pixel.p)
            self.gpu.fill(ins.x, ins.y, ins.w, ins.h, ins.pixel.ca)

            self.gpu.setForeground(oldColor, isPallete)
        elseif ins.type == "copy" then
            self.gpu.copy(ins.x, ins.y, ins.w, ins.h, ins.dx, ins.dy)
        elseif ins.type == "shader" then
            RGPU:drawWithShader(ins.x, ins.y, ins.w, ins.h, ins.shader)
        elseif ins.type == "text" then
            local x = ins.x
            local y = ins.y
            local text = ins.text

            for i=1,#text do
                self.gpu.set(x + i - 1, y, text:sub(i, i))
            end
        elseif ins.type == "image" then
            -- Image not yet implemented
        end
    end
end

return RGPU