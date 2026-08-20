local ADDON_TITLE   = "Covetous Countess Assistant"
local ADDON_NAME    = "CovetousCountessAssistant"
local ADDON_AUTHOR  = "@AlexD"
local ADDON_VERSION = "__BUILD_VERSION__"
local ADDON_WEBSITE = "https://www.esoui.com/downloads/info4778-CovetousCountessAssistant.html"
local SV_VERSION    = 1

local SLASH_TRACK_SETTINGS = "/ccatracksettings" -- opens addon settings
local SLASH_TRACK_COUNTESS = "/ccatrackcountess" -- toggle Covetous Countess tracking
local SLASH_TRACK_CROW     = "/ccatrackcrow"     -- toggle Bursar of Tributes tracking
local SLASH_TRACK_STATUS   = "/ccatrackstatus"   -- show addon status

local CCA = {}

-- Cached ESO globals / functions
local EM                            = EVENT_MANAGER
local GetItemLink                   = GetItemLink
local GetItemLinkNumItemTags        = GetItemLinkNumItemTags
local GetItemLinkItemTagInfo        = GetItemLinkItemTagInfo
local ZO_ColorDef                   = ZO_ColorDef
local ZO_ScrollList_RefreshVisible  = ZO_ScrollList_RefreshVisible
local zo_strformat                  = zo_strformat
local zo_callLater                  = zo_callLater
local GetString                     = GetString
local ZO_SavedVars                  = ZO_SavedVars
local tinsert                       = table.insert
local tremove                       = table.remove

--[[
Treasure categories used by The Covetous Countess:
https://en.uesp.net/wiki/Online:Treasures
https://en.uesp.net/wiki/Online:The_Covetous_Countess
- Games, Dolls, and Statues
- Ritual Objects and Oddities
- Writings (inc. Scrivener Supplies) and Maps
- Cosmetics, Linens (Dry Goods), and Wardrobe Accessories
- Drinkware, Utensils, and Dishes and Cookware
--]]
local COUNTESS_DUMMY_IDS = {
    ["Collectibles"]                = {
        ["Games"]                   = "61630",
        ["Dolls"]                   = "64365",
        ["Statues"]                 = "61536",
    },
    [ "Curiosities" ]               = {
        ["Ritual Objects"]          = "64413",
        ["Oddities"]                = "61442",
        ["Magic Curiosities"]       = "64389",
    },
    [ "Documents" ]                 = {
        ["Writings"]                = "61207",
        ["Scrivener Supplies"]      = "62584",
        ["Maps"]                    = "62081",
    },
    [ "Accessories" ]               = {
        ["Cosmetics"]               = "63157",
        ["Dry Goods"]               = "61382",
        ["Wardrobe Accessories"]    = "61107",
    },
    [ "Kitchenware" ]               = {
        ["Drinkware"]               = "61458",
        ["Utensils"]                = "64326",
        ["Dishes and Cookware"]     = "61263",
    },
}

--[[
Treasure categories used by Bursar of Tributes (Crow):
https://en.uesp.net/wiki/Online:Bursar_of_Tributes
- A Matter of Leisure: toys, dolls or games
- A Matter of Respect: utensils, drinkware, dishes or cookware
- A Matter of Tributes: cosmetics and grooming supplies
--]]
local CROW_DUMMY_IDS = {
    ["Leisure"]                     = {
        ["Games"]                   = "61630",
        ["Dolls"]                   = "64365",
        ["Children's Toys"]         = "64325",
    },
    ["Respect"]     = {
        ["Drinkware"]               = "61458",
        ["Utensils"]                = "64326",
        ["Dishes and Cookware"]     = "61263",
    },
    ["Tributes"]    = {
        ["Cosmetics"]               = "63157",
        ["Grooming Items"]          = "62810",
    },
}

-- Quest IDs (reserved for future quest-aware highlighting)
local QUEST_NAME_ID = {
    ["The Covetous Countess"]   = 5584,
    ["A Matter of Respect"]     = 6072,
    ["A Matter of Tributes"]    = 6106,
    ["A Matter of Leisure"]     = 6107,
}

local QUEST_ID = {
    [5584] = true, -- The Covetous Countess
    [6072] = true, -- A Matter of Respect
    [6106] = true, -- A Matter of Tributes
    [6107] = true, -- A Matter of Leisure
}

