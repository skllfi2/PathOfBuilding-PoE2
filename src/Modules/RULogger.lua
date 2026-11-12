-- Path of Building
-- Module: RULogger
-- Runtime miss logger for untranslated Russian UI strings.
-- Logs strings that pass through UITranslationsRU:Get() unchanged (still English/mixed).

local t_insert = table.insert
local RULogger = { }

-- Configuration
RULogger.enabled = true
RULogger.flushIntervalMs = 2000
RULogger.logFileName = "untranslated_live.log"

-- State
local pending = { }        -- buffer of entries awaiting flush
local seen = { }           -- deduplication: seen[key] = true
local lastFlush = 0
local logFilePath = nil

-- Technical tokens to ignore (exact matches, case-insensitive)
local techTokens = {
    ["dps"] = true, ["ehp"] = true, ["es"] = true, ["hp"] = true,
    ["mp"] = true, ["xp"] = true, ["aoe"] = true, ["dot"] = true,
    ["pob"] = true, ["poe"] = true, ["poe2"] = true,
    ["ctrl"] = true, ["alt"] = true, ["shift"] = true,
    ["url"] = true, ["xml"] = true,
}

-- Short all-caps / mixed technical tokens (like "DPS", "EHP", "PoB", "Ctrl+V")
local techShort = {
    ["DPS"] = true, ["EHP"] = true, ["ES"] = true, ["HP"] = true,
    ["MP"] = true, ["XP"] = true, ["AoE"] = true, ["DoT"] = true,
    ["PoB"] = true, ["PoE"] = true, ["PoE2"] = true,
    ["URL"] = true, ["XML"] = true,
}

-- Check if text is a technical short token
local function isTechToken(text)
    if techTokens[text:lower()] then
        return true
    end
    if techShort[text] then
        return true
    end
    -- Ctrl+..., Alt+..., Shift+...
    if text:match("^[Cc]trl%+") or text:match("^[Aa]lt%+") or text:match("^[Ss]hift%+") then
        return true
    end
    -- v0.... version strings
    if text:match("^v%d") then
        return true
    end
    -- URLs
    if text:match("^http") then
        return true
    end
    -- Paths with / or .lua/.dds/.png
    if text:match("[/\\%.]lua$") or text:match("[/\\%.]dds$") or text:match("[/\\%.]png$") then
        return true
    end
    return false
end

-- Check if text contains Cyrillic UTF-8 bytes
local function hasCyrillic(text)
    return text:match("[\208\209]") ~= nil
end

-- Check if text has at least 2 consecutive Latin letters
local function hasLatinLetters(text)
    return text:match("[A-Za-z][A-Za-z]+") ~= nil
end

-- Count Latin words (sequences of letters) longer than 1 char
local function countLatinWords(text)
    local count = 0
    for word in text:gmatch("[A-Za-z][A-Za-z]+") do
        count = count + 1
    end
    return count
end

-- Determine if a string should be logged
local function shouldLog(rawText)
    if not rawText or rawText == "" then
        return false
    end
    -- Ignore technical tokens
    if isTechToken(rawText) then
        return false
    end
    -- Must have at least 2 consecutive Latin letters
    if not hasLatinLetters(rawText) then
        return false
    end
    -- If already has Cyrillic, check if it's a MIXED string
    if hasCyrillic(rawText) then
        -- Mixed if there are more than 1 Latin words (excluding known short tokens)
        local latinWordCount = 0
        for word in rawText:gmatch("[A-Za-z][A-Za-z]+") do
            if not techShort[word] then
                latinWordCount = latinWordCount + 1
            end
        end
        if latinWordCount > 1 then
            return true, "[MIXED]"
        end
        return false -- Cyrillic-only, not worth logging
    end
    -- Pure English/mixed without Cyrillic - log it
    return true, ""
end

-- Flush pending entries to log file
local function flush()
    if #pending == 0 then
        return
    end
    if not logFilePath then
        RULogger.Init()
    end
    if not logFilePath then
        return
    end
    local fh = io.open(logFilePath, "a")
    if not fh then
        return
    end
    for _, entry in ipairs(pending) do
        local safeText = tostring(entry.text):gsub("\r", ""):gsub("\n", "\\n")
        local tagPart = (entry.tag and entry.tag ~= "") and (entry.tag .. " ") or ""
        fh:write(string.format("[%s] %s%s\n", entry.source or "UI", tagPart, safeText))
    end
    fh:close()
    pending = { }
end

-- Public flush (for periodic calls from Main.lua OnFrame)
function RULogger.Flush()
    flush()
end

-- Initialize logger path
function RULogger.Init()
    local scriptPath = GetScriptPath and GetScriptPath() or "."
    if scriptPath == "" then scriptPath = "." end
    logFilePath = scriptPath .. "/" .. RULogger.logFileName
    if ConPrintf then
        ConPrintf("^7RULogger: untranslated strings log at " .. logFilePath)
    end
end

-- Log an untranslated string
function RULogger.Log(source, rawText)
    if not RULogger.enabled then
        return
    end
    -- Respect EN mode
    if main and main.itemLanguage == "EN" then
        return
    end
    local logIt, tag = shouldLog(rawText)
    if not logIt then
        return
    end
    local key = rawText
    if seen[key] then
        return
    end
    seen[key] = true
    t_insert(pending, { source = source or "UI", text = rawText, tag = tag })

    -- Periodic flush
    local now = GetTime and GetTime() or 0
    if now == 0 or (now - lastFlush >= RULogger.flushIntervalMs) then
        flush()
        lastFlush = now
    end
end

-- Flush and close (call on shutdown)
function RULogger.Shutdown()
    flush()
end

return RULogger
