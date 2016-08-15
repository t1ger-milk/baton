local flene = {}



local sourceFunction = {}

function sourceFunction.key(k)
  return function()
    return love.keyboard.isDown(k) and 1 or 0
  end
end

function sourceFunction.sc(sc)
  return function()
    return love.keyboard.isScancodeDown(sc) and 1 or 0
  end
end

function sourceFunction.gpaxis(value)
  local axis, direction = value:match '(.+)%s*([%+%-])'
  if direction == '+' then direction = 1 end
  if direction == '-' then direction = -1 end
  return function(self)
    if self.joystick then
      local v = self.joystick:getGamepadAxis(axis)
      v = v * direction
      if v > self.deadzone then
        return v
      end
    end
    return 0
  end
end

function sourceFunction.gpbutton(button)
  return function(self)
    if self.joystick then
      return self.joystick:isGamepadDown(button) and 1 or 0
    end
    return 0
  end
end

function sourceFunction.joyaxis(value)
  local axis, direction = value:match '(.+)%s*([%+%-])'
  if direction == '+' then direction = 1 end
  if direction == '-' then direction = -1 end
  return function(self)
    if self.joystick then
      local v = self.joystick:getAxis(tonumber(axis))
      v = v * direction
      if v > self.deadzone then
        return v
      end
    end
    return 0
  end
end

function sourceFunction.joybutton(button)
  return function(self)
    if self.joystick then
      return self.joystick:isDown(tonumber(button)) and 1 or 0
    end
    return 0
  end
end



local Player = {}

function Player:_addControl(name, sources)
  self.controls[name] = {
    value = 0,
    downCurrent = false,
    downPrevious = false,
  }
  self:_setSources(name, sources)
end

function Player:_setSources(controlName, sources)
  self.controls[controlName].sources = {}
  for i = 1, #sources do
    local type, value = sources[i]:match '(.+)%s*:%s*(.+)'
    table.insert(self.controls[controlName].sources,
      sourceFunction[type](value))
  end
end

function Player:setControls(controls)
  for name, sources in pairs(controls) do
    if self.controls[name] then
      self:_setSources(name, sources)
    else
      self:_addControl(name, sources)
    end
  end
end

function Player:update()
  for _, control in pairs(self.controls) do
    control.value = 0
    for i = 1, #control.sources do
      control.value = control.value + control.sources[i](self)
    end
    if control.value > 1 then control.value = 1 end

    control.downPrevious = control.downCurrent
    control.downCurrent = control.value > self.deadzone
  end
end

function Player:get(control)
  return self.controls[control].value
end
function Player:down(control)
  return self.controls[control].downCurrent
end
function Player:pressed(control)
  local c = self.controls[control]
  return c.downCurrent and not c.downPrevious
end
function Player:released(control)
  local c = self.controls[control]
  return c.downPrevious and not c.downCurrent
end

function flene.newPlayer(controls, joystick)
  local player = setmetatable({
    controls = {},
    joystick = joystick,
    deadzone = .5,
  }, {__index = Player})
  player:setControls(controls)
  return player
end



return flene