-- Unlike the Countess, each Crow (Bursar of Tributes) quest always wants a
-- fixed, known category -- no fuzzy text matching required.
local CROW_QUEST_CATEGORY = {
    [6072] = "Respect",  -- A Matter of Respect
    [6106] = "Tributes", -- A Matter of Tributes
    [6107] = "Leisure",  -- A Matter of Leisure
}

local FENCE_ICON                = "/esoui/art/icons/servicemappins/servicepin_fence.dds"
local FENCE_ICON_COLOR_WHITE    = ZO_ColorDef:New("FFFFFF")
local FENCE_ICON_COLOR_GREEN    = ZO_ColorDef:New("00FF00")

local USED_ICONS = { [FENCE_ICON] = true, }

local TARGET_NAMES           = {
    -- en
    ["Tip Board"] = true,
    -- de
    ["Brett für Aufträge"] = true,
    -- fr
    ["Tableau des tuyaux"] = true,
    -- es
    ["Tablón de informes"] = true,
    -- ru
    ["Доска объявлений"] = true,
    -- jp
    ["ジョブボード"] = true,
    -- zh
    ["提示板"] = true,
}

local SKIP_RESPONSES         = {
    -- en
    ["<Keep reading.>"] = true,
    ["<Make a note of the request.>"] = true,

    -- de
    ["<Weiterlesen.>"] = true,
    ["<Diese Anfrage vermerken.>"] = true,

    -- fr
    ["<Continuer à lire.>"] = true,
    ["<Prendre note de la requête.>"] = true,

    -- es
    ["<Continuar leyendo.>"] = true,
    ["<Apuntar la petición.>"] = true,

    -- ru
    ["<Продолжить чтение.>"] = true,
    ["<Записать подробности.>"] = true,

    -- jp
    ["<続きを読む>"] = true,
    ["<要求をメモする>"] = true,

    -- zh
    ["<继续阅读。>"] = true,
    ["<记下任务要求。>"] = true,
}

local COUNTESS_RESPONSES     = {
    -- en
    ["<Read the contract.>"] = true,

    -- de
    ["<Den Kontrakt lesen.>"] = true,

    -- fr
    ["<Lire le contrat.>"] = true,

    -- es
    ["<Leer el contrato.>"] = true,

    -- ru
    ["<Прочесть контракт.>"] = true,

    -- jp
    ["<契約書を読む>"] = true,

    -- zh
    ["<阅读契约>"] = true,
}

----------------------------------------------------------------------
-- Localization cache
-- https://wiki.esoui.com/How_to_add_localization_support
-- dynamically change the language ingame via a slash command in the chat editbox:
-- /script SetCVar("language.2", "de")
--[[
Languages:
de	German
en	English
es	Spanish
fr	French
ru	Russian
jp	Japanese
zh	Chinese Simplified
br	Portugese
it	Italian
kr	Korean
pl	Polish
th	Thai
tr	Turkish
ua	Ukrainian
--]]
----------------------------------------------------------------------
local STRINGS = {}

local function CacheLocalizedStrings()
    STRINGS.OPTION_TRACK_COUNTESS 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_OPTION_TRACK_COUNTESS)
    STRINGS.OPTION_TRACK_COUNTESS_TOOLTIP 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_OPTION_TRACK_COUNTESS_TOOLTIP)
    STRINGS.OPTION_TRACK_CROW 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_OPTION_TRACK_CROW)
    STRINGS.OPTION_TRACK_CROW_TOOLTIP 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_OPTION_TRACK_CROW_TOOLTIP)
    STRINGS.OPTION_AUTOSKIP_TIPBOARD 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_OPTION_AUTOSKIP_TIPBOARD)
    STRINGS.OPTION_AUTOSKIP_TIPBOARD_TOOLTIP 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_OPTION_AUTOSKIP_TIPBOARD_TOOLTIP)
    STRINGS.OPTION_AUTOSKIP_TIPBOARD_WARNING 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_OPTION_AUTOSKIP_TIPBOARD_WARNING)
    STRINGS.SETTINGS 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_OPTION_SETTINGS)
    STRINGS.MSG_COUNTESS_ON 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_MSG_COUNTESS_ON)
    STRINGS.MSG_COUNTESS_OFF 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_MSG_COUNTESS_OFF)
    STRINGS.MSG_CROW_ON 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_MSG_CROW_ON)
    STRINGS.MSG_CROW_OFF 
        = GetString(SI_COVETOUSCOUNTESSASSISTANT_MSG_CROW_OFF)
