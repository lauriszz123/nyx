---@class TerminalScreen
local TerminalScreen = {}

function TerminalScreen:initialize()
	self.scale = 5
	self.currentX = 1
	self.currentY = 1
	love.window.setMode(240 * self.scale, 180 * self.scale)

	self.lines = { "" }
end

function TerminalScreen:draw()
	for i, line in ipairs(self.lines) do
		love.graphics.print(line, 1, (i - 1) * 16)
	end
end

function TerminalScreen:read(addr, value)
	if addr == 0x3000 then
		if value == ("\n"):byte() then
			self.currentY = self.currentY + 1
			self.lines[self.currentY] = ""
		else
			self.lines[self.currentY] = self.lines[self.currentY] .. string.char(value)
		end
	end
end

return TerminalScreen
