-- Path of Building
--
-- Module: Fluent Theme
-- WinUI 3 Fluent design tokens for PoB2 controls, in two palettes:
-- "Dark" (Windows 11 Dark) and "Light" (Windows 11 Light).
--
-- Colors are stored as { r, g, b, a } tables in the 0..1 range so they can be
-- passed straight to DrawControlBox(bgColor, borderColor) or applied with
-- SetDrawColor(unpack(color)).
--
-- The tokens are only consumed when the loaded SimpleGraphic runtime provides
-- the DrawControlBox primitive; otherwise the controls keep their legacy
-- DrawImage rendering for backward compatibility.
--
-- SetTheme("Dark" | "Light") swaps the active palette, re-resolves every
-- component token and keeps the system window chrome in sync via
-- SetWindowDarkMode (Windows 11 DWM integration).
--
-- SetAccent(name) swaps the accent palette (see `accents` below: PoE2 Gold,
-- Fluent Blue, Crimson, Emerald) and re-derives the accent tokens on both
-- palettes; the settings field is persisted by Main.lua ("uiAccent").
--
-- The runtime's LoadModule executes this file for every consumer with no
-- caching, so each control class would otherwise hold its own theme state.
-- To keep every consumer consistent the mutable state (palettes, active
-- theme/accent, resolved component tokens) lives in the shared table
-- _G.__THEME_FLUENT_SHARED__; every returned instance is a write-through
-- view onto that state.
--
local m_max = math.max
local m_min = math.min

-- Parse a "#RRGGBB" hex string into a { r, g, b, a } color table.
local function hex(value, alpha)
	return {
		tonumber(value:sub(2, 3), 16) / 255,
		tonumber(value:sub(4, 5), 16) / 255,
		tonumber(value:sub(6, 7), 16) / 255,
		alpha or 1,
	}
end

-- Blend a color toward white (t > 0) or black (t < 0) by a -1..1 amount.
local function shade(color, t)
	local target = t > 0 and 1 or 0
	local k = m_min(m_max(math.abs(t), 0), 1)
	return {
		color[1] + (target - color[1]) * k,
		color[2] + (target - color[2]) * k,
		color[3] + (target - color[3]) * k,
		color[4],
	}
end

-- ================
-- Accent palettes
-- ================
-- Dark value = base hex from the palette spec; Light value = darkened for
-- readable contrast on light surfaces. "PoE2 Gold" keeps the shipped legacy
-- values byte-exact (regression guard), other accents use shade(base, -0.30).
local accents = {
	["PoE2 Gold"] = {
		dark = hex("#D4AF37"),
		light = hex("#9E7D1E"),
		-- Contrast check mark over the accent fill
		checkDark = hex("#1F1F21"),
		checkLight = hex("#FFFFFF"),
	},
	["Fluent Blue"] = {
		dark = hex("#0078D4"),
		light = shade(hex("#0078D4"), -0.30),
		checkDark = hex("#FFFFFF"),
		checkLight = hex("#FFFFFF"),
	},
	["Crimson"] = {
		dark = hex("#D13438"),
		light = shade(hex("#D13438"), -0.30),
		checkDark = hex("#FFFFFF"),
		checkLight = hex("#FFFFFF"),
	},
	["Emerald"] = {
		dark = hex("#107C41"),
		light = shade(hex("#107C41"), -0.30),
		checkDark = hex("#FFFFFF"),
		checkLight = hex("#FFFFFF"),
	},
}
local defaultAccent = "PoE2 Gold"