end

----------------------------------------------------------------------
-- Saved Variables + LibAddonMenu2 panel
----------------------------------------------------------------------
local function RefreshInventoryIcons()
    if not PLAYER_INVENTORY or not PLAYER_INVENTORY.inventories then return end
    local types = {
        INVENTORY_BACKPACK,
        INVENTORY_BANK,
        INVENTORY_GUILD_BANK,
        INVENTORY_HOUSE_BANK,
        INVENTORY_CRAFT_BAG,
    }
    for _, invType in ipairs(types) do
        local inv = PLAYER_INVENTORY.inventories[invType]
        local listView = inv and inv.listView
        if listView and not listView:IsHidden() then
            ZO_ScrollList_RefreshVisible(listView)
        end
    end
end

local function InitSettings()
    local defaults = {
        trackCountess    = true,   -- track Covetous Countess treasure tags
        trackCrow        = false,  -- track Bursar of Tributes (Crow Store) treasure tags
        autoSkipTipBoard = false,  -- auto-close Tip Board offers that aren't the Countess
    }

    local SV = ZO_SavedVars:NewAccountWide(ADDON_NAME .. "_SV", SV_VERSION, "Settings", defaults)
    CCA.SV = SV

    if not LibAddonMenu2 then return end

    local panelData = {
        type                 = "panel",
        name                 = ADDON_TITLE,
        displayName          = ADDON_TITLE,
        author               = ADDON_AUTHOR,
        version              = ADDON_VERSION,
        website              = ADDON_WEBSITE,
        slashCommand         = SLASH_TRACK_SETTINGS,
        registerForRefresh   = true,
        registerForDefaults  = true,
    }

    local options = {
        {
            type    = "checkbox",
            name    = STRINGS.OPTION_TRACK_COUNTESS,
            tooltip = STRINGS.OPTION_TRACK_COUNTESS_TOOLTIP,
            getFunc = function() return SV.trackCountess end,
            setFunc = function(v)
                SV.trackCountess = v
                RefreshInventoryIcons()
            end,
            default = defaults.trackCountess,
        },
        {
            type    = "checkbox",
            name    = STRINGS.OPTION_TRACK_CROW,
            tooltip = STRINGS.OPTION_TRACK_CROW_TOOLTIP,
            getFunc = function() return SV.trackCrow end,
            setFunc = function(v)
                SV.trackCrow = v
                RefreshInventoryIcons()
            end,
            default = defaults.trackCrow,
        },
        {
            type    = "checkbox",
            name    = STRINGS.OPTION_AUTOSKIP_TIPBOARD,
            tooltip = STRINGS.OPTION_AUTOSKIP_TIPBOARD_TOOLTIP,
            warning = STRINGS.OPTION_AUTOSKIP_TIPBOARD_WARNING,
            getFunc = function() return SV.autoSkipTipBoard end,
            setFunc = function(v) SV.autoSkipTipBoard = v end,
            default = defaults.autoSkipTipBoard,
        },
    }

    LibAddonMenu2:RegisterAddonPanel(ADDON_NAME .. "Panel", panelData)
    LibAddonMenu2:RegisterOptionControls(ADDON_NAME .. "Panel", options)
end

----------------------------------------------------------------------
-- Treasure tag tables (built once at load)
----------------------------------------------------------------------
local COUNTESS_TAGS     = {} -- category -> { tag = true }
local COUNTESS_TAGS_SET = {} -- flat set
local CROW_TAGS         = {}
local CROW_TAGS_SET     = {}
local COMBINED_TAGS_SET = {}

local ACTIVE_QUESTS_ID   = {}
local ACTIVE_QUESTS_TAGS = {}

-- itemLink -> tags table | false (no matching tags). Tags never change mid-session.
local tagCache          = {}

local function ToItemLink(itemId)
    if not itemId then return nil end
    return "|H0:item:" .. itemId .. ":0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h"
end

