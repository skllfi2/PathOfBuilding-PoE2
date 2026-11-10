-- Path of Building
--
-- Module: Window State
-- Window geometry persistence helpers (position, size, maximised flag).
--
-- The window state lives in the "Misc" element of Settings.xml as the
-- attributes windowX, windowY, windowWidth, windowHeight and windowMaximized.
-- This module owns the pure logic (parsing, validation and clamping) so it
-- can be unit-tested without a window; Main.lua only performs the calls to
-- the SimpleGraphic runtime API.
--
-- Validation rules (guard check):
--   * a missing or malformed value is ignored (the window keeps the position
--     chosen by the runtime);
--   * the size must be positive and is clamped to the available screen;
--   * the position must keep a visible part of the window inside the virtual
--     desktop (the window may not be completely off-screen after a monitor
--     change); an unusable position is replaced by a centred one.
--
-- The runtime API used here:
--   GetWindowPosition()  -> x, y          (screen coordinates)
--   SetWindowPosition(x, y)
--   GetWindowSize()      -> width, height (window coordinates)
--   SetWindowSize(width, height)
--   IsWindowMaximized()  -> boolean
--   SetWindowMaximized(boolean)
--   GetMonitorBounds()   -> left, top, right, bottom (union of all monitors)

local WindowState = { }

-- Minimum visible area (in pixels) that must stay on screen for a restored
-- window position to be considered usable.
local minVisible = 64

local function toNumber(value)
	if value == nil then
		return nil
	end
	local num = tonumber(value)
	if not num or num ~= num then -- rejects NaN
		return nil
	end
	return num
end

-- Reads the window state from a Settings.xml attribute table.
-- @param attrib table|nil attribute table of the "Misc" element
-- @return table|nil state { x, y, width, height, maximised } or nil when
-- nothing usable is stored
function WindowState.Read(attrib)
	if type(attrib) ~= "table" then
		return nil
	end
	local x = toNumber(attrib.windowX)
	local y = toNumber(attrib.windowY)
	local width = toNumber(attrib.windowWidth)
	local height = toNumber(attrib.windowHeight)
	if not x or not y or not width or not height then
		return nil
	end
	if width <= 0 or height <= 0 then
		return nil
	end
	local maximised = attrib.windowMaximized
	if maximised == "true" then
		maximised = true
	elseif maximised == "false" then
		maximised = false
	else
		maximised = (toNumber(maximised) or 0) ~= 0
	end
	return {
		x = math.floor(x),
		y = math.floor(y),
		width = math.floor(width),
		height = math.floor(height),
		maximised = maximised,
	}
end

-- Writes the window state into a Settings.xml attribute table.
-- Existing attributes are preserved (the table is updated in place).
-- @return table attrib the same table
function WindowState.Write(attrib, state)
	if type(attrib) ~= "table" or type(state) ~= "table" then
		return attrib
	end
	attrib.windowX = tostring(state.x or 0)
	attrib.windowY = tostring(state.y or 0)
	attrib.windowWidth = tostring(state.width or 0)
	attrib.windowHeight = tostring(state.height or 0)
	attrib.windowMaximized = state.maximised and "true" or "false"
	return attrib
end

-- Returns the bounds of the virtual desktop as { left, top, right, bottom }.
-- Returns nil when the runtime does not provide the API (older DLL).
function WindowState.GetBounds()
	if type(GetMonitorBounds) ~= "function" then
		return nil
	end
	local left, top, right, bottom = GetMonitorBounds()
	left = toNumber(left)
	top = toNumber(top)
	right = toNumber(right)
	bottom = toNumber(bottom)
	if not left or not top or not right or not bottom then
		return nil
	end
	if right <= left or bottom <= top then
		return nil
	end
	return {
		left = math.floor(left),
		top = math.floor(top),
		right = math.floor(right),
		bottom = math.floor(bottom),
	}
end

