-- Path of Building
--
-- Module: UI Font
-- Font preset management for the Options dialog.
--
-- The SimpleGraphic runtime resolves font slots ("VAR", "VAR BOLD", ...)
-- from `<runtime>/SimpleGraphic/Fonts/<slot>.tgf` at startup only, so a font
-- preset is applied by swapping those slot config files and takes effect
-- after the next application restart (font reload).
--
-- Presets:
--   "authentic" (default): shipped legacy font configs are kept untouched
--     (Fontin / Fontin SmallCaps for the authentic slots, Liberation Sans for
--     VAR, with the shared UnicodeFallback.tgf chain on Noto Sans providing
--     Cyrillic/CJK glyphs).
--   "noto": ("Modern Sans (Noto Sans)") every UI font slot (VAR, VAR BOLD,
--     Fontin, Fontin SmallCaps and their italic variants) is redirected to
--     notosanssc-regular.ttf / notosanssc-semibold.ttf through TTF-config
--     .tgf files written by this module; the monospace console slot
--     (Bitstream Vera Sans Mono) is left untouched.
--
-- Original slot files are backed up once as "<slot>.tgf.authentic-bak" next
-- to the slot config, so switching back to "authentic" restores them
-- byte-exact. All swaps are idempotent: ApplyPreset/SetPreset sync the disk
-- state to the requested preset without rewriting already-correct files.
-- Settings persistence ("uiFont" attribute in the Misc element of
-- Settings.xml) is handled by Main.lua; this module only owns the disk side.

local t_insert = table.insert

local UIFont = {
	-- Identifier of the default preset (Main.lua falls back to this when
	-- Settings.xml has no uiFont attribute).
	defaultPreset = "authentic",
}

-- Font slots redirected by the "noto" preset, spanning the complete set of
-- UI font slots (r_main.cpp: F_VAR, F_VAR_BOLD, F_FONTIN, F_FONTIN_SC,
-- F_FONTIN_ITALIC, F_FONTIN_SC_ITALIC). Bitstream Vera Sans Mono (F_FIXED,
-- console) is intentionally preserved.
local slots = {
	{ name = "Liberation Sans", notoFile = "notosanssc-regular.ttf" },
	{ name = "Liberation Sans Bold", notoFile = "notosanssc-semibold.ttf" },
	{ name = "Fontin", notoFile = "notosanssc-regular.ttf" },
	{ name = "Fontin SmallCaps", notoFile = "notosanssc-semibold.ttf" },
	{ name = "Fontin Italic", notoFile = "notosanssc-regular.ttf" },
	{ name = "Fontin SmallCaps Italic", notoFile = "notosanssc-semibold.ttf" },
}

-- Ordered preset registry consumed by the Options DropDown.
local presets = {
	{
		id = "authentic",
		label = "PoE2 Authentic (Fontin)",
		desc = "Original PoE2 font set: Fontin with a Unicode fallback on Noto Sans.",
	},
	{
		id = "noto",
		label = "Modern Sans (Noto Sans)",
		desc = "Redirects the interface fonts to Noto Sans SC (supports Cyrillic and CJK).\nRequires a restart to apply.",
	},
}

local function find(list, id)
	for _, entry in ipairs(list) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

-- Marker written into injected TTF-config slot files. The runtime's
-- LoadTtfFaceFromConfig parser only looks at the "file" and "scale" fields,
-- so additional fields are ignored there.
local injectedMarker = "pobUIFont"

function UIFont.GetPresetList()
	local list = { }
	for _, preset in ipairs(presets) do
		t_insert(list, { id = preset.id, label = preset.label, desc = preset.desc })
	end
	return list
end

function UIFont.GetLabel(presetID)
	local preset = find(presets, presetID)
	return preset and preset.label or presetID
end

function UIFont.IsValidPreset(presetID)
	return find(presets, presetID) ~= nil
end

-- Returns the absolute path of the runtime Fonts directory, or nil plus a
-- reason when it cannot be located or read.
function UIFont.GetFontsDir()
	local runtimePath
	if type(GetRuntimePath) == "function" then
		runtimePath = GetRuntimePath()
	end
	if not runtimePath or runtimePath == "" then
		return nil, "runtime path unavailable"
	end
	local dir = runtimePath.."/SimpleGraphic/Fonts/"
	local probe, err = io.open(dir.."UnicodeFallback.tgf", "rb")
	if not probe then
		return nil, "Fonts directory not accessible: "..(err or "unknown error")
	end
	probe:close()
	return dir
end

local function readSlotFile(dir, slot)
	local file, err = io.open(dir..slot.name..".tgf", "rb")
	if not file then
		return nil, err or "cannot be opened"
	end
	local rest = file:read("*a")
	file:close()
	return rest
