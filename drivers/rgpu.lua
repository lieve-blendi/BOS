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
                RGPU:setPixel(pixel)
            end
        end
    end
end

function RGPU:clear()
    local width, height = self.gpu.getResolution()

    self.gpu.fill(1, 1, width, height, " ")
end

RGPU.image = {}
function RGPU.image:new(width, height)
    local pixelData = {}

    for i=1,width*height do
        table.insert(pixelData, RGPU:pixel(0x000000, " ", false))
    end

    return {
        pixelData = pixelData,
        width = width,
        height = height,
        set = function(self, x, y, pixel)
            RGPU.image:set(self, x, y, pixel)
        end,
    }
end

function RGPU.image:set(image, x, y, pixel)
    local i = (x + y * width) + 1

    image.pixelData[i] = pixel
end

function RGPU:setPixel(x, y, pixel)
    self.gpu.setForeground(pixel.co, pixel.p)
    self.gpu.set(i, j, pixel.ca)
end

function RGPU.image:get(image, x, y, pixel)
    local i = (x + y * width) + 1

    return image.pixelData[i]
end

function RGPU:renderImage(image, ix, iy, hideEmptyBlack)
    for x=0,imageData.width-1 do
        for y=0,imageData.height-1 do
            local i = (x + y * width) + 1
            local p = image.pixelData[i]
            if not hideEmptyBlack then
                setPixel(ix + x, iy + y, p)
            else
                if ((p.isPallete) or (p.color ~= 0x000000)) then
                    setPixel(ix + x, iy + y, p)
                end
            end
        end
    end
end

function RGPU:drawWithInstructions(instructions)
    for _, ins in ipairs(instructions) do
        if ins.type == "rect" then
            self.gpu.setBackground(ins.pixel.co, ins.pixel.p)
            self.gpu.fill(ins.x, ins.y, ins.w, ins.h, ins.pixel.ca)
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