local function GetTreasureTags(itemLink)
    if not itemLink or itemLink == "" then return nil end

    local cached = tagCache[itemLink]
    if cached ~= nil then
        return cached or nil
    end

    local tags = {}
    local count = GetItemLinkNumItemTags(itemLink)
    for i = 1, count do
        local tag, category = GetItemLinkItemTagInfo(itemLink, i)
        if category == TAG_CATEGORY_TREASURE_TYPE and tag and tag ~= "" then
            tinsert(tags, zo_strformat(SI_TOOLTIP_ITEM_TAG_FORMATER, tag))
        end
    end

    local result = #tags > 0 and tags or false
    tagCache[itemLink] = result
    return result or nil
end

local function BuildTagTables(source, dest, flatSet)
    for category, items in pairs(source) do
        dest[category] = {}
        for _, dummyId in pairs(items) do
            local tags = GetTreasureTags(ToItemLink(dummyId))
            if tags then
                for _, tag in ipairs(tags) do
                    dest[category][tag] = true
                    flatSet[tag] = true
                end
            end
        end
    end
end

local function BuildTreasureTags()
    BuildTagTables(COUNTESS_DUMMY_IDS, COUNTESS_TAGS, COUNTESS_TAGS_SET)
    BuildTagTables(CROW_DUMMY_IDS, CROW_TAGS, CROW_TAGS_SET)

    for tag in pairs(COUNTESS_TAGS_SET) do COMBINED_TAGS_SET[tag] = true end
    for tag in pairs(CROW_TAGS_SET) do COMBINED_TAGS_SET[tag] = true end
end

local function IsTrackedTreasure(itemLink)
    local tags = GetTreasureTags(itemLink)
    if not tags then return false end

    local set
    if CCA.SV.trackCountess and CCA.SV.trackCrow then
        set = COMBINED_TAGS_SET
    elseif CCA.SV.trackCountess then
        set = COUNTESS_TAGS_SET
    elseif CCA.SV.trackCrow then
        set = CROW_TAGS_SET
    else
        return false
    end

    for _, t in ipairs(tags) do
        if set[t] then return true end
    end
    return false
end

