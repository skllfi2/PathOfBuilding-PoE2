import glob
import json
import os
import re
import sys

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC_ROOT = os.path.join(REPO_ROOT, "src")
SCRATCH_DIR = os.path.join(REPO_ROOT, "scratch")
os.makedirs(SCRATCH_DIR, exist_ok=True)

OUT_META_JSON = os.path.join(SCRATCH_DIR, "ast_candidates_meta.json")
OUT_LUA = os.path.join(SCRATCH_DIR, "ast_audit_host.lua")

SKIP_FILES = {
    "RULogger.lua", "ModParser.lua", "ModStore.lua", "ModList.lua", "ModDB.lua",
    "ModTools.lua", "CalcTools.lua", "BuildSiteTools.lua", "Launch.lua",
    "UpdateCheck.lua", "UIFont.lua", "WindowState.lua", "ItemTools.lua",
    "Common.lua", "StatDescriber.lua", "Calcs.lua", "CalcActiveSkill.lua",
    "CalcSetup.lua", "CalcMirages.lua", "HeadlessWrapper.lua",
}

UI_CALLS = {
    "AddLine", "s_format", "format", "OpenPopup", "OpenConfirmPopup",
    "OpenMessagePopup", "LabelControl", "ButtonControl", "CheckBoxControl",
}
UI_FIELDS = {"tooltipText", "tooltip", "label", "footer", "prompt", "placeholder"}


def tokenize_lua(code: str):
    tokens = []
    i, n, line = 0, len(code), 1
    while i < n:
        c = code[i]
        if c == "\n":
            line += 1
            i += 1
        elif c in " \t\r":
            i += 1
        elif c == "-" and i + 1 < n and code[i + 1] == "-":
            if i + 3 < n and code[i + 2] == "[":
                m = re.match(r"\[(=*)\[", code[i + 2:])
                if m:
                    end_tag = "]" + m.group(1) + "]"
                    end_pos = code.find(end_tag, i + 2 + len(m.group(0)))
                    if end_pos == -1:
                        break
                    line += code[i:end_pos + len(end_tag)].count("\n")
                    i = end_pos + len(end_tag)
                    continue
            nl = code.find("\n", i)
            if nl == -1:
                break
            i = nl
        elif c in ('"', "'"):
            q = c
            j = i + 1
            buf = []
            while j < n:
                ch = code[j]
                if ch == "\\":
                    if j + 1 < n:
                        esc = code[j + 1]
                        if esc == "n": buf.append("\n")
                        elif esc == "t": buf.append("\t")
                        elif esc == "r": pass
                        else: buf.append(esc)
                        j += 2
                        continue
                elif ch == q:
                    j += 1
                    break
                elif ch == "\n":
                    line += 1
                buf.append(ch)
                j += 1
            tokens.append(("STR", "".join(buf), line))
            i = j
        elif c == "[" and i + 1 < n and code[i + 1] in ("[", "="):
            m = re.match(r"\[(=*)\[", code[i:])
            if m:
                end_tag = "]" + m.group(1) + "]"
                end_pos = code.find(end_tag, i + len(m.group(0)))
                if end_pos != -1:
                    raw = code[i + len(m.group(0)):end_pos]
                    line += raw.count("\n")
                    tokens.append(("STR", raw, line))
                    i = end_pos + len(end_tag)
                    continue
            tokens.append(("SYM", c, line))
            i += 1
        elif c == "." and i + 1 < n and code[i + 1] == ".":
            tokens.append(("OP", "..", line))
            i += 2
        elif c.isalpha() or c == "_":
            j = i + 1
            while j < n and (code[j].isalnum() or code[j] == "_"):
                j += 1
            tokens.append(("ID", code[i:j], line))
            i = j
        elif c.isdigit():
            j = i + 1
            while j < n and (code[j].isalnum() or code[j] in ".xX"):
                j += 1
            tokens.append(("NUM", code[i:j], line))
            i = j
        else:
            tokens.append(("SYM", c, line))
            i += 1
    return tokens


