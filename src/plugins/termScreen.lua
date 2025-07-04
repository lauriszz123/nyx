---@class TerminalScreen
local TerminalScreen = {}

function TerminalScreen:initialize()
	self.scale = 4
	self.width = 240
	self.height = 180

	self.currentX = 1
	self.currentY = 1
	self.lines = { "" }

	self.doUpdate = false

	self.canvas = love.graphics.newCanvas(self.width, self.height)
	love.window.setMode(self.width * self.scale, self.height * self.scale)
	self.canvas:setFilter("nearest", "nearest")
	love.graphics.setFont(love.graphics.newFont("src/plugins/pico.ttf", 5))
end

function TerminalScreen:draw()
	if self.doUpdate then
		love.graphics.setCanvas(self.canvas)
		for i, line in ipairs(self.lines) do
			love.graphics.print(line, 0, (i - 1) * 6)
		end
		love.graphics.setCanvas()
	end

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.canvas, 0, 0, 0, self.scale, self.scale)
end

function TerminalScreen:write(addr, value)
	if addr == 0x3000 then
		if value == ("\n"):byte() then
			self.currentY = self.currentY + 1
			self.lines[self.currentY] = ""
			self.currentX = 1
		else
			self.lines[self.currentY] = self.lines[self.currentY] .. string.char(value)
			self.currentX = self.currentX + 1
		end
		self.doUpdate = true
	end
end

function TerminalScreen:read(addr) end

return TerminalScreen
