-- Path of Building
--
-- Multi-Build + Popup Headless UI & Calcs Crawler (runs in host.exe)
-- Crawls:
--  1. Default build + any .xml builds found in tools/ru_i18n/fixtures/ (optional)
--  2. All 9 tabs (IMPORT, NOTES, TREE, SKILLS, ITEMS, CALCS, CONFIG, PARTY, COMPARE)
--  3. Programmatic popups (Options, etc.)
--  4. All control labels, tooltipText, tooltipFunc, and calcsEnv.player.breakdown
--

local out = io.open("F:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/scratch/headless_audit_miss.txt", "w")
local seen = {}
local misses = {}

local function hasEnglishWord(s)
	if not s or type(s) ~= "string" then return false end
	local clean = s:gsub("%^x%x%x%x%x%x%x", ""):gsub("%^%d", "")
	if clean:match("[\208\209]") then return false end
	if clean:match("^%s*$") then return false end
	if not clean:match("[A-Za-z][A-Za-z]+") then return false end
	if clean:match("^https?://") or clean:match("^0x%x+$") then return false end
	return true
end

local function record(tag, orig, tr)
	if tr == orig and hasEnglishWord(orig) then
		local key = tag .. "|" .. orig
		if not seen[key] then
			seen[key] = true
			misses[#misses + 1] = "[" .. tag .. "] " .. orig:gsub("\r", ""):gsub("\n", "\\n")
		end
	end
end

local ok, err = pcall(function()
	local SRC = "F:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/src/"
	local RT = "F:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/runtime/"
	io.read = function() return "" end
	package.path = SRC .. "?.lua;" .. RT .. "lua/?.lua;" .. RT .. "lua/?/init.lua;" .. package.path
	package.cpath = RT .. "?.dll;" .. package.cpath

	local orig_loadfile = loadfile
	local orig_io_open = io.open
	io.open = function(path, mode, ...)
		local f, e = orig_io_open(path, mode, ...)
		if not f and (not mode or mode:sub(1, 1) == "r") and type(path) == "string" and not path:match("^%a:[/\\]") then
			f, e = orig_io_open(SRC .. path, mode, ...)
		end
		return f, e
	end
	loadfile = function(path, ...)
		local f, e = orig_loadfile(path, ...)
		if not f and type(path) == "string" and not path:match("^%a:[/\\]") then
			f, e = orig_loadfile(SRC .. path, ...)
		end
		return f, e
	end
	dofile = function(path)
		local f, e = loadfile(path)
		if not f then error(e) end
		return f()
	end

	dofile("HeadlessWrapper.lua")
	if newBuild then
		newBuild()
	elseif __mainObject__ and __mainObject__.main then
		__mainObject__.main:SetMode("BUILD", false, "Headless")
	end
	runCallback("OnFrame")

	local mainObj = __mainObject__.main
	mainObj.uiLanguage = "RU"
	mainObj.itemLanguage = "DUAL"
	mainObj.logUntranslatedRU = false

	local ui = LoadModule("Data/UITranslationsRU")

	local origDrawString = DrawString
	DrawString = function(x, y, align, height, font, text, ...)
		if type(text) == "string" then
			record("DRAW", text, ui:Get(text))
		end
		return origDrawString(x, y, align, height, font, text, ...)
	end

	local fakeTooltip = {
		AddLine = function(self, size, text)
			if type(text) == "string" then
				for line in (text .. "\n"):gmatch("([^\n]*)\n") do
					if line ~= "" then
						record("TT_FUNC", line, ui:Get(line))
					end
				end
			end
		end,
		AddSeparator = function() end,
		Clear = function() end,
		CheckForUpdate = function() return true end,
	}

	local function scanControls(prefix, ctrls)
		if type(ctrls) ~= "table" then return end
		for _, ctrl in pairs(ctrls) do
			if type(ctrl) == "table" then
				if type(ctrl.label) == "string" then
					record("CTRL:" .. prefix, ctrl.label, ui:Get(ctrl.label))
				end
				if type(ctrl.tooltipText) == "string" then
					for line in (ctrl.tooltipText .. "\n"):gmatch("([^\n]*)\n") do
						if line ~= "" then
							record("TT:" .. prefix, line, ui:Get(line))
						end
					end
				end
				if type(ctrl.tooltipFunc) == "function" then
					pcall(ctrl.tooltipFunc, fakeTooltip, ctrl)
				end
			end
		end
	end

	local function crawlCurrentBuild()
		local b = mainObj.modes["BUILD"]
		if not b then return end

		local tabs = { "IMPORT", "NOTES", "TREE", "SKILLS", "ITEMS", "CALCS", "CONFIG", "PARTY", "COMPARE" }
		for _, tabName in ipairs(tabs) do
			b.viewMode = tabName
			pcall(runCallback, "OnFrame")
		end

		local tabObjs = {
			IMPORT = b.importTab, NOTES = b.notesTab, TREE = b.treeTab,
			SKILLS = b.skillsTab, ITEMS = b.itemsTab, CALCS = b.calcsTab,
			CONFIG = b.configTab, PARTY = b.partyTab, COMPARE = b.compareTab,
		}
		for tname, tobj in pairs(tabObjs) do
			if tobj and tobj.controls then
				scanControls(tname, tobj.controls)
			end
		end

		if b.calcsTab and b.calcsTab.calcsEnv and b.calcsTab.calcsEnv.player and b.calcsTab.calcsEnv.player.breakdown then
			for bdKey, bd in pairs(b.calcsTab.calcsEnv.player.breakdown) do
				if type(bd) == "table" then
					for _, line in ipairs(bd) do
						if type(line) == "string" then
							record("BD:" .. tostring(bdKey), line, ui:Get(line))
						end
					end
					if bd.colList then
						for _, col in ipairs(bd.colList) do
							if type(col.label) == "string" then
								record("BD_COL", col.label, ui:Get(col.label))
							end
						end
					end
					if bd.rowList then
						for _, row in ipairs(bd.rowList) do
							for k, v in pairs(row) do
								if type(v) == "string" and k ~= "sourceName" then
									record("BD_ROW", v, ui:Get(v))
								end
							end
						end
					end
				end
			end
		end
	end

	-- Crawl default build
	crawlCurrentBuild()

	-- Crawl Options popup controls
	if mainObj.OpenOptionsPopup then
		pcall(function()
			mainObj:OpenOptionsPopup()
			if mainObj.popups and #mainObj.popups > 0 then
				local p = mainObj.popups[#mainObj.popups]
				scanControls("OPTIONS", p.controls)
				mainObj:ClosePopup()
			end
		end)
	end

	-- Crawl any XML build fixtures in tools/ru_i18n/fixtures/
	local fixDir = "F:/Development/Dev/mydev/PoB2Fork/PathOfBuilding-PoE2/tools/ru_i18n/fixtures/"
	local h = NewFileSearch and NewFileSearch(fixDir .. "*.xml")
	while h do
		local fname = h:GetFileName()
		local f = orig_io_open(fixDir .. fname, "r")
		if f then
			local xml = f:read("*a")
			f:close()
			if loadBuildFromXML then
				pcall(loadBuildFromXML, xml, fname)
				pcall(runCallback, "OnFrame")
				crawlCurrentBuild()
			end
		end
		if not h:NextFile() then break end
	end
end)

if not ok then
	out:write("ERROR: " .. tostring(err) .. "\n")
end
for _, m in ipairs(misses) do
	out:write(m .. "\n")
end
out:write("HEADLESS_MISSES=" .. #misses .. "\n")
out:close()
Exit()