-- ================
-- Named palettes
-- ================
local palettes = {
	Dark = {
		-- Windows 11 Dark backgrounds
		background = hex("#1F1F21"), -- window base / input fill
		surface = hex("#292B30"), -- cards and control fill
		surfaceHover = shade(hex("#292B30"), 0.08),
		surfacePressed = shade(hex("#292B30"), -0.12),

		-- Subtle strokes (Fluent control borders)
		stroke = hex("#FFFFFF", 0.08),
		strokeSoft = hex("#FFFFFF", 0.05), -- softened card / section frames
		strokeHover = hex("#FFFFFF", 0.25),
		strokeDisabled = hex("#FFFFFF", 0.05),

		-- Opaque hairline edges (panel borders, separators)
		border = hex("#3E4046"),

		-- PoE2 accent gold
		accent = hex("#D4AF37"),
		accentHover = shade(hex("#D4AF37"), 0.08),
		accentPressed = shade(hex("#D4AF37"), -0.12),
		accentDisabled = hex("#D4AF37", 0.25),

		-- Text
		textPrimary = hex("#FFFFFF"),
		textSecondary = hex("#FFFFFF", 0.6),
		textDisabled = hex("#FFFFFF", 0.35),

		-- Component-level palette details
		check = hex("#1F1F21"), -- check mark on the gold fill
		scrollThumb = hex("#FFFFFF", 0.35),
		scrollThumbHover = hex("#FFFFFF", 0.55),
		scrollThumbDrag = hex("#FFFFFF", 0.65),
		veil = hex("#FFFFFF", 0.08), -- hover veil over data-driven tints
		cellSelected = hex("#D4AF37", 0.22), -- pinned calc stat veil
		overlay = hex("#292B30", 0.97), -- floating overlay pane fill
	},
	Light = {
		-- Windows 11 Light backgrounds
		background = hex("#F3F3F3"), -- window base / input fill
		surface = hex("#FFFFFF"), -- cards and control fill
		surfaceHover = shade(hex("#FFFFFF"), -0.04),
		surfacePressed = shade(hex("#FFFFFF"), -0.10),

		-- Subtle strokes (Fluent control borders)
		stroke = hex("#000000", 0.10),
		strokeSoft = hex("#000000", 0.07), -- softened card / section frames
		strokeHover = hex("#000000", 0.22),
		strokeDisabled = hex("#000000", 0.05),

		-- Opaque hairline edges (panel borders, separators)
		border = hex("#E5E5E5"),

		-- PoE2 accent gold, darkened for light backgrounds
		accent = hex("#9E7D1E"),
		accentHover = shade(hex("#9E7D1E"), 0.10),
		accentPressed = shade(hex("#9E7D1E"), -0.10),
		accentDisabled = hex("#9E7D1E", 0.35),

		-- Text
		textPrimary = hex("#1B1B1B"),
		textSecondary = hex("#5C5C5C"),
		textDisabled = hex("#1B1B1B", 0.35),

		-- Component-level palette details
		check = hex("#FFFFFF"), -- light check mark on the darker gold fill
		scrollThumb = hex("#000000", 0.25),
		scrollThumbHover = hex("#000000", 0.40),
		scrollThumbDrag = hex("#000000", 0.50),
		veil = hex("#000000", 0.05), -- hover veil over data-driven tints
		cellSelected = hex("#9E7D1E", 0.18), -- pinned calc stat veil
		overlay = hex("#FFFFFF", 0.97), -- floating overlay pane fill
	},
}