end

local function writeSlotFile(dir, name, content)
	local file, err = io.open(dir..name, "wb")
	if not file then
		return nil, err or "cannot be created"
	end
	file:write(content)
	file:close()
	return true
end

-- True when a slot file is a TTF config injected by this module (contains
-- the marker field) - a legacy .tgf and foreign configs do not match.
local function isSlotInjected(dir, slot)
	local content, err = readSlotFile(dir, slot)
	if not content or err then
		return nil
	end
	return content:find('"'..injectedMarker..'"') ~= nil
end

-- Copies the current slot config to the permanent authentic backup if no
-- backup exists yet and the slot is not currently injected.
local function ensureBackup(dir, slot)
	local backupName = slot.name..".tgf.authentic-bak"
	local backup = io.open(dir..backupName, "rb")
	if backup then
		backup:close()
		return true
	end
	if isSlotInjected(dir, slot) then
		return nil, "no backup available for "..slot.name
	end
	local content, err = readSlotFile(dir, slot)
	if not content or err then
		return nil, "cannot read "..slot.name..".tgf: "..(err or "unknown error")
	end
	local ok, writeErr = writeSlotFile(dir, backupName, content)
	if not ok then
		return nil, "cannot write backup for "..slot.name..": "..(writeErr or "unknown error")
	end
	return true
end

local function restoreSlot(dir, slot)
	local backupName = slot.name..".tgf.authentic-bak"
	local backup, err = io.open(dir..backupName, "rb")
	if not backup then
		return nil, "backup missing: "..(err or backupName.." cannot be opened")
	end
	local content = backup:read("*a")
	backup:close()
	local ok, writeErr = writeSlotFile(dir, slot.name..".tgf", content)
	if not ok then
		return nil, "cannot restore "..slot.name..": "..(writeErr or "unknown error")
	end
	return true
end

local function buildNotoConfig(slot)
	return ([[
{
	"comment": "UI font preset 'Modern Sans (Noto Sans)' injected by src/Modules/UIFont.lua",
	"%s": "noto",
	"file": "%s",
	"scale": 1.0
}
]]):format(injectedMarker, slot.notoFile)
end

-- Applies the given preset to the font slot files on disk.
-- @return true on success (or when already applied);
-- @return nil, reason string when the state cannot be changed safely.
function UIFont.ApplyPreset(presetID)
	if not find(presets, presetID) then
		return nil, "Unknown font preset '"..tostring(presetID).."'"
	end
	local dir, dirErr = UIFont.GetFontsDir()
	if not dir then
		return nil, dirErr
	end
	if presetID == "noto" then
		-- Redirect VAR / VAR BOLD to the Noto Sans TTFs.
		for _, slot in ipairs(slots) do
			local okBackup, backupErr = ensureBackup(dir, slot)
			if okBackup then
				local ok, err = writeSlotFile(dir, slot.name..".tgf", buildNotoConfig(slot))
				if not ok then
					return nil, "cannot redirect "..slot.name..": "..(err or "unknown error")
				end
			else
				return nil, "cannot backup "..slot.name..": "..(backupErr or "unknown error")
			end
		end
		return true
	else
		-- "authentic": roll every injected slot back to the shipped config.
		for _, slot in ipairs(slots) do
			if isSlotInjected(dir, slot) then
				local ok, err = restoreSlot(dir, slot)
				if not ok then
					return nil, err
				end
			end
		end
		return true
	end
end

-- Returns "noto" when the engine font slots on disk are currently redirected
-- by this module, "authentic" when they are in the shipped state, and nil
-- when the state cannot be detected.
function UIFont.GetAppliedPreset()
	local dir, dirErr = UIFont.GetFontsDir()
	if not dir then
		return nil, dirErr
	end
	for _, slot in ipairs(slots) do
		local injected = isSlotInjected(dir, slot)
		if injected == nil then
			return nil, "cannot read "..slot.name..".tgf"
		end
		if injected then
			return "noto"
		end
	end
	return "authentic"
end

-- Syncs the font slot files on disk to the requested preset without touching
-- already-correct files. Intended to be called at startup with the uiFont
-- value read from Settings.xml; it heals a state left half-applied by an
-- interrupted previous session (or by an update reinstalling the runtime).
-- @return ok(boolean), changed(boolean) on success; nil, reason on failure.
function UIFont.Sync(presetID)
	local applied, err = UIFont.GetAppliedPreset()
	if not applied then
		return nil, err
	end
	local requested = find(presets, presetID) and presetID or "authentic"
	if applied == requested then
		return true, false
	end
	local ok, applyErr = UIFont.ApplyPreset(requested)
	if not ok then
		return nil, applyErr
	end
	return true, true
end

return UIFont
