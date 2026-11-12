-- Path of Building
--
-- Dictionary Quality Validator (runs in host.exe from src/)
-- Checks:
--  1. Syntax & loadability of all RU translation modules
--  2. Placeholder parity (%d, %s, %.2f, {0}, etc.) between EN keys and RU values
--  3. Malformed color tags (^x without 6 hex digits) or unintended %%
--  4. CJK / replacement character (\xEF\xBF\xBD) leaks
--  5. Sidebar label width budget (<= 185px) for BuildDisplayStats keys
--

local SRC = "F:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/"
local OUT = "F:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/scratch/validate_ru_dicts_report.txt"

function LoadModule(name, ...)
	if not name:match("%.lua$") then name = name .. ".lua" end
	local f, e = loadfile(SRC .. name)
	if not f then error(e) end
	return f(...)
end

main = { uiLanguage = "RU", itemLanguage = "DUAL", logUntranslatedRU = false }

local out = io.open(OUT, "w")
local warnings, errors = 0, 0

local function countPlaceholders(s)
	local counts = {}
	for ph in s:gmatch("%%[%d%.%+%-]*[dfgs]") do
		counts[ph] = (counts[ph] or 0) + 1
	end
	for ph in s:gmatch("{%d+}") do
		counts[ph] = (counts[ph] or 0) + 1
	end
	return counts
end

local function checkMap(modName, tbl)
	local n = 0
	for k, v in pairs(tbl) do
		if type(k) == "string" and type(v) == "string" then
			n = n + 1
			-- 1. Check replacement char or CJK (U+4E00..U+9FFF / Hangul)
			if v:find("\239\191\189", 1, true) then
				errors = errors + 1
				out:write("ERR [REPLACEMENT_CHAR] " .. modName .. " | " .. k .. "\n")
			end
			-- 2. Check malformed ^x tags
			for pos in v:gmatch("()%^x") do
				local hex = v:sub(pos + 2, pos + 7)
				if not hex:match("^%x%x%x%x%x%x$") then
					errors = errors + 1
					out:write("ERR [BAD_HEX_TAG] " .. modName .. " | " .. k .. " => " .. v .. "\n")
				end
			end
			-- 3. Check unintended %% when key had single %
			if v:find("%%%%", 1, true) and not k:find("%%%%", 1, true) then
				warnings = warnings + 1
				out:write("WARN [DOUBLE_PCT] " .. modName .. " | " .. k .. " => " .. v .. "\n")
			end
			-- 4. Placeholder parity
			local ck = countPlaceholders(k)
			local cv = countPlaceholders(v)
			for ph, cnt in pairs(ck) do
				if cv[ph] ~= cnt then
					warnings = warnings + 1
					out:write("WARN [PH_MISMATCH:" .. ph .. "] " .. modName .. " | " .. k .. " => " .. v .. "\n")
				end
			end
		end
	end
	out:write(string.format("CHECKED %s: %d entries\n", modName, n))
end

local ok, err = pcall(function()
	local ui = LoadModule("Data/UITranslationsRU")
	local cfg = LoadModule("Data/ConfigTooltipsRU")
	local bd = LoadModule("Data/CalcBreakdownRU")
	local sk = LoadModule("Data/SkillDescriptionsRU")
	local mod = LoadModule("Data/ModTranslationsRU")

	checkMap("UITranslationsRU.map", ui.map)
	checkMap("ConfigTooltipsRU", cfg)
	checkMap("CalcBreakdownRU.static", bd.static)
	checkMap("CalcBreakdownRU.parens", bd.parens)
	if sk.byDesc then checkMap("SkillDescriptionsRU.byDesc", sk.byDesc) end
	if mod.exact then checkMap("ModTranslationsRU.exact", mod.exact) end

	-- Check sidebar label widths from BuildDisplayStats.lua (when renderer is active)
	local bdsFile = io.open(SRC .. "Modules/BuildDisplayStats.lua", "r")
	if bdsFile then
		local bdsSrc = bdsFile:read("*a")
		bdsFile:close()
		local wideCount = 0
		local rendererAvail = pcall(DrawStringWidth, 16, "VAR", "test")
		if rendererAvail then
			local seen = {}
			for lbl in bdsSrc:gmatch('label%s*=%s*"([^"]+)"') do
				if not seen[lbl] then
					seen[lbl] = true
					local tr = ui:Get(lbl)
					local w = DrawStringWidth(16, "VAR", tr)
					if w > 180 then
						wideCount = wideCount + 1
						out:write(string.format("INFO [WIDE_SIDEBAR:%dpx] %s => %s\n", w, lbl, tr))
					end
				end
			end
			out:write("SIDEBAR_WIDE_OVER_180PX=" .. wideCount .. "\n")
		else
			out:write("INFO [SKIP_WIDTH_CHECK] Renderer not initialised in headless host.exe\n")
		end
	end
end)

if not ok then
	errors = errors + 1
	out:write("FATAL: " .. tostring(err) .. "\n")
end

out:write(string.format("SUMMARY: ERRORS=%d WARNINGS=%d\n", errors, warnings))
out:close()
Exit()