def extract_concat_expr(tokens, idx):
    parts = []
    n = len(tokens)
    while idx < n:
        t, v, _ = tokens[idx]
        if t == "STR":
            parts.append(v)
            idx += 1
        elif t == "NUM":
            parts.append(v)
            idx += 1
        elif t == "ID":
            expr_name = v
            idx += 1
            while idx < n and tokens[idx][1] in (".", ":"):
                idx += 1
                if idx < n and tokens[idx][0] == "ID":
                    expr_name += "." + tokens[idx][1]
                    idx += 1
            if idx < n and tokens[idx][1] == "(":
                depth = 1
                idx += 1
                while idx < n and depth > 0:
                    if tokens[idx][1] == "(": depth += 1
                    elif tokens[idx][1] == ")": depth -= 1
                    idx += 1
            parts.append("^7" if "colorCodes" in expr_name else "10")
        elif t == "SYM" and v == "(":
            depth = 1
            idx += 1
            while idx < n and depth > 0:
                if tokens[idx][1] == "(": depth += 1
                elif tokens[idx][1] == ")": depth -= 1
                idx += 1
            parts.append("10")
        else:
            break
        if idx < n and tokens[idx] == ("OP", "..", tokens[idx][2]):
            idx += 1
        else:
            break
    return "".join(parts), idx


def classify(rel_path: str, ctx: str) -> str:
    if "ConfigOptions" in rel_path or ctx == "tooltipText":
        return "ConfigTooltips" if "ConfigOptions" in rel_path else "Tooltip"
    if "Calc" in rel_path:
        return "CalcBreakdown"
    return "UI"


def is_ui_candidate(s: str) -> bool:
    s = s.strip()
    if len(s) < 3 or " " not in s:
        return False
    if s.startswith(("http://", "https://", "Assets/", "Data/", "Classes/", "Modules/", "TreeData/", "Builds/", "SELECT ", "INSERT ")):
        return False
    if not re.search(r"[A-Za-z]{2,}", s):
        return False
    if any(tok in s for tok in ("{", "}", "[[", "]]", "%(", "%)", ".*", ".+", "function(", "local ", "return ", "output:", "mod:")):
        return False
    if re.match(r"^[\^0-9a-fA-Fx\s%\+\-\*\/=:,\.]+$", s):
        return False
    return True


def norm_placeholders(s: str) -> str:
    t = re.sub(r"%[0-9\.\+\-]*[dfg]", "10", s)
    t = t.replace("%s", "Test").replace("%%", "%")
    return t


def lua_str(s: str) -> str:
    s = s.replace("\r", "").replace("\0", "")
    return f"[===[{s}]===]"


