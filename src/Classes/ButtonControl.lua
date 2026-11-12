-- Path of Building
--
-- Class: Button Control
-- Basic button control.
--
---@class ButtonControl: Control, TooltipHost
local unpack = unpack

local ThemeFluent = LoadModule("Modules/ThemeFluent")

local ButtonClass = newClass("ButtonControl", "Control", "TooltipHost")

function ButtonClass:ButtonControl(anchor, rect, label, onClick, onHover, forceTooltip)
	self:Control(anchor, rect)
	self:TooltipHost()
	self.label = label
	self.onClick = onClick
	self.onHover = onHover
	self.forceTooltip = forceTooltip
	return self
end

function ButtonClass:Click()
	if self:IsShown() and self:IsEnabled() then
		self.onClick()
	end
end

function ButtonClass:SetImage(path)
	if path then
		self.image = NewImageHandle()
		self.image:Load(path)
	else
		self.image = nil
	end
end

function ButtonClass:IsMouseOver()
	if not self:IsShown() then
		return false
	end
	return self:IsMouseInBounds()
end

function ButtonClass:Draw(viewPort, noTooltip)
	local x, y = self:GetPos()
	local width, height = self:GetSize()
	local enabled = self:IsEnabled()
	local mOver = self:IsMouseOver()
	local locked = self:GetProperty("locked")
	local textCol
	if DrawControlBox then
		-- WinUI 3 Fluent style: rounded button with a border and a soft shadow
		local tokens = ThemeFluent.button
		local bg, border
		if not enabled then
			bg, border = tokens.bgDisabled, tokens.borderDisabled
		elseif self.clicked and mOver then
			bg, border = tokens.bgPressed, tokens.borderPressed
		elseif mOver then
			bg, border = tokens.bgHover, tokens.borderHover
		elseif locked then
			-- Active mode button (e.g. the current view tab): elevated fill with
			-- a Windows 11 segmented-control style accent indicator underneath
			bg, border = tokens.bgActive, tokens.border
		else
			bg, border = tokens.bg, tokens.border
		end
		DrawControlBox(x, y, width, height, tokens.radius, bg, border, tokens.borderWidth, tokens.shadowBlur)
		if enabled and locked then
			SetDrawColor(unpack(tokens.indicator))
			DrawImage(nil, x + tokens.indicatorInset, y + height - tokens.indicatorHeight - 1, width - tokens.indicatorInset * 2, tokens.indicatorHeight)
		end
		textCol = enabled and tokens.text or tokens.textDisabled
	else
		-- Legacy SimpleGraphic rendering (runtime without DrawControlBox)
		if not enabled then
			SetDrawColor(0.33, 0.33, 0.33)
		elseif mOver or locked then
			SetDrawColor(1, 1, 1)
		else
			SetDrawColor(0.5, 0.5, 0.5)
		end
		DrawImage(nil, x, y, width, height)
		if not enabled then
			SetDrawColor(0, 0, 0)
		elseif self.clicked and mOver then
			SetDrawColor(0.5, 0.5, 0.5)
		elseif mOver or locked then
			SetDrawColor(0.33, 0.33, 0.33)
		else
			SetDrawColor(0, 0, 0)
		end
		DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
		textCol = enabled and { 1, 1, 1, 1 } or { 0.33, 0.33, 0.33, 1 }
	end
	if self.image then
		if enabled then
			SetDrawColor(1, 1, 1)
		else
			SetDrawColor(0.33, 0.33, 0.33)
		end
		DrawImage(self.image, x + 2, y + 2, width - 4, height - 4)
		if self.clicked and mOver then
			SetDrawColor(1, 1, 1, 0.5)
			DrawImage(nil, x + 1, y + 1, width - 2, height - 2)
		end
	end
	-- Restore the label color (the image block above changes the draw color)
	SetDrawColor(unpack(textCol))
	local label = self:GetProperty("label")
	if label == "+" then
		DrawImage(nil, x + width * 0.2, y + height * 0.45, width * 0.6, height * 0.1)
		DrawImage(nil, x + width * 0.45, y + height * 0.2, width * 0.1, height * 0.6)
	elseif label == "-" then
		DrawImage(nil, x + width * 0.2, y + height * 0.45, width * 0.6, height * 0.1)
	elseif label == "x" then
		DrawImageQuad(nil, x + width * 0.2, y + height * 0.3, x + width * 0.3, y + height * 0.2, x + width * 0.8, y + height * 0.7, x + width * 0.7, y + height * 0.8)
		DrawImageQuad(nil, x + width * 0.7, y + height * 0.2, x + width * 0.8, y + height * 0.3, x + width * 0.3, y + height * 0.8, x + width * 0.2, y + height * 0.7)
	else
		local overSize = self.overSizeText or 0
		local fontSize = height - 4 + overSize * 2
		local maxW = width - 6
		if maxW > 8 and DrawStringWidth then
			local textW = DrawStringWidth(fontSize, "VAR", label)
			while textW > maxW and fontSize > 9 do
				fontSize = fontSize - 1
				textW = DrawStringWidth(fontSize, "VAR", label)
			end
		end
		local textY = y + math.floor((height - fontSize) / 2)
		DrawString(x + width / 2, textY, "CENTER_X", fontSize, "VAR", label)
	end
	if mOver then
		if not noTooltip or self.forceTooltip then
			SetDrawLayer(nil, 100)
			self:DrawTooltip(x, y, width, height, viewPort)
			SetDrawLayer(nil, 0)
		end
		if self.onHover ~= nil then
			return self.onHover()
		end
	end
end

function ButtonClass:OnKeyDown(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" then
		self.clicked = true
	elseif self.enterFunc then
		self.enterFunc()
	end
	return self
end

function ButtonClass:OnKeyUp(key)
	if not self:IsShown() or not self:IsEnabled() then
		return
	end
	if key == "LEFTBUTTON" and self.clicked then
		self.clicked = false
		if self:IsMouseOver() then
			return self.onClick()
		end
	end
	self.clicked = false
end