local Theme = {
	-- ===========
	-- Active theme
	-- ===========
	themeName = "Dark",
	accents = accents,
	accentName = defaultAccent,
	colors = palettes.Dark,

	-- =================
	-- Shape and shadows
	-- =================
	radius = {
		control = 4, -- buttons, inputs, checkboxes
		checkbox = 3, -- check boxes (smaller, Windows 11 style)
		scrollThumb = 3, -- scrollbar thumb plate
		popup = 6, -- drop-down lists
		card = 8, -- cards, popups
		tooltip = 8, -- tooltips
	},
	shadow = {
		small = 3, -- resting buttons, inputs
		medium = 6, -- cards, drop-down popups
		large = 10, -- modal dialogs, tooltips
	},

	-- =================
	-- Component tokens
	-- =================
	button = {
		radius = 4, -- radius.control
		borderWidth = 1,
		shadowBlur = 3, -- shadow.small
		bg = nil, -- resolved below
		bgHover = nil,
		bgPressed = nil,
		bgDisabled = nil,
		bgActive = nil, -- elevated fill of the active (locked) mode button
		border = nil,
		borderHover = nil, -- accent gold on hover
		borderPressed = nil,
		borderDisabled = nil,
		indicator = nil, -- accent bar marking the active mode button
		indicatorHeight = 3,
		indicatorInset = 3, -- keep the bar clear of the rounded corners
		text = nil,
		textDisabled = nil,
	},
	edit = {
		radius = 4, -- radius.control
		borderWidth = 1,
		shadowBlur = 0, -- inputs carry no shadow in Fluent
		bg = nil, -- dark input fill
		bgDisabled = nil,
		border = nil,
		borderHover = nil,
		borderFocus = nil, -- accent gold focus ring
		borderDisabled = nil,
	},
	checkbox = {
		radius = 3, -- radius.checkbox
		borderWidth = 1,
		shadowBlur = 0,
		bgChecked = nil, -- accent gold fill when checked
		bgCheckedHover = nil,
		bgCheckedPressed = nil,
		bgUnchecked = nil, -- dark input fill when unchecked
		bgDisabled = nil,
		border = nil,
		borderHover = nil,
		borderDisabled = nil,
		check = nil, -- contrast check mark on the gold fill
	},
	dropdown = {
		radius = 4, -- radius.control (body)
		borderWidth = 1,
		shadowBlur = 0, -- the body carries no shadow
		bg = nil,
		bgDisabled = nil,
		border = nil,
		borderHover = nil,
		borderOpen = nil, -- accent gold while the list is dropped
		borderDisabled = nil,
		popup = { -- the dropped list card
			radius = 6, -- radius.popup
			borderWidth = 1,
			shadowBlur = 6, -- shadow.medium
			bg = nil,
			border = nil,
		},
		itemHoverBg = nil, -- rounded hover highlight of a list row
		itemHoverRadius = 4, -- radius.control
	},
	scrollbar = {
		radius = 3, -- radius.scrollThumb (Windows 11 thumb plate)
		borderWidth = 0,
		shadowBlur = 0,
		thumb = nil,
		thumbHover = nil,
		thumbDrag = nil,
	},
	list = {
		radius = 4, -- radius.control (list panel)
		borderWidth = 1,
		shadowBlur = 0,
		bg = nil, -- list body fill
		border = nil, -- hairline panel border
		borderFocus = nil, -- accent border while the list has focus
		rowRadius = 4, -- hover / selection row highlight (WinUI list rows)
		rowHoverBg = nil, -- rounded hover highlight
		rowSelectedBg = nil, -- selected row fill (list has focus)
		rowSelectedBgUnfocused = nil, -- selected row fill (list not focused)
		rowIndicator = nil, -- accent bar on the left edge of the selected row
		rowIndicatorWidth = 3,
		rowSeparator = nil, -- hairline between rows (showRowSeparators)
		dragTargetBg = { 0, 0.05, 0, 1 }, -- legacy drag-target feedback (kept verbatim)
		dragTargetBorder = { 0.2, 0.6, 0.2, 1 },
	},
	section = {
		radius = 4, -- radius.control (owner decision: dense sidebar layout)
		borderWidth = 1,
		shadowBlur = 0, -- sections sit flush against each other, no shadow
		bg = nil, -- card fill, matches the sidebar so the label notch blends in
		border = nil,
		labelBg = nil, -- plate that hides the border under the label ("legend")
		labelText = nil,
	},
	calcSection = {
		radius = 4, -- radius.control (matches SectionControl)
		borderWidth = 1,
		shadowBlur = 0, -- sections stack vertically, no shadow
		bg = nil, -- card fill
		border = nil, -- subtle stroke frame (group colour stays on the inner lines)
		cellRadius = 3, -- hover / pinned cell highlight
		cellHoverBg = nil, -- veil over the data-driven bgCol tint
		cellSelectedBg = nil, -- pinned stat: gold veil
		cellIndicator = nil, -- accent bar on a pinned cell
		cellIndicatorWidth = 3,
		overlayRadius = 6, -- floating overlay pane (popup-level card)
		overlayShadow = 6, -- shadow.medium
		overlayBg = nil, -- translucent surface
		overlayBorder = nil,
		overlayBorderDrag = nil, -- accent while the pane is being dragged
		overlayHeaderBg = nil, -- elevated header strip
		overlaySeparator = nil, -- hairline under the header
		-- Variant A: damage-type column zoning for 6-column damage tables
		-- (literal values on purpose: palette-independent, per TZ_OPENCODE_CALCS_OVERHAUL)
		damageTints = {
			{ 0.16, 0.17, 0.20, 0.35 }, -- All Types (neutral, bold total)
			{ 0.24, 0.24, 0.26, 0.28 }, -- Physical (cold silver)
			{ 0.28, 0.25, 0.08, 0.26 }, -- Lightning (muted amber)
			{ 0.09, 0.18, 0.30, 0.30 }, -- Cold (muted icy blue)
			{ 0.30, 0.13, 0.06, 0.28 }, -- Fire (muted warm)
			{ 0.24, 0.08, 0.24, 0.28 }, -- Chaos (muted purple)
		},
		damageHeaderColors = {
			[3] = "^xF0D050", -- Lightning
			[4] = "^x68A8FF", -- Cold
			[5] = "^xFF8844", -- Fire
			[6] = "^xE060C0", -- Chaos
		},
	},
	slider = {
		radius = 3, -- track capsule
		borderWidth = 1,
		shadowBlur = 0,
		trackBg = nil, -- dark input-like track fill
		trackBorder = nil,
		trackBorderHover = nil,
		trackDisabledBg = nil,
		trackDisabledBorder = nil,
		trackFill = nil, -- accent gold fill left of the knob (WinUI slider)
		tick = nil, -- divCount tick marks
		knob = nil, -- light round knob (WinUI thumb)
		knobBorder = nil,
		knobBorderActive = nil, -- accent ring while hovering / dragging
		arrow = nil, -- div-mode arrows take the place of the knob
		arrowActive = nil, -- while hovering / dragging
	},
	card = {
		radius = 8, -- radius.card
		borderWidth = 1,
		shadowBlur = 6, -- shadow.medium
		bg = nil,
		border = nil,
	},
	tooltip = {
		radius = 8, -- radius.card
		borderWidth = 1,
		shadowBlur = 10, -- shadow.large (expressive soft tooltip shadow)
		bg = nil,
		border = nil,
	},
	dialog = {
		radius = 8, -- radius.card
		borderWidth = 1,
		shadowBlur = 10, -- shadow.large
		bg = nil,
		border = nil,
		title = nil, -- dialog title text (no plate in Fluent)
	},
}