def main():
    by_test = {}
    for folder in ("Classes", "Modules"):
        for path in sorted(glob.glob(os.path.join(SRC_ROOT, folder, "**", "*.lua"), recursive=True)):
            bname = os.path.basename(path)
            if "\\Export\\" in path or "/Export/" in path or bname in SKIP_FILES or bname.startswith("ModParser"):
                continue
            rel = os.path.relpath(path, SRC_ROOT).replace("\\", "/")
            with open(path, encoding="utf-8", errors="ignore") as f:
                code = f.read()
            toks = tokenize_lua(code)
            i, n = 0, len(toks)
            while i < n:
                t, v, ln = toks[i]
                if t == "ID" and v in UI_FIELDS and i + 1 < n and toks[i + 1][1] == "=":
                    expr, nxt = extract_concat_expr(toks, i + 2)
                    for sub in expr.split("\n"):
                        sub_s = sub.strip()
                        if is_ui_candidate(sub_s):
                            test_s = norm_placeholders(sub_s)
                            entry = by_test.setdefault(test_s, {
                                "key": sub_s,
                                "test": test_s,
                                "category": classify(rel, v),
                                "locations": [],
                                "has_color_tags": bool(re.search(r"\^(?:x[0-9a-fA-F]{6}|[0-9])", sub_s)),
                                "placeholders": re.findall(r"%[0-9\.\+\-]*[dfgs]|\{\d+\}", sub_s),
                            })
                            loc = f"{rel}:{ln}"
                            if loc not in entry["locations"]:
                                entry["locations"].append(loc)
                    i = nxt
                    continue
                if t == "ID" and v in UI_CALLS and i + 1 < n and toks[i + 1][1] == "(":
                    j = i + 2
                    depth = 1
                    while j < n and depth > 0:
                        if toks[j][1] == "(":
                            depth += 1
                            j += 1
                        elif toks[j][1] == ")":
                            depth -= 1
                            j += 1
                        elif toks[j][0] == "STR" or (toks[j][0] == "ID" and j + 1 < n and toks[j + 1][0] == "OP"):
                            expr, nxt = extract_concat_expr(toks, j)
                            for sub in expr.split("\n"):
                                sub_s = sub.strip()
                                if is_ui_candidate(sub_s):
                                    test_s = norm_placeholders(sub_s)
                                    entry = by_test.setdefault(test_s, {
                                        "key": sub_s,
                                        "test": test_s,
                                        "category": classify(rel, v),
                                        "locations": [],
                                        "has_color_tags": bool(re.search(r"\^(?:x[0-9a-fA-F]{6}|[0-9])", sub_s)),
                                        "placeholders": re.findall(r"%[0-9\.\+\-]*[dfgs]|\{\d+\}", sub_s),
                                    })
                                    loc = f"{rel}:{ln}"
                                    if loc not in entry["locations"]:
                                        entry["locations"].append(loc)
                            j = nxt
                        else:
                            j += 1
                    i = j
                    continue
                i += 1

    items = list(by_test.values())
    with open(OUT_META_JSON, "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, indent=2)

    src_fwd = SRC_ROOT.replace("\\", "/") + "/"
    scratch_fwd = SCRATCH_DIR.replace("\\", "/") + "/"
    lua_lines = ["local items = {"]
    for it in items:
        lua_lines.append(
            f"  {{ {lua_str(it['category'])}, {lua_str(it['locations'][0])}, {lua_str(it['key'])}, {lua_str(it['test'])}, "
            f"{'true' if it['has_color_tags'] else 'false'} }},"
        )
    lua_lines.append("}")
    lua_lines.append(f'''
local SRC = "{src_fwd}"
local OUT_TXT = "{scratch_fwd}ast_audit_miss.txt"
local OUT_JSON = "{scratch_fwd}missing_to_translate.json"
function LoadModule(name, ...)
    if not name:match("%.lua$") then name = name .. ".lua" end
    local f, e = loadfile(SRC .. name)
    if not f then error(e) end
    return f(...)
end
main = {{ uiLanguage = "RU", itemLanguage = "DUAL", logUntranslatedRU = false }}
local ui = LoadModule("Data/UITranslationsRU")
local out = io.open(OUT_TXT, "w")
local jout = io.open(OUT_JSON, "w")
local function jesc(s)
    return s:gsub("\\\\", "\\\\\\\\"):gsub('"', '\\\\"'):gsub("\\n", "\\\\n"):gsub("\\r", ""):gsub("\\t", "\\\\t")
end
jout:write("[\\n")
local miss = 0
for _, it in ipairs(items) do
    local tr = ui:Get(it[4])
    if tr == it[4] then
        miss = miss + 1
        out:write(it[1] .. " | " .. it[2] .. " | " .. it[3] .. "\\n")
        if miss > 1 then jout:write(",\\n") end
        jout:write(string.format('  {{"category":"%s","location":"%s","key":"%s","has_color_tags":%s}}',
            jesc(it[1]), jesc(it[2]), jesc(it[3]), tostring(it[5])))
    end
end
jout:write("\\n]\\n")
jout:close()
out:write("TOTAL=" .. #items .. " MISS=" .. miss .. "\\n")
out:close()
Exit()
''')
    with open(OUT_LUA, "w", encoding="utf-8") as f:
        f.write("\n".join(lua_lines))

    print(f"AST v2 extracted {len(items)} unique expressions -> {OUT_LUA}")


if __name__ == "__main__":
    main()
