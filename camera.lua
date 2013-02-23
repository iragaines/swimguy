-- http://nova-fusion.com/2011/04/19/cameras-in-love2d-part-1-the-basics/

camera = {}
camera.x = 0
camera.y = 0
camera.scaleX = 1
camera.scaleY = 1
camera.rotation = 0

function camera:set()
	love.graphics.push()
	love.graphics.rotate(-self.rotation)
	love.graphics.scale(1 / self.scaleX, 1 / self.scaleY)
	love.graphics.translate(-self.x, -self.y)
end

function camera:unset()
	love.graphics.pop()
end

function camera:move(dx, dy)
	self.x = math.floor(self.x + (dx or 0))
	self.y = math.floor(self.y + (dy or 0))
end

function camera:rotate(dr)
	self.rotation = self.rotation + dr
end

function camera:scale(sx, sy)
	sx = sx or 1
	self.scaleX = self.scaleX * sx
	self.scaleY = self.scaleY * (sy or sx)
end

function camera:setPosition(x, y)
	self.x = math.floor(x or self.x)
	self.y = math.floor(y or self.y)
end

function camera:setScale(sx, sy)
	self.scaleX = sx or self.scaleX
	self.scaleY = sy or self.scaleY
end

function camera:mousePosition()
	return love.mouse.getX() * self.scaleX + self.x, love.mouse.getY() * self.scaleY + self.y
end

function camera:constrain(windowWidth, windowHeight, mapWidth, mapHeight)
	local xMax = mapWidth - windowWidth
	local yMax = mapHeight - windowHeight
	self.x = self.x < 0 and 0 or (self.x > xMax and xMax or self.x)
	self.y = self.y < 0 and 0 or (self.y > yMax and yMax or self.y)
end