-- Resolve component tokens from the active palette (kept out of the literal
-- above so the palette stays the single source of truth).
local function Resolve(theme)
	local c = theme.colors
	theme.button.bg = c.surface
	theme.button.bgHover = c.surfaceHover
	theme.button.bgPressed = c.surfacePressed
	theme.button.bgDisabled = c.surfacePressed
	theme.button.bgActive = c.surfaceHover
	theme.button.border = c.stroke
	theme.button.borderHover = c.accent
	theme.button.borderPressed = c.accentPressed
	theme.button.borderDisabled = c.strokeDisabled
	theme.button.indicator = c.accent
	theme.button.text = c.textPrimary
	theme.button.textDisabled = c.textDisabled

	theme.edit.bg = c.background
	theme.edit.bgDisabled = c.surfacePressed
	theme.edit.border = c.stroke
	theme.edit.borderHover = c.strokeHover
	theme.edit.borderFocus = c.accent
	theme.edit.borderDisabled = c.strokeDisabled

	theme.checkbox.bgChecked = c.accent
	theme.checkbox.bgCheckedHover = c.accentHover
	theme.checkbox.bgCheckedPressed = c.accentPressed
	theme.checkbox.bgUnchecked = c.background
	theme.checkbox.bgDisabled = c.surfacePressed
	theme.checkbox.border = c.stroke
	theme.checkbox.borderHover = c.strokeHover
	theme.checkbox.borderDisabled = c.strokeDisabled
	theme.checkbox.check = c.check

	theme.dropdown.bg = c.surface
	theme.dropdown.bgDisabled = c.surfacePressed
	theme.dropdown.border = c.stroke
	theme.dropdown.borderHover = c.strokeHover
	theme.dropdown.borderOpen = c.accent
	theme.dropdown.borderDisabled = c.strokeDisabled
	theme.dropdown.popup.bg = c.surface
	theme.dropdown.popup.border = c.stroke
	theme.dropdown.itemHoverBg = c.surfaceHover

	theme.scrollbar.thumb = c.scrollThumb
	theme.scrollbar.thumbHover = c.scrollThumbHover
	theme.scrollbar.thumbDrag = c.scrollThumbDrag

	theme.list.bg = c.background
	theme.list.border = c.border
	theme.list.borderFocus = c.accent
	theme.list.rowHoverBg = c.surfaceHover
	theme.list.rowSelectedBg = c.surface
	theme.list.rowSelectedBgUnfocused = c.surfacePressed
	theme.list.rowIndicator = c.accent
	theme.list.rowSeparator = c.stroke

	-- Cards and sections use the softened stroke: flat WinUI cards separate
	-- through fill + spacing, not hard outlines (visual noise reduction)
	theme.section.bg = c.surface
	theme.section.border = c.strokeSoft
	theme.section.labelBg = c.surface -- blends the label plate into the card
	theme.section.labelText = c.textPrimary

	theme.calcSection.bg = c.surface
	theme.calcSection.border = c.strokeSoft
	theme.calcSection.cellHoverBg = c.veil
	theme.calcSection.cellSelectedBg = c.cellSelected
	theme.calcSection.cellIndicator = c.accent
	theme.calcSection.overlayBg = c.overlay
	theme.calcSection.overlayBorder = c.strokeSoft
	theme.calcSection.overlayBorderDrag = c.accent
	theme.calcSection.overlayHeaderBg = c.surfaceHover
	theme.calcSection.overlaySeparator = c.border

	theme.slider.trackBg = c.background
	theme.slider.trackBorder = c.stroke
	theme.slider.trackBorderHover = c.strokeHover
	theme.slider.trackDisabledBg = c.surfacePressed
	theme.slider.trackDisabledBorder = c.strokeDisabled
	theme.slider.trackFill = c.accent
	theme.slider.tick = c.border -- opaque hairline ticks, visible on fill and track
	theme.slider.knob = c.textPrimary
	theme.slider.knobBorder = c.stroke
	theme.slider.knobBorderActive = c.accent
	theme.slider.arrow = c.textSecondary
	theme.slider.arrowActive = c.textPrimary

	for _, key in ipairs({ "card", "tooltip", "dialog" }) do
		theme[key].bg = c.surface
		theme[key].border = c.strokeSoft
	end
	theme.dialog.title = c.textPrimary
