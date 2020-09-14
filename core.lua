local addonName, T = ...;

local WhoChannel = LibStub("AceAddon-3.0"):NewAddon("WhoChannel", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0") -- , "AceConfigCmd-3.0", "AceConfigDialog-3.0")
local GetNumDisplayChannels,GetChannelDisplayInfo = GetNumDisplayChannels, GetChannelDisplayInfo
--local PanelTemplates_SetNumTabs, PanelTemplates_UpdateTabs = PanelTemplates_SetNumTabs, PanelTemplates_UpdateTabs
local C_ChatInfo, GetPlayerInfoByGUID, GetGuildInfo = C_ChatInfo, GetPlayerInfoByGUID, GetGuildInfo
local GetMaxPlayerLevel = GetMaxPlayerLevel
local select,pairs, ipairs, table, tinsert, format, max = select, pairs, ipairs, table, tinsert, format, max
-- LibStub:GetLibary('LibWho-2.0'):Embed(WhoChannel)
--local wholib = LibStub:GetLibrary('LibWho-2.0'):Library()
-- AceTimer:Embed(self)
local WARRIOR, MAGE, ROGUE, DRUID, HUNTER, SHAMAN, PRIEST, WARLOCK, PALADIN = "WARRIOR", "MAGE", "ROGUE", "DRUID", "HUNTER", "SHAMAN", "PRIEST", "WARLOCK", "PALADIN"
local RAID_CLASS_COLORS, CLASS_ICON_TCOORDS = RAID_CLASS_COLORS, CLASS_ICON_TCOORDS

local texture_path_index = {
    [WARRIOR] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:0:64:0:64|t",
    [MAGE] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:64:128:0:64|t",
    [ROGUE] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:128:196:0:64|t",
    [DRUID] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:196:256:0:64|t",
    [HUNTER] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:0:64:64:128|t",
    [SHAMAN] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:64:128:64:128|t",
    [PRIEST] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:128:196:64:128|t",
    [WARLOCK] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:196:256:64:128|t",
    [PALADIN] = "|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:0:64:128:196|t",

}
local localizedClasses = {
   [WARRIOR] = "Guerrier",
   [MAGE] = "Mage",
   [ROGUE] = "Voleur",
   [DRUID] = "Druide",
   [HUNTER] = "Chasseur",
   [SHAMAN] = "Chaman",
   [PRIEST] = "Prêtre",
   [WARLOCK] = "Démoniste",
   [PALADIN] = "Paladin",
}
local max_class_str_length = 0

do
   for _, localClass in pairs(localizedClasses) do
      max_class_str_length = max(max_class_str_length, #localClass)
   end
end

local basic_options = {
   type = "group",
   args = {
      chanToSpy = {
         name = "chat channel name to spy",
         desc = "allows to set the chat channel name",
         descStyle  = "inline",
         type = "input",
         set = function(info, val) WhoChannel.channel_to_track_name = val end,
         get = function(info)return WhoChannel.channel_to_track_name end
      }
   }

}

WhoChannel:RegisterChatCommand("wc", "SlashCommandProcessor")

function WhoChannel:SlashCommandProcessor(input)
   if not input or input:trim() == "" then
    --LibStub("AceConfigDialog-3.0"):Open("WhoChannel")
  else
    --LibStub("AceConfigCmd-3.0").HandleCommand(WhoChannel, "wc", "WhoChannel", input)
    if input:trim() == "report" then
      self:ReportChanStatus()
    end
  end
end

function WhoChannel:SchedulePrintReportTimer()
   if self.reportTimer ~= nil then
      self:CancelTimer(self.reportTimer)
   end
   self.reportTimer = self:ScheduleRepeatingTimer("ReportChanStatus", 60 , "foo")
end

function WhoChannel:AddToPlayersCache(guid, localizedClass, englishClass, localizedRace, englishRace, sex, name, realm,  guildName, guildRankName, guildRankIndex, level)
   self:Print("AddToPlayersCache "..guid .. " - " .. (name or "noname"))
   local p = {
      localizedClass = localizedClass,
      englishClass = englishClass,
      localizedRace = localizedRace,
      englishRace = englishRace,
      sex = sex,
      name = name,
      realm = realm,
      guildName = guildName,
      guildRankName = guildRankName,
      guildRankIndex = guildRankIndex,
      level = level
   }
   local existing = self.player_cache[guid]
   if existing ~= nil then
      self:Print("USE OF ADD INSTEAD OF UPDATE !!!!! (".. guid..")")
      return
      ---- for a given guid, we suppose that only the following fields may change over time
      --if guildName~= nil and existing.guildName ~= nil and existing.guildName ~= guildName then
      --   p.guildName = guildName
      --end
      --if guildRankName ~= nil and existing.guildRankName ~= nil and existing.guildRankName ~= guildRankName then
      --   p.guildRankName = guildRankName
      --end
      --if guildRankIndex ~= nil and existing.guildRankIndex ~= nil and existing.guildRankIndex ~= guildRankIndex then
      --   p.guildRankIndex = guildRankIndex
      --end
      --if level ~= nil and level ~= 0 and existing.level ~= nil and existing.level ~= level then
      --   p.level = level
      --end
   end
   self.player_cache[guid] = p
   self.player_cache.count = self.player_cache.count + 1
end


function WhoChannel:UpdatePlayersCache(guid, localizedClass, englishClass, localizedRace, englishRace, sex, name, realm,  guildName, guildRankName, guildRankIndex, level)
   self:Print("UpdatePlayersCache "..guid .. " - " .. name)
   local p = {
      localizedClass = localizedClass,
      englishClass = englishClass,
      localizedRace = localizedRace,
      englishRace = englishRace,
      sex = sex,
      name = name,
      realm = realm,
      guildName = guildName,
      guildRankName = guildRankName,
      guildRankIndex = guildRankIndex,
      level = level
   }
   local existing = self.player_cache[guid]
   if existing == nil then
      self:Print("USE OF UPDATE INSTEAD OF ADD !!!!! (".. guid..")")
      return
   else
      -- for a given guid, we suppose that only the following fields may change over time
      if guildName~= nil and existing.guildName ~= nil and existing.guildName ~= guildName then
         p.guildName = guildName
      end
      if guildRankName ~= nil and existing.guildRankName ~= nil and existing.guildRankName ~= guildRankName then
         p.guildRankName = guildRankName
      end
      if guildRankIndex ~= nil and existing.guildRankIndex ~= nil and existing.guildRankIndex ~= guildRankIndex then
         p.guildRankIndex = guildRankIndex
      end
      if level ~= nil and level ~= 0 and existing.level ~= nil and level > existing.level then
         p.level = level
      end
      self.player_cache[guid] = p
   end
end


function WhoChannel:IsPlayerInCache(guid)
   --self:Print("IsPlayerInCache "..guid)
   return self.player_cache[guid] ~= nil
end

function WhoChannel:GetFromPlayersCache(guid)
   --self:Print("GetFromPlayersCache "..guid)
   return self.player_cache[guid]
end


function WhoChannel:AddPlayerToChanDataBase(guid)
   --self:Print("AddPlayerToChanDataBase "..guid)
   ----self:SetPlayerCount(self.channel_to_track_index, self.playerCount)
   --local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(guid)

   --if self.classes_all_level[englishClass][name] ~= nil then return end

   --self.playerCount = self.playerCount + 1

   --local guildName, guildRankName, guildRankIndex, _ = GetGuildInfo(name)

   --local level = UnitLevel(guid)
   --if level == nil or level == 0 then
   --   level = "?"
   --end
   --local p = {
   --         --name = name,
   --         --class = englishClass,
   --         --localizedClass = localizedClass,
   --         guildName = guildName or "undefined",
   --         level = level or "?",
   --         guid = guid,

   --         localizedClass = localizedClass,
   --         englishClass = englishClass,
   --         localizedRace = localizedRace,
   --         englishRace = englishRace,
   --         sex = sex,
   --         name = name,
   --         realm = realm,
   --         guildName = guildName,
   --         guildRankName = guildRankName,
   --         guildRankIndex = guildRankIndex,
   --         level = level
   --      }
   -- tinsert(self.classes_all_level[englishClass], p)
   local p = self.player_cache[guid]


   if p.englishClass ~= nil then
      if self.classes_all_level[p.englishClass][guid] == nil then
         self.classes_all_level[p.englishClass][guid] = p
      end
      self.classes_all_level[p.englishClass].count = self.classes_all_level[p.englishClass].count + 1
      self.playerCount = max(0, self.playerCount + 1)
      --self:Print("---- FINE ----")
   else
      self:Print("---")
      self:Print("AddPlayerToChanDataBase FUCKED UP "..guid)
      self:Print("localizedClass=" .. (p.localizedClass or "nil"))
      self:Print("englishClass=" .. (p.englishClass or "nil"))
      self:Print("localizedRace=" .. (p.localizedRace or "nil"))
      self:Print("englishRace=" .. (p.englishRace or "nil"))
      self:Print("sex=" .. (p.sex or "nil"))
      self:Print("name=" .. (p.name or "nil"))
      self:Print("realm=" .. (p.realm or "nil"))
      self:Print("guildName=" .. (p.guildName or "nil"))
      self:Print("guildRankName=" .. (p.guildRankName or "nil"))
      self:Print("guildRankIndex=" .. (p.guildRankIndex or "nil"))
      self:Print("level=" .. (p.level or "nil"))
      self:Print("---- FUCK ----")
   end

end

function WhoChannel:RemovePlayerFromChanDataBase(guid)
   --self:Print("RemovePlayerFromChanDataBase "..guid)
   self.playerCount = max(0, self.playerCount - 1)
   --if self.playerCount <= 0 then
   --   self.playerCount = 0
   --end
   --self:SetPlayerCount(self.channel_to_track_index, self.playerCount)
   local _, englishClass, _, _, _, name, _ = GetPlayerInfoByGUID(guid)
   self.classes_all_level[englishClass][guid] = nil
   self.classes_all_level[englishClass].count = max(0, self.classes_all_level[englishClass].count - 1)
end


function WhoChannel:TryToGrabPlayerData(guid)
   self:Print("TryToGrabPlayerData "..guid)
   local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(guid)
   local guildName, guildRankName, guildRankIndex --, _ = GetGuildInfo(name)
   local level = 0
   local raidIndex = UnitInRaid(name)
   local isInParty = UnitInParty(name)
   --local isInMyGuild = UnitIsInMyGuild(name)

   if raidIndex and not C_PvP.IsActiveBattlefield() then
      -- _, _, _, level, _, _, _, _, _, _, _ = GetRaidRosterInfo(raid_index)
      level = select(4, GetRaidRosterInfo(raid_index))
   elseif isInParty then
      local unit_id = nil
      for _, v in ipairs{"party1", "party2", "party3", "party4"} do
         if UnitName(v) == name then
            unit_id = v
            break
         end
      end
      level = UnitLevel(unit_id)
      guildName, guildRankName, guildRankIndex, _ = GetGuildInfo(unit_id)
   end
   --elseif isInMyGuild then
   --   for i=1, GetNumGuildMembers() do
   --      _, guildRankName, guildRankIndex, level, _, _, _, _, _, _, _, _, _, _, _, _ = GetGuildRosterInfo(i)
   --   end
   --end
   return guid, localizedClass, englishClass, localizedRace, englishRace, sex, name, realm,
         guildName, guildRankName, guildRankIndex, level
end


function WhoChannel:AddPlayer(guid)
   --self:Print("Adding "..guid)
   local isInCache = self:IsPlayerInCache(guid)



   if not isInCache then
      local _, localizedClass, englishClass, localizedRace, englishRace, sex, name, realm, guildName, guildRankName,
       guildRankIndex, level = self:TryToGrabPlayerData(guid)
      self:AddToPlayersCache(guid, localizedClass, englishClass, localizedRace, englishRace, sex, name, realm,
         guildName, guildRankName, guildRankIndex, level)
   else
      --local _, localizedClass, englishClass, localizedRace, englishRace, sex, name, realm,
      --   guildName, guildRankName, guildRankIndex, level = self:TryToGrabPlayerData(guid)
      --self:UpdatePlayersCache(guid, localizedClass, englishClass, localizedRace, englishRace, sex, name, realm,
      --   guildName, guildRankName, guildRankIndex, level)
   end
   self:AddPlayerToChanDataBase(guid)
end

function WhoChannel:RemovePlayer(guid)
   self:RemovePlayerFromChanDataBase(guid)
end


function WhoChannel:playerDataTableToString(playersMap) --, englishClass)
   local t = {}
   -- local p
   local class_color_str
   local s
   --self:Print("Dealing with  ".. englishClass .. " type of map is " .. type(playersMap))
   for guid, p in pairs(playersMap) do
      if guid ~= "count" then
         if guid ~= nil then
            if self:IsPlayerInCache(guid) then
               -- p = self.player_cache[guid]
               class_color_str = format("|c%s", RAID_CLASS_COLORS[p.englishClass].colorStr)
               s = format("%s%s%s(%s)", class_color_str, p.name, "|r", p.level)
               tinsert(t, s)
            else
               self:Print("WTF BBQ - guid " .. guid .. " not in cache ?!")
            end
         else
            self:Print("no Guid for class")
         end
      end
   end
   return table.concat( t, "|r, ")
end


function WhoChannel:ReportChanStatus()
   self:Print("ReportChanStatus")
   if self.playerCount <=0 then return end

   self:Print("--- Chan Status ---")
   self:Print("--- Total : " .. self.playerCount)
   -- local classes_all_level = self.classes_all_level
   for englishClass, playersMap in pairs(self.classes_all_level) do
      local nb = playersMap.count
      local format_str = "%2d %s %-"..max_class_str_length.."s: %s" -- size it to max class name length
      local output

      if nb > 0 then
         local texture_path_str = texture_path_index[englishClass] or "shit !"
         local s = self:playerDataTableToString(playersMap, englishClass)
         output = format(format_str, nb, texture_path_str, localizedClasses[englishClass], s)
         self:Print(output)
      end
   end
   self:Print("-------------------")
end


function WhoChannel:SearchChannelIdentifiers(channelName, displayIndex, channelIndex)
   if self.channel_found then -- self.updatePlayerListTimer ~= -1 and self.channel_to_track_index ~= -1 then
      return
   end
   if channelName ~= nil and channelName ~= self.channel_to_track_name then
      return
   end

   if channelName == nil and (displayIndex == nil or displayIndex <0) and (channelIndex == nil or channelIndex < 0) then
      return
   end

   self:Print("SearchChannelIdentifiers")
   --local L_channelIndex = channelIndex
   --local count, category
   local current_chan_name -- = channelName
   -- local is_found = false
   local channelCount = GetNumDisplayChannels()
   for index = 0, channelCount, 1 do
      current_chan_name= GetChannelDisplayInfo(index)
      if (current_chan_name ~=nil and current_chan_name == self.channel_to_track_name) then
         -- L_channelIndex = index
         self.channel_to_track_index = index
         self.channel_found = true
         break;
      end
   end

   if self.channel_found then
      self:Print("Channel found")
      --self:UnregisterEvent("CHAT_MSG_CHANNEL_JOIN")
      self:UnregisterEvent("CHANNEL_FLAGS_UPDATED")
      --self:UnregisterEvent("CHAT_MSG_CHANNEL_LEAVE")
      self:UnregisterEvent("CHANNEL_COUNT_UPDATE")
      --if self.reportTimer == nil then
      --   self:Print("Starting report timer")
      --   self.reportTimer = self:ScheduleRepeatingTimer("ReportChanStatus", 60 , "foo")
      --end
      self:SchedulePrintReportTimer()
   end
end


function WhoChannel:GetClassesStats()
   local current_count = select(5,GetChannelDisplayInfo(self.channel_to_track_index))
   if current_count == nil or self.playerCount == nil then
      --or current_count ~= self.playerCount then
      -- game not ready to tell us how many players in chan
      return
   end
   self.playerCount = 0
   -- reset map
   --self.classes_all_level = {
   --   [WARRIOR] = { count = 0},
   --   [MAGE] = { count = 0},
   --   [ROGUE] = { count = 0},
   --   [DRUID] = { count = 0},
   --   [HUNTER] = { count = 0},
   --   [SHAMAN] = { count = 0},
   --   [PRIEST] = { count = 0},
   --   [WARLOCK] = { count = 0},
   --   [PALADIN] = { count = 0},
   --}
   -- self:Print("Found ".. current_count .. " players in ["..self.channel_to_track_name.."]")
   for j=1, current_count, 1 do
      --self:Print("Player n° " .. j)
      --local name2, owner, moderator, muted, active, enabled = C_ChatInfo.GetChannelRosterInfo(target_channel_id, j)
      local _, _, _, guid = C_ChatInfo.GetChannelRosterInfo(self.channel_to_track_index, j)
      --self:Print("ChannelId=" .. target_channel_id .. " " .. name2)
      --local guid = UnitGUID(name2)
      if guid ~= nil then
         self:AddPlayer(guid)
      end
   end
   --self:Print("Updating internal classes list status")
   --if self.reportTimer ~= nil then
   --   self:CancelTimer(self.reportTimer)
   --   self.reportTimer = self:ScheduleRepeatingTimer("ReportChanStatus", 60 , "foo")
   --end
   self:SchedulePrintReportTimer()
end


function WhoChannel:CHAT_MSG_CHANNEL(_, text, playerNameWithRealm, _, channelFullName, playerName2, _, _, channelDisplayIndex, channelBaseName, _,_,guid,_)
   --self:Print("CHAT_MSG_CHANNEL - channelBaseName=".. channelBaseName .. " channelDisplayIndex=" ..channelDisplayIndex)
   if not self.channel_found then
      self:SearchChannelIdentifiers(channelBaseName, channelDisplayIndex, nil)
   end

   if self.channel_to_track_name == channelBaseName then
      -- do stuff
      self:AddPlayer(guid)
   end
end


function WhoChannel:CHAT_MSG_CHANNEL_JOIN(_, text, playerName, languageName, channelFullName, _, _, _, channelDisplayIndex, channelBaseName, _, _, guid)
   --self:Print("CHAT_MSG_CHANNEL_JOIN - channelBaseName=".. channelBaseName .. " channelDisplayIndex=" ..channelDisplayIndex)
   --if giud == nil then
   self:SearchChannelIdentifiers(channelBaseName, channelDisplayIndex, nil)
   --else
      -- TODO: manage single new guid
   --end
   if not self.channel_found or not channelBaseName == self.channel_to_track_name then return end
   self:Print("CHAT_MSG_CHANNEL_JOIN ".. playerName .. " " .. guid)
   self:AddPlayer(guid)
   self:ReportChanStatus()
end

function WhoChannel:CHAT_MSG_CHANNEL_LEAVE(_, text, playerName, languageName, channelFullName, _, _, _, channelDisplayIndex, channelBaseName, _, _, guid)
   if not self.channel_found then return end
   if channelBaseName ~= self.channel_to_track_name then return end
   -- self.playerCount = self.playerCount - 1
   -- if not self.channel_found or not channelBaseName == self.channel_to_track_name then return end
   self:Print("CHAT_MSG_CHANNEL_LEAVE ".. playerName .. " " .. guid)
   self:RemovePlayer(guid)
   self:ReportChanStatus()
end

function WhoChannel:CHANNEL_ROSTER_UPDATE(_, channelIndex, count)
   -- self:Print("CHANNEL_ROSTER_UPDATE")
   if self.channel_found and self.channel_to_track_index == channelIndex then
      self:Print("CHANNEL_ROSTER_UPDATE for "..self.channel_to_track_name)
   else
      self:SearchChannelIdentifiers(nil, nil, channelIndex)
   end

   if not self.channel_found then return end
   if self.channel_to_track_index ~= channelIndex then return end

   self.classes_all_level = {
      [WARRIOR] = { count = 0},
      [MAGE] = { count = 0},
      [ROGUE] = { count = 0},
      [DRUID] = { count = 0},
      [HUNTER] = { count = 0},
      [SHAMAN] = { count = 0},
      [PRIEST] = { count = 0},
      [WARLOCK] = { count = 0},
      [PALADIN] = { count = 0},
   }
   --self:SetPlayerCount(channelIndex, count)
   self:GetClassesStats()
   --self:ReportChanStatus()
   self:Print("ASSERTION: computed player count=".. self.playerCount .. " event count=" .. count)
end

function WhoChannel:CHANNEL_COUNT_UPDATE(_, channelIndex, new_count)
   -- self:Print("CHANNEL_COUNT_UPDATE - channelIndex="..channelIndex)
   if self.channel_found and self.channel_to_track_index == channelIndex then
      self:Print("CHANNEL_ROSTER_UPDATE for "..self.channel_to_track_name)
   end
   self:SearchChannelIdentifiers(nil, nil, channelIndex)
   --self:SetPlayerCount(channelIndex, new_count)
   if not self.channel_found then return end
   if self.channel_to_track_index ~= channelIndex then return end

   self:GetClassesStats()
   --self:ReportChanStatus()
   self:Print("ASSERTION: computed player count=".. self.playerCount .. " event count=" .. new_count)
end

function WhoChannel:CHANNEL_FLAGS_UPDATED(_, channelIndex)
   -- self:Print("CHANNEL_FLAGS_UPDATED - channelIndex="..channelIndex)
   self:SearchChannelIdentifiers(nil, nil, channelIndex)
end

--function WhoChannel:OnShowFriendsFrame()
--      --PanelTemplates_SetNumTabs(FriendsFrame, FriendsFrame.numTabs + 1);
--      --PanelTemplates_UpdateTabs(FriendsFrame);
--end


function WhoChannel:ParseMyGuild()
   local fullName, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, classe, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID
   local name
   --local GUID
   for i=1, GetNumGuildMembers() do
      --self:Print(GetGuildRosterInfo(i))
      --GUID = select(17, GetGuildRosterInfo(i))
      fullName, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, classe, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID = GetGuildRosterInfo(i)
      name = Ambiguate(fullName, "mail") -- wow classic
      self:AddToPlayersCache(GUID, classDisplayName, classe, "localizedRace", "englishRace", "sex", name, "realm",  "guildName", rankName, rankIndex, level)

      --self:AddPlayer(GUID)
   end
end

function WhoChannel:OnInitialize()
   self:Print("OnInitialize")
   do
      self:RegisterEvent("CHAT_MSG_CHANNEL_JOIN")
      self:RegisterEvent("CHANNEL_ROSTER_UPDATE")
      self:RegisterEvent("CHANNEL_COUNT_UPDATE")
      self:RegisterEvent("CHANNEL_FLAGS_UPDATED")
      self:RegisterEvent("CHAT_MSG_CHANNEL")
      self:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE")

      self.options = basic_options

      self.max_level = GetMaxPlayerLevel("player")
      self.channel_to_track_name = "loktar"
      self.channel_to_track_index = -1
      --self.updatePlayerListTimer = nil
      self.reportTimer = nil
      self.channel_found = false
      self.playerCount = 0
      self.owner = nil
   end
   self.classes_all_level = {
      [WARRIOR] = { count = 0},
      [MAGE] = { count = 0},
      [ROGUE] = { count = 0},
      [DRUID] = { count = 0},
      [HUNTER] = { count = 0},
      [SHAMAN] = { count = 0},
      [PRIEST] = { count = 0},
      [WARLOCK] = { count = 0},
      [PALADIN] = { count = 0},
   }

   self.classes_max_level = {
      [WARRIOR] = {},
      [MAGE] = {},
      [ROGUE] = {},
      [DRUID] = {},
      [HUNTER] = {},
      [SHAMAN] = {},
      [PRIEST] = {},
      [WARLOCK] = {},
      [PALADIN] = {},
   }

   self.player_cache = {
      count = 0,
      --[WARRIOR] = { count = 0},
      --[MAGE] = { count = 0},
      --[ROGUE] = { count = 0},
      --[DRUID] = { count = 0},
      --[HUNTER] = { count = 0},
      --[SHAMAN] = { count = 0},
      --[PRIEST] = { count = 0},
      --[WARLOCK] = { count = 0},
      --[PALADIN] = { count = 0},
   }

   self:ParseMyGuild()
end


function WhoChannel:OnEnable()
   self:Print("OnEnable")
end

function WhoChannel:OnDisable()
   self:Print("OnDisable")
   self:UnregisterEvent("CHAT_MSG_CHANNEL_JOIN")
   self:UnregisterEvent("CHANNEL_ROSTER_UPDATE")
   self:UnregisterEvent("CHANNEL_COUNT_UPDATE")
   self:UnregisterEvent("CHANNEL_FLAGS_UPDATED")
   self:UnregisterEvent("CHAT_MSG_CHANNEL")
   self:UnregisterEvent("CHAT_MSG_CHANNEL_LEAVE")
   self:CancelAllTimers()
   self.reportTimer = nil
end

