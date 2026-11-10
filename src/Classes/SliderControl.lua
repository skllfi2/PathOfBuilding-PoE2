-- Path of Building
--
-- Class: Slider Control
-- Basic slider control.
--
local m_min = math.min
local m_max = math.max
local m_ceil = math.ceil

local ThemeFluent = LoadModule("Modules/ThemeFluent")

---@class SliderControl: Control, TooltipHost
local SliderClass = newClass("SliderControl", "Control", "TooltipHost")

function SliderClass:SliderControl(anchor, rect, changeFunc, scrollWheelSpeedTbl)
	self:Control(anchor, rect)
	self:TooltipHost()
	self.knobSize = self.height - 2
	self.val = 0
	self.changeFunc = changeFunc
	self.scrollWheelSpeedTbl = scrollWheelSpeedTbl or { ["SHIFT"] = 0.25, ["CTRL"] = 0.01, ["DEFAULT"] = 0.05 }
	return self
end

function SliderClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local cursorX, cursorY = GetCursorPos()
	local mOver = cursorX >= x and cursorY >= y and cursorX < x + width and cursorY < y + height
	local mOverComp
	if mOver then
		local relX = cursorX - x - 2
		local knobX = self:GetKnobXForVal()
		if relX >= knobX and relX < knobX + self.knobSize then
			mOverComp = "KNOB"
		else
			mOverComp = "SLIDE"
		end
	end
	return mOver, mOverComp
end

function SliderClass:GetKnobTravel()
	local width, height = self:GetSize()
	return width - self.knobSize - 2
end

function SliderClass:SetVal(newVal)
	newVal = m_max(0, m_min(1, newVal))
	if newVal ~= self.val then
		self.val = newVal
		if self.changeFunc then
			self.changeFunc(self.val)
		end
	end
end

function SliderClass:GetDivVal(val)
	val = val or self.val
	if self.divCount and self.divCount > 1 then
		local divIndex = m_max(m_ceil(val * self.divCount), 1)
		return divIndex, val * self.divCount - divIndex + 1
	else
		return 1, val
	end
end

function SliderClass:SetValFromKnobX(knobX)
	self:SetVal(knobX / self:GetKnobTravel())
end

function SliderClass:GetKnobXForVal()
	local knobTravel = self:GetKnobTravel()
	return knobTravel * self.val
end