-- Checks whether the window rectangle still overlaps the visible screen area.
-- @param state table window state { x, y, width, height }
-- @param bounds table virtual desktop bounds { left, top, right, bottom }
-- @return boolean visible
function WindowState.IsOnScreen(state, bounds)
	if type(state) ~= "table" or type(bounds) ~= "table" then
		return false
	end
	local left = bounds.left or 0
	local top = bounds.top or 0
	local right = bounds.right or 0
	local bottom = bounds.bottom or 0
	if right <= left or bottom <= top then
		return false
	end
	local width = state.width or 0
	local height = state.height or 0
	if width <= 0 or height <= 0 then
		return false
	end
	local stateRight = state.x + width
	local stateBottom = state.y + height
	-- At least `minVisible` pixels of the window must be reachable
	local visibleW = math.min(stateRight, right) - math.max(state.x, left)
	local visibleH = math.min(stateBottom, bottom) - math.max(state.y, top)
	return visibleW >= math.min(minVisible, width) and visibleH >= math.min(minVisible, height)
end

-- Clamps the size to the screen and the position to the visible area.
-- @return table state the state to apply
-- @return boolean corrected true when the stored position had to be fixed
function WindowState.Clamp(state, bounds)
	if type(state) ~= "table" then
		return nil, false
	end
	if type(bounds) ~= "table" then
		return {
			x = state.x or 0,
			y = state.y or 0,
			width = state.width or 0,
			height = state.height or 0,
			maximised = state.maximised and true or false,
		}, false
	end
	local left = bounds.left or 0
	local top = bounds.top or 0
	local right = bounds.right or 0
	local bottom = bounds.bottom or 0
	local screenW = right - left
	local screenH = bottom - top
	if screenW <= 0 or screenH <= 0 then
		return {
			x = state.x or 0,
			y = state.y or 0,
			width = state.width or 0,
			height = state.height or 0,
			maximised = state.maximised and true or false,
		}, false
	end
	local width = math.max(1, math.min(state.width or 1, screenW))
	local height = math.max(1, math.min(state.height or 1, screenH))
	local x = state.x or 0
	local y = state.y or 0
	local corrected = false
	if not WindowState.IsOnScreen({ x = x, y = y, width = width, height = height }, bounds) then
		-- The window would be (almost) completely off-screen: centre it instead
		x = left + math.floor((screenW - width) / 2)
		y = top + math.floor((screenH - height) / 2)
		corrected = true
	else
		-- Keep the window reachable: pull it back into the screen
		local clampedX = math.max(left, math.min(x, right - width))
		local clampedY = math.max(top, math.min(y, bottom - height))
		if clampedX ~= x or clampedY ~= y then
			corrected = true
		end
		x, y = clampedX, clampedY
	end
	return {
		x = x,
		y = y,
		width = width,
		height = height,
		maximised = state.maximised and true or false,
	}, corrected
end

-- Collects the current window state from the runtime API.
-- Returns nil when the runtime does not provide the API (older DLL).
function WindowState.Capture()
	if type(GetWindowPosition) ~= "function" or type(GetWindowSize) ~= "function" then
		return nil
	end
	local x, y = GetWindowPosition()
	local width, height = GetWindowSize()
	local maximised = false
	if type(IsWindowMaximized) == "function" then
		maximised = IsWindowMaximized() and true or false
	end
	x = toNumber(x)
	y = toNumber(y)
	width = toNumber(width)
	height = toNumber(height)
	if not x or not y or not width or not height then
		return nil
	end
	if width <= 0 or height <= 0 then
		return nil
	end
	return {
		x = math.floor(x),
		y = math.floor(y),
		width = math.floor(width),
		height = math.floor(height),
		maximised = maximised,
	}
end

-- Applies a stored window state to the runtime API.
-- @return boolean applied
function WindowState.Apply(state)
	if type(state) ~= "table" then
		return false
	end
	if type(SetWindowSize) ~= "function" or type(SetWindowPosition) ~= "function" then
		return false
	end
	SetWindowSize(state.width, state.height)
	SetWindowPosition(state.x, state.y)
	if state.maximised and type(SetWindowMaximized) == "function" then
		SetWindowMaximized(true)
	end
	return true
end

return WindowState