end

Resolve(Theme)
if type(SetWindowDarkMode) == "function" then
	SetWindowDarkMode(true)
end

-- Switch the active palette ("Dark" | "Light"): re-resolves every component
-- token and keeps the Windows titlebar in sync through SetWindowDarkMode.
-- Also remaps the base text colour escape (^7) through the runtime's
-- SetIndexedColor so the thousands of "^7"-prefixed labels follow the palette
-- (white in Dark, deep dark in Light). Returns false for unknown theme names
-- (the active palette is untouched).
function Theme:SetTheme(name)
	if not palettes[name] then
		return false
	end
	if name == self.themeName then
		return true
	end
	self.themeName = name
	self.colors = palettes[name]
	Resolve(self)
	if type(SetWindowDarkMode) == "function" then
		SetWindowDarkMode(name == "Dark")
	end
	if type(SetClearColor) == "function" then
		local bg = self.colors.background
		SetClearColor(bg[1], bg[2], bg[3], bg[4] or 1)
	end
	if type(SetIndexedColor) == "function" then
		local text = self.colors.textPrimary
		SetIndexedColor(7, text[1], text[2], text[3])
	end
	if colorCodes and colorCodes.NORMAL then
		if name == "Light" then
			colorCodes.NORMAL = "^x1B1B1B"
		else
			colorCodes.NORMAL = "^xC8C8C8"
		end
		if colorCodes.ARMOUR then colorCodes.ARMOUR = colorCodes.NORMAL end
		if colorCodes.PHYS then colorCodes.PHYS = colorCodes.NORMAL end
	end
	return true
end

-- Name of the currently active palette.
function Theme:GetTheme()
	return self.themeName
end

-- Re-derives the accent tokens on one palette from the active accent entry.
-- Shade factors replicate the shipped values exactly for the default accent.
local function ApplyAccentTo(paletteField, accent, isLight)
	local base = isLight and accent.light or accent.dark
	paletteField.accent = base
	paletteField.accentHover = shade(base, isLight and 0.10 or 0.08)
	paletteField.accentPressed = shade(base, isLight and -0.10 or -0.12)
	if isLight then
		paletteField.accentDisabled = { base[1], base[2], base[3], 0.35 }
		paletteField.cellSelected = { base[1], base[2], base[3], 0.18 }
	else
		paletteField.accentDisabled = { base[1], base[2], base[3], 0.25 }
		paletteField.cellSelected = { base[1], base[2], base[3], 0.22 }
	end
	paletteField.check = isLight and accent.checkLight or accent.checkDark
end

-- Switch the accent palette ("PoE2 Gold" | "Fluent Blue" | "Crimson" |
-- "Emerald"): re-derives accent/accentHover/accentPressed/accentDisabled,
-- cellSelected and the checkbox check mark on both palettes, then re-resolves
-- the component tokens of the active palette. Returns false for unknown
-- accent names (state is untouched); a same-name call is a no-op.
function Theme:SetAccent(name)
	if not accents[name] then
		return false
	end
	if name == self.accentName then
		return true
	end
	self.accentName = name
	ApplyAccentTo(palettes.Dark, accents[name], false)
	ApplyAccentTo(palettes.Light, accents[name], true)
	Resolve(self)
	return true
end

function Theme:GetAccent()
	return self.accentName or defaultAccent
end

-- ThemeFluent is a singleton across LoadModule calls (which the runtime
-- executes uncached for every consumer) - every returned object is a proxy
-- onto one shared instance, so Main and the control classes share state.
local shared = _G.__THEME_FLUENT_SHARED__
if not shared then
	shared = { }
	_G.__THEME_FLUENT_SHARED__ = shared
end
shared.instance = Theme

-- Every consumer receives a write-through proxy view: reads hit the current
-- shared instance and writes propagate into it, so switching the theme or
-- accent from one place (Options) is visible to every control that loaded
-- its own copy of this module.
shared.view = shared.view or {
	__index = function(_, key)
		return shared.instance[key]
	end,
	__newindex = function(_, key, value)
		shared.instance[key] = value
	end,
}

return setmetatable({ }, shared.view)