function SliderClass:Draw(viewPort)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local enabled = self:IsEnabled()
	local knobTravel = self:GetKnobTravel()
	if self.dragging and not IsKeyDown("LEFTBUTTON") then
		self.dragging = false
	end
	if self.dragging then
		local cursorX, cursorY = GetCursorPos()
		self:SetValFromKnobX((cursorX - self.dragCX) + self.dragKnobX)
	end
	local mOver, mOverComp = self:IsMouseOver()
	local knobX = self:GetKnobXForVal()
	if DrawControlBox then
		-- Fluent: thin dark track, accent fill up to the knob, light round knob
		local tokens = ThemeFluent.slider
		if not enabled then
			DrawControlBox(x, y, width, height, tokens.radius, tokens.trackDisabledBg, tokens.trackDisabledBorder, tokens.borderWidth, tokens.shadowBlur)
		else
			DrawControlBox(x, y, width, height, tokens.radius, tokens.trackBg, (self.dragging or mOver) and tokens.trackBorderHover or tokens.trackBorder, tokens.borderWidth, tokens.shadowBlur)
			local fillWidth = m_min(knobX + self.knobSize / 2, width - 2)
			if fillWidth > 0 then
				DrawControlBox(x + 1, y + 1, fillWidth, height - 2, tokens.radius, tokens.trackFill, nil, 0, 0)
			end
		end
	else
		if not enabled then
			SetDrawColor(0.33, 0.33, 0.33)
		elseif self.dragging or mOver then
			SetDrawColor(1, 1, 1)
		else
			SetDrawColor(0.5, 0.5, 0.5)
		end
		DrawImage(nil, x, y, width, height)
		SetDrawColor(0, 0, 0)
		DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
	end
	if enabled then
		if self.divCount then
			if DrawControlBox then
				SetDrawColor(unpack(ThemeFluent.slider.tick))
			else
				SetDrawColor(0.33, 0.33, 0.33)
			end
			for d = 0, knobTravel + 0.5, knobTravel / self.divCount do
				DrawImage(nil, x + self.knobSize/2 + d, y + 1, 2, height - 2)
			end
		end
		if self.divCount then
			local arrowHeight = self.knobSize/2
			local arrowColor
			if DrawControlBox then
				local tokens = ThemeFluent.slider
				arrowColor = (self.dragging or mOverComp == "KNOB") and tokens.arrowActive or tokens.arrow
			else
				arrowColor = (self.dragging or mOverComp == "KNOB") and { 1, 1, 1 } or { 0.5, 0.5, 0.5 }
			end
			SetDrawColor(unpack(arrowColor))
			main:DrawArrow(x + 1 + knobX + self.knobSize/2, y + height/2 - arrowHeight/2, self.knobSize, arrowHeight, "UP")
			main:DrawArrow(x + 1 + knobX + self.knobSize/2, y + height/2 + arrowHeight/2, self.knobSize, arrowHeight, "DOWN")
		elseif DrawControlBox then
			local tokens = ThemeFluent.slider
			DrawControlBox(x + 2 + knobX, y + 2, self.knobSize - 2, self.knobSize - 2, m_min(16, (self.knobSize - 2) / 2), tokens.knob, (self.dragging or mOverComp == "KNOB") and tokens.knobBorderActive or tokens.knobBorder, 1, 0)
		else
			if self.dragging or mOverComp == "KNOB" then
				SetDrawColor(1, 1, 1)
			else
				SetDrawColor(0.5, 0.5, 0.5)
			end
			DrawImage(nil, x + 2 + knobX, y + 2, self.knobSize - 2, self.knobSize - 2)
		end
	end
	if enabled and (mOver or self.dragging) then
		SetDrawLayer(nil, 100)
		if self.dragging then
			self:DrawTooltip(x, y, width, height, viewPort, self.val)
		else
			local cursorX, cursorY = GetCursorPos()
			local val = (cursorX - x - 1 - self.knobSize / 2) / knobTravel
			self:DrawTooltip(x, y, width, height, viewPort, m_max(0, m_min(1, val)))
		end
		SetDrawLayer(nil, 0)
	end
end

function SliderClass:OnKeyDown(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" then
		local mOver, mOverComp = self:IsMouseOver()
		if not mOver then
			return
		end
		if not self.dragging then
			self.dragging = true
			local cursorX, cursorY = GetCursorPos()
			self.dragCX = cursorX
			if mOverComp == "SLIDE" then
				local x, y = self:GetPos()
				self:SetValFromKnobX(cursorX - x - 1 - self.knobSize / 2)
			end	
			self.dragKnobX = self:GetKnobXForVal()
		end
	end
	return self
end

function SliderClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" then
		if self.dragging then
			self.dragging = false
			local cursorX, cursorY = GetCursorPos()
			self:SetValFromKnobX((cursorX - self.dragCX) + self.dragKnobX)
		end
	elseif (not main.invertSliderScrollDirection and key == "WHEELDOWN") or (main.invertSliderScrollDirection and  key == "WHEELUP") or key == "DOWN" or key == "LEFT" then
		if IsKeyDown("SHIFT") then
			self:SetVal(self.val - self.scrollWheelSpeedTbl["SHIFT"])
		elseif IsKeyDown("CTRL") then
			self:SetVal(self.val - self.scrollWheelSpeedTbl["CTRL"])
		else
			self:SetVal(self.val - self.scrollWheelSpeedTbl["DEFAULT"])
		end
	elseif (not main.invertSliderScrollDirection and key == "WHEELUP") or (main.invertSliderScrollDirection and key == "WHEELDOWN") or key == "UP" or key == "RIGHT" then
		if IsKeyDown("SHIFT") then
			self:SetVal(self.val + self.scrollWheelSpeedTbl["SHIFT"])
		elseif IsKeyDown("CTRL") then
			self:SetVal(self.val + self.scrollWheelSpeedTbl["CTRL"])
		else
			self:SetVal(self.val + self.scrollWheelSpeedTbl["DEFAULT"])
		end
	end
end