----------------------------------------------------------------------
-- Inventory icon hooks
----------------------------------------------------------------------
-- create local function to avoid globals for hooks
local function UpdateStatusControlIcons() 

    -- PreHook: inject (or strip) our icon path into additionalIcons before vanilla runs.
    ZO_PreHook("ZO_UpdateStatusControlIcons", function(inventorySlot, slotData)
        if not slotData or not slotData.bagId or not slotData.slotIndex then
            return false
        end

        local itemLink = GetItemLink(slotData.bagId, slotData.slotIndex)
        if not itemLink or itemLink == "" then return false end

        -- Prevent stacking on repeated redraws
        if slotData.additionalIcons then
            for i = #slotData.additionalIcons, 1, -1 do
                if USED_ICONS[slotData.additionalIcons[i]] then
                    tremove(slotData.additionalIcons, i)
                end
            end
        end

        if IsTrackedTreasure(itemLink) then
            slotData.additionalIcons = slotData.additionalIcons or {}
            slotData.additionalIcons[#slotData.additionalIcons + 1] = FENCE_ICON
        end

        return false -- let vanilla continue
    end)

    -- PostHook: apply tint. Vanilla AddIcon takes only the path, so tint must be
    -- set on iconData after the fact. Force hide/show so single-icon rows re-read tint.
    -- (See zo_multiicon.lua: each iconData entry is { iconTexture, iconTint, iconNarration }).
    ZO_PostHook("ZO_UpdateStatusControlIcons", function(inventorySlot, slotData)
        if not slotData or not slotData.additionalIcons then return end

        local hasOurs = false
        for _, icon in ipairs(slotData.additionalIcons) do
            if USED_ICONS[icon] then
                hasOurs = true
                break
            end
        end
        if not hasOurs then return end

        local statusControl = inventorySlot:GetNamedChild("StatusTexture")
        if not statusControl or not statusControl.iconData then return end

        local matchesQuest = false
        for _, questTags in pairs(ACTIVE_QUESTS_TAGS) do
            if questTags and slotData.bagId and slotData.slotIndex then
                local itemLink = GetItemLink(slotData.bagId, slotData.slotIndex)
                local itemTags = itemLink and GetTreasureTags(itemLink)
                if itemTags then
                    for _, tag in ipairs(itemTags) do
                        if questTags[tag] then
                            matchesQuest = true
                            break
                        end
                    end
                end
            end
        end

        local tinted = false
        for _, data in ipairs(statusControl.iconData) do
            if data.iconTexture == FENCE_ICON then
                data.iconTint = matchesQuest and FENCE_ICON_COLOR_GREEN or FENCE_ICON_COLOR_WHITE
                tinted = true
            end
        end

        if tinted then
            statusControl:SetHidden(true)
            statusControl:SetHidden(false)
        end
    end)

end

----------------------------------------------------------------------
-- Diagnostics
----------------------------------------------------------------------
local function CountEntries(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function CheckTreasureTagsLoaded()
    local expectedCountess, expectedCrow = 0, 0
    for _, items in pairs(COUNTESS_DUMMY_IDS) do
        expectedCountess = expectedCountess + CountEntries(items)
    end
    for _, items in pairs(CROW_DUMMY_IDS) do
        expectedCrow = expectedCrow + CountEntries(items)
    end
    return CountEntries(COUNTESS_TAGS_SET) == expectedCountess
        and CountEntries(CROW_TAGS_SET) == expectedCrow
end

----------------------------------------------------------------------
-- Quests Tracking
----------------------------------------------------------------------

-- N-gram fuzzy matching
-- lua 5.1 customized
local string_lower  = zo_strlower -- string.lower
local string_sub    = zo_strsub   -- string.sub
local string_len    = string.len
local string_byte   = string.byte

-- Language → n-gram size (based on linguistic characteristics)
-- Bigrams  for CJKT (characters ≈ syllables / concepts, no spaces)
-- Trigrams for Latin / Cyrillic / agglutinative (longer words + morphology)
local NGRAM_SIZE    = {
    zh = 1, -- Chinese Simplified
    jp = 1, -- Japanese
    kr = 2, -- Korean
    th = 2, -- Thai
    -- everything else defaults to 3
    de = 3,
    en = 3,
    es = 3,
    fr = 3,
    ru = 3,
    br = 3,
    it = 3,
    pl = 3,
    tr = 3,
    ua = 3,
}

local DEFAULT_NGRAM = 3

-- Multi-byte safe character iterator (UTF-8)
local function string_to_chars(str)
    local chars = {}
    local i = 1
    str = string_lower(str)
    local len = string_len(str)

    while i <= len do
        local byte = string_byte(str, i)
        local char_bytes = 1
        if byte >= 0xc0 and byte <= 0xdf then
            char_bytes = 2
        elseif byte >= 0xe0 and byte <= 0xef then
            char_bytes = 3
        elseif byte >= 0xf0 and byte <= 0xf7 then
            char_bytes = 4
        end

        local char = string_sub(str, i, i + char_bytes - 1)
        table.insert(chars, char)
        i = i + char_bytes
    end
    return chars
end

-- Generate a set of unique n-grams (n = 2 or 3)
local function get_ngrams(chars, n)
    local ngrams = {}
    if #chars < n then
        return ngrams -- too short → empty set
    end
    for i = 1, #chars - n + 1 do
        local gram = ""
        for j = 0, n - 1 do
            gram = gram .. chars[i + j]
        end
        ngrams[gram] = true
    end
    return ngrams
end

-- Score = fraction of the group's n-grams that appear anywhere in the quest text
-- (coverage of the short group inside the long text)
local function score_group_match(group_text, quest_text, n)
    local g_chars = string_to_chars(group_text)
    local q_chars = string_to_chars(quest_text)

    local group_ngrams = get_ngrams(g_chars, n)
    local quest_ngrams = get_ngrams(q_chars, n)

    local intersection = 0
    local total = 0

    for gram in pairs(group_ngrams) do
        total = total + 1
        if quest_ngrams[gram] then
            intersection = intersection + 1
        end
    end

    if total == 0 then
        return 0
    end
    return intersection / total
end

-- Main entry point
-- quest_text   = the long text to search in
-- word_groups  = { [category] = "tag1 tag2 tag3 ...", ... }
-- lang         = language code ("ru", "zh", "en", "jp" …)
-- returns best category name and its score, or nil, 0
local function FindMatchingGroup(quest_text, word_groups, lang)
    if not quest_text or quest_text == "" then
        return nil, 0
    end

    local n = NGRAM_SIZE[lang] or DEFAULT_NGRAM
    local best_group_id = nil
    local max_score = -1

    for group_id, group_string in pairs(word_groups) do
        local score = score_group_match(group_string, quest_text, n)
        d(string.format("DEBUG: %s: %.2f", group_id, score))
        if score > max_score then
            max_score = score
            best_group_id = group_id
        end
    end

    -- Soft floor against pure noise (safe because exactly one real match is guaranteed)
    if max_score >= 0.20 then
        return best_group_id, max_score
    end

    return nil, 0
end

-- Convert source[category][tag] = true
-- into  word_groups[category] = "tag1 tag2 tag3 ..."
local function PrepareWordGroups(source)
    local word_groups = {}

    for category, tags in pairs(source) do
        local parts = {}
        for tag, _ in pairs(tags) do -- _ is always true
            table.insert(parts, tag)
        end
        -- Join with a space (harmless for CJK, useful for Latin/Cyrillic)
        word_groups[category] = table.concat(parts, " ")
    end

    return word_groups
end

-- Find the best matching group for the given quest
local function FindBestGroup(questText, sourceTags)
    local currentLanguage = GetCVar("Language.2")
    if NGRAM_SIZE[currentLanguage] == nil then
        d("[" .. ADDON_NAME .. "] Language not found.")
        return nil, 0
    end
    d("[" .. ADDON_NAME .. "] Language key found! N-Gram size is: " .. NGRAM_SIZE[currentLanguage])
    local wordGroups = PrepareWordGroups(sourceTags)
    return FindMatchingGroup(questText, wordGroups, currentLanguage)
end

-- Start (or refresh) tracking for a quest
local function ActivateQuestTracking(questId, journalIndex)
    ACTIVE_QUESTS_ID[questId] = true

    if questId == QUEST_NAME_ID["The Covetous Countess"] then
        local _, _, activeStepText = GetJournalQuestInfo(journalIndex)
        local best_group_id, max_score = FindBestGroup(activeStepText, COUNTESS_TAGS)

        if best_group_id then
            d("[" .. ADDON_NAME .. "] Found a match for this quest: " .. best_group_id .. ", score: " .. max_score)
            ACTIVE_QUESTS_TAGS[questId] = COUNTESS_TAGS[best_group_id]
        elseif not ACTIVE_QUESTS_TAGS[questId] then
            d("[" .. ADDON_NAME .. "] Could not find a matching group for this quest.")
        end
    elseif CROW_QUEST_CATEGORY[questId] then
        -- Fixed category, no fuzzy matching needed.
        ACTIVE_QUESTS_TAGS[questId] = CROW_TAGS[CROW_QUEST_CATEGORY[questId]]
    end

    RefreshInventoryIcons()
end

-- Stop tracking a quest
local function DeactivateQuestTracking(questId)
    if not questId or not ACTIVE_QUESTS_ID[questId] then return end

    ACTIVE_QUESTS_ID[questId] = nil
    ACTIVE_QUESTS_TAGS[questId] = nil

    RefreshInventoryIcons()
end

-- On load / zone-in: pick up any relevant quests already in the journal
local function ScanActiveQuests()
    local numQuests = GetNumJournalQuests()
    for journalIndex = 1, numQuests do
        if IsValidQuestIndex(journalIndex) then
            local questId = GetJournalQuestId(journalIndex)
            if QUEST_ID[questId] then
                ActivateQuestTracking(questId, journalIndex)
            end
        end
    end
end

local function OnQuestAdded(eventCode, journalIndex, questName, objectiveName)
    local questId = GetJournalQuestId(journalIndex)
    if QUEST_ID[questId] then
        ActivateQuestTracking(questId, journalIndex)
    end
end

local function OnQuestAdvanced(eventCode, journalIndex, questName, objectiveName)
    local questId = GetJournalQuestId(journalIndex)
    if QUEST_ID[questId] then
        ActivateQuestTracking(questId, journalIndex)
    end
end

local function OnQuestRemoved(eventCode, isCompleted, journalIndex, questName, zoneIndex, poiIndex, questId)
    if QUEST_ID[questId] then
        DeactivateQuestTracking(questId)
    end
end

local function IsTargetBoard()
    return TARGET_NAMES[GetUnitName("interact") or ""] ~= nil
end

local function OnQuestOffered(eventCode)
    if not CCA.SV.autoSkipTipBoard then return end

    -- debug
    -- local _, response = GetOfferedQuestInfo()
    -- local name = GetUnitName("interact") or "unknown"
    -- local message = name .. "\n" .. response
    -- LocalDebugTools.ShowDebug(message)
    -- if true then return end

    if not IsTargetBoard() then return end

    local _, response = GetOfferedQuestInfo()

    if COUNTESS_RESPONSES[response] then
        d("[" .. ADDON_NAME .. "] Covetous Countess offer detected!")
        return
    end

    if SKIP_RESPONSES[response] then
        local interaction = SYSTEMS:GetObjectBasedOnCurrentScene(ZO_INTERACTION_SYSTEM_NAME)
        if interaction then interaction:CloseChatter() end
    end
end

local function RegisterQuestEvents()
    EM:RegisterForEvent(ADDON_NAME, EVENT_QUEST_ADDED, OnQuestAdded)
    EM:RegisterForEvent(ADDON_NAME, EVENT_QUEST_ADVANCED, OnQuestAdvanced)
    EM:RegisterForEvent(ADDON_NAME, EVENT_QUEST_OFFERED, OnQuestOffered)
    EM:RegisterForEvent(ADDON_NAME, EVENT_QUEST_REMOVED, OnQuestRemoved)
end

----------------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------------
local function ToggleTrackCountess()
    CCA.SV.trackCountess = not CCA.SV.trackCountess
    RefreshInventoryIcons()
    local msg = CCA.SV.trackCountess and STRINGS.MSG_COUNTESS_ON or STRINGS.MSG_COUNTESS_OFF
    if msg and msg ~= "" then
        d("[" .. ADDON_TITLE .. "] " .. msg)
    else
        d(string.format("[%s] Covetous Countess tracking: %s",
            ADDON_TITLE, CCA.SV.trackCountess and "ON" or "OFF"))
    end
end

local function ToggleTrackCrow()
    CCA.SV.trackCrow = not CCA.SV.trackCrow
    RefreshInventoryIcons()
    local msg = CCA.SV.trackCrow and STRINGS.MSG_CROW_ON or STRINGS.MSG_CROW_OFF
    if msg and msg ~= "" then
        d("[" .. ADDON_TITLE .. "] " .. msg)
    else
        d(string.format("[%s] Bursar of Tributes tracking: %s",
            ADDON_TITLE, CCA.SV.trackCrow and "ON" or "OFF"))
    end
end

local function ShowTrackingStatus()
    local sv = CCA.SV

    local function getStatus(isActive, msgOn, msgOff, label)
        local customMsg = isActive and msgOn or msgOff
        if customMsg and customMsg ~= "" then return customMsg end
        return string.format("%s tracking: %s", label, isActive and "ON" or "OFF")
    end

    local countess = getStatus(sv.trackCountess, STRINGS.MSG_COUNTESS_ON, STRINGS.MSG_COUNTESS_OFF, "Countess")
    local crow = getStatus(sv.trackCrow, STRINGS.MSG_CROW_ON, STRINGS.MSG_CROW_OFF, "Bursar of Tributes")

    d(string.format("[%s]\n%s\n%s", ADDON_TITLE, countess, crow))
end

----------------------------------------------------------------------
-- Load
----------------------------------------------------------------------
local function OnPlayerActivated()
    EM:UnregisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED)

    RegisterQuestEvents()
    ScanActiveQuests()
    if not CheckTreasureTagsLoaded() then
        d("[" .. ADDON_NAME .. "] Missing treasure tags — please report to the author.")
    end
end

local function OnLoaded(_, name)
    if name ~= ADDON_NAME then return end
    EM:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
    EM:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

    CacheLocalizedStrings()
    InitSettings()
    BuildTreasureTags()
    UpdateStatusControlIcons()

    SLASH_COMMANDS[SLASH_TRACK_COUNTESS] = ToggleTrackCountess
    SLASH_COMMANDS[SLASH_TRACK_CROW]     = ToggleTrackCrow
    SLASH_COMMANDS[SLASH_TRACK_STATUS]   = ShowTrackingStatus
end

EM:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnLoaded)
