-- Path of Building
--
-- Module: Item Comparison
-- Shared helpers for side-by-side item comparison.
--

local pairs = pairs
local ipairs = ipairs
local t_insert = table.insert

local ItemComparison = { }

ItemComparison.MAX_TOOLTIP_WIDTH = 450
ItemComparison.CARD_GAP = 12

-- Places the secondary card next to the primary card. The right side is
-- preferred; the left side is used when the complete pair fits there. If
-- neither side can contain the pair without overlapping the primary card or
-- leaving the viewport, nil is returned and the caller omits the secondary
-- card for that frame.
function ItemComparison.GetSideBySideLayout(primaryX, primaryWidth, secondaryWidth, viewPort)
	if not viewPort then
		return nil, false
	end
	local rightX = primaryX + primaryWidth + ItemComparison.CARD_GAP
	if rightX + secondaryWidth <= viewPort.x + viewPort.width then
		return rightX, true
	end
	local leftX = primaryX - ItemComparison.CARD_GAP - secondaryWidth
	if leftX >= viewPort.x then
		return leftX, false
	end
	return nil, false
end

-- Flasks and charms compare activation state instead of replacing an item in
-- an equipment slot. These helpers keep that distinction in one place so the
-- side-by-side implementation cannot accidentally turn them into replacement
-- deltas.
function ItemComparison.GetActivationComparisonMode(base)
	if base and base.flask then
		return "toggleFlask"
	end
	if base and base.charm then
		return "toggleCharm"
	end
	return nil
end

function ItemComparison.ShouldBuildChildTooltips(item, options)
	if not item or not item.grantedSkills or #item.grantedSkills == 0 then
		return false
	end
	return not (options and options.skipChildTooltips)
end

-- Slots in the same family can be compared with one another. Weapon sets are
-- handled separately by the active weapon set, so the " Swap" suffix is not
-- part of the family name.
function ItemComparison.GetFamilyName(slotName)
	if not slotName then
		return nil
	end
	return slotName:gsub(" Swap$", ""):gsub(" %d+$", "")
end

local function getActiveWeaponSet(itemsTab)
	local mainEnv = itemsTab.build and itemsTab.build.calcsTab and itemsTab.build.calcsTab.mainEnv
	if mainEnv and mainEnv.weaponSet then
		return mainEnv.weaponSet
	end
	return itemsTab.activeItemSet and itemsTab.activeItemSet.useSecondWeaponSet and 2 or 1
end

local function isSlotActive(itemsTab, slot, weaponSet)
	if slot.inactive then
		return false
	end
	if slot.weaponSet then
		return slot.weaponSet == weaponSet
	end
	if type(slot.shown) == "function" then
		return slot.shown()
	end
	return slot.shown ~= false
end

-- Returns all slots in the active item set to which the item can be equipped.
function ItemComparison.GetCandidateSlots(itemsTab, item)
	local candidates = { }
	if not item or not item.base then
		return candidates
	end
	local weaponSet = getActiveWeaponSet(itemsTab)
	local orderedSlots = itemsTab.orderedSlots
	if orderedSlots and #orderedSlots > 0 then
		-- orderedSlots keeps passive sockets in numeric node order and avoids
		-- treating "Jewel 20" as older than "Jewel 3".
		for _, slot in ipairs(orderedSlots) do
			if isSlotActive(itemsTab, slot, weaponSet) and itemsTab:IsItemValidForSlot(item, slot.slotName) then
				t_insert(candidates, slot)
			end
		end
	else
		for slotName, slot in pairs(itemsTab.slots or { }) do
			if isSlotActive(itemsTab, slot, weaponSet) and itemsTab:IsItemValidForSlot(item, slotName) then
				t_insert(candidates, slot)
			end
		end
		table.sort(candidates, function(a, b)
			return a.slotName < b.slotName
		end)
	end
	return candidates
end

local function getHoveredSlotName(itemsTab, slot)
	if type(slot) == "table" then
		if slot.slotName then
			return slot.slotName
		end
		if slot.nodeId and itemsTab.sockets then
			local socket = itemsTab.sockets[slot.nodeId]
			return socket and socket.slotName or nil
		end
	elseif type(slot) == "string" then
		return slot
	end
	return nil
end

local function getPrimarySlotName(itemsTab, item)
	if not item then
		return nil
	end
	if type(itemsTab.GetComparisonSlotNameForItem) == "function" then
		return itemsTab:GetComparisonSlotNameForItem(item)
	end
	if type(item.GetPrimarySlot) == "function" then
		return item:GetPrimarySlot()
	end
	return nil
end

local function findSlotByName(candidates, slotName)
	for _, slot in ipairs(candidates) do
		if slot.slotName == slotName then
			return slot
		end
	end
	return nil
end

local function getFamilySlots(candidates, familyName)
	local familySlots = { }
	for _, slot in ipairs(candidates) do
		if ItemComparison.GetFamilyName(slot.slotName) == familyName then
			t_insert(familySlots, slot)
		end
	end
	return familySlots
end

-- Picks the slot used by the side-by-side card and by the stat deltas.
--
-- In compact mode, SHIFT toggles between the first two slots of a family
-- (Ring 1 <-> Ring 2, Weapon 1 <-> Weapon 2). When an equipped slot is
-- hovered, the hovered slot is used by default and SHIFT selects its paired
-- slot instead.
function ItemComparison.PickComparisonSlot(itemsTab, item, hoveredSlot, isCompact, shiftHeld)
	local candidates = ItemComparison.GetCandidateSlots(itemsTab, item)
	if #candidates == 0 then
		return nil
	end

	local hoveredSlotName = getHoveredSlotName(itemsTab, hoveredSlot)
	local hoveredCandidate = findSlotByName(candidates, hoveredSlotName)
	local targetFamily = ItemComparison.GetFamilyName(hoveredCandidate and hoveredCandidate.slotName or getPrimarySlotName(itemsTab, item))
	local familySlots = getFamilySlots(candidates, targetFamily)
	if #familySlots == 0 then
		familySlots = candidates
	end

	if isCompact then
		if hoveredCandidate then
			local hoveredIndex = 1
			for index, slot in ipairs(familySlots) do
				if slot.slotName == hoveredCandidate.slotName then
					hoveredIndex = index
					break
				end
			end
			local targetIndex = shiftHeld and (hoveredIndex == 1 and 2 or 1) or hoveredIndex
			return familySlots[targetIndex] or familySlots[1]
		end
		local targetIndex = shiftHeld and 2 or 1
		return familySlots[targetIndex] or familySlots[1]
	end

	return hoveredCandidate or familySlots[1]
end

return ItemComparison
