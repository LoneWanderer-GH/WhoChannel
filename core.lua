
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
  -- if not input or input:trim() == "" then
  --  LibStub("AceConfigDialog-3.0"):Open("WhoChannel")
  --else
  --  LibStub("AceConfigCmd-3.0").HandleCommand(WhoChannel, "wc", "WhoChannel", input)
  --end
end


function WhoChannel:OnInitialize()
   self:Print("OnInitialize")

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
end

function WhoChannel:OnEnable()
   self:Print("OnEnable")
end


local function playerDataTableToString(playersMap)
   local t = {}
   for name, p in pairs(playersMap) do
      if name ~= "count" then
         local class_color_str = format("|c%s", RAID_CLASS_COLORS[p.class].colorStr)
         tinsert(t, class_color_str .. name .. "("..p.level ..")")
      end
   end
   return table.concat( t, "|r, ")
end


function WhoChannel:ReportChanStatus()
   if self.playerCount <=0 then return end

   self:Print("--- Chan Status ---")
   self:Print("--- Total : " .. self.playerCount)
   for classEnglish, playersMap in pairs(self.classes_all_level) do
      local nb = playersMap.count
      local format_str = "%2d %s %-"..max_class_str_length.."s: %s" -- size it to max class name length
      local output

      if nb > 0 then
         local texture_path_str = texture_path_index[classEnglish] or "shit !"
         local s =playerDataTableToString(playersMap)
         -- table.concat( classList, ", ")
         -- self:Print(nb .. texture_path_str.. classEnglish .. " " .. s)
         output = format(format_str, nb, texture_path_str, localizedClasses[classEnglish], s)
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
      if self.reportTimer == nil then
         self:Print("Starting report timer")
         self.reportTimer = self:ScheduleRepeatingTimer("ReportChanStatus", 240  , "foo")
      end
   end
end


function WhoChannel:GetClassesStats()
   local current_count = select(5,GetChannelDisplayInfo(self.channel_to_track_index))
   if current_count == nil or self.playerCount == nil then
      --or current_count ~= self.playerCount then
      -- game not ready to tell us how many players in chan
      return
   end

   -- self:Print("Found ".. current_count .. " players in ["..self.channel_to_track_name.."]")
   for j=1, current_count, 1 do
      --self:Print("Player n° " .. j)
      --local name2, owner, moderator, muted, active, enabled = C_ChatInfo.GetChannelRosterInfo(target_channel_id, j)
      local _, _, _, guid = C_ChatInfo.GetChannelRosterInfo(self.channel_to_track_index, j)
      --self:Print("ChannelId=" .. target_channel_id .. " " .. name2)
      --local guid = UnitGUID(name2)
      if guid ~= nil then
         self:AddPlayer(guid)
         --local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(guid)
         --local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo(guid)
         ---- local inMyGuild = UnitIsInMyGuild(guid)
         --local level = UnitLevel(guid)

         --local p = {
         --   name = name,
         --   class = englishClass,
         --   localizedClass = localizedClass,
         --   guildName = guildName or "undefined",
         --   level = level or "undefined",
         --   guid = guid
         --}
         --if self.classes_all_level[englishClass][p.name] == nil then
         --   self.classes_all_level[englishClass][p.name] = p
         --end
      end
   end
   self:Print("Updating internal classes list status")
end

d
function WhoChannel:AddToPlayersCache(p)
end

function WhoChannel:GetFromPlayersCache(p)

end


--function WhoChannel:SetPlayerCount(channelIndex, count)
--   if count == nil or count < 0 then return end
--   if channelIndex == nil or channelIndex ~= self.channel_to_track_index then return end

--   if not self.channel_found then return end
--   self.playerCount = count
--   self:Print("PlayerCount in [ "..self.channel_to_track_name.." ] = [ "..self.playerCount.." ]")
--end

function WhoChannel:CHAT_MSG_CHANNEL(_, text, playerNameWithRealm, _, channelFullName, playerName2, _, _, channelDisplayIndex, channelBaseName)
   --self:Print("CHAT_MSG_CHANNEL - channelBaseName=".. channelBaseName .. " channelDisplayIndex=" ..channelDisplayIndex)
   self:SearchChannelIdentifiers(channelBaseName, channelDisplayIndex, nil)
   if self.channel_to_track_name == channelBaseName then
      -- do stuff
   end
end


function WhoChannel:AddPlayer(guid)
   self.playerCount = self.playerCount + 1
   --self:SetPlayerCount(self.channel_to_track_index, self.playerCount)
   local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(guid)

   if self.classes_all_level[englishClass][name] ~= nil then return end

   local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo(name)

   local level = UnitLevel(guid)
   if level == nil or level == 0 then
      level = "?"
   end
   local p = {
            name = name,
            class = englishClass,
            localizedClass = localizedClass,
            guildName = guildName or "undefined",
            level = level or "?",
            guid = guid
         }
   -- tinsert(self.classes_all_level[englishClass], p)
    self.classes_all_level[englishClass][p.name] = p
    self.classes_all_level[englishClass].count = self.classes_all_level[englishClass].count + 1
end

function WhoChannel:RemovePlayer(guid)
   self.playerCount = self.playerCount - 1
   --self:SetPlayerCount(self.channel_to_track_index, self.playerCount)
   local _, englishClass, _, _, _, name, _ = GetPlayerInfoByGUID(guid)
   self.classes_all_level[englishClass][name] = nil
   self.classes_all_level[englishClass].count = self.classes_all_level[englishClass].count - 1
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
   if not self.channel_found or not channelBaseName == self.channel_to_track_name then return end
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
   end
   self:SearchChannelIdentifiers(nil, nil, channelIndex)

   if not self.channel_found then return end
   if self.channel_to_track_index ~= channelIndex then return end
   --self:SetPlayerCount(channelIndex, count)
   self:GetClassesStats()
   self:ReportChanStatus()
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
   self:ReportChanStatus()
   self:Print("ASSERTION: computed player count=".. self.playerCount .. " event count=" .. new_count)
end

function WhoChannel:CHANNEL_FLAGS_UPDATED(_, channelIndex)
   -- self:Print("CHANNEL_FLAGS_UPDATED - channelIndex="..channelIndex)
   self:SearchChannelIdentifiers(nil, nil, channelIndex)
end

function WhoChannel:OnShowFriendsFrame()
      --PanelTemplates_SetNumTabs(FriendsFrame, FriendsFrame.numTabs + 1);
      --PanelTemplates_UpdateTabs(FriendsFrame);
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

--function WhoChannel:WhoCallBack(user, time)

--end

function WhoChannel:RegisterFriendFrameShow()
   --if FriendsFrame then
   --   FriendsFrame:HookScript("OnShow", self.OnShowFriendsFrame)
   --   self:CancelTimer(self.timerFriendFrame)
   --else
   --   self:Print("FriendsFrame not found yet")
   --end
end

function WhoChannel:Get_Channel_Player_List_Timer()
   self:Print("Get_Channel_Player_List_Timer triggered")
   self:Get_Channel_Player_List()
end


function WhoChannel:Get_Channel_Player_List()
   self:Print("Get_Channel_Player_List")
   if not self.channel_found then return end
   if self.channel_to_track_index == nil or self.channel_to_track_index == -1 then return end

   self:Print("self.channel_to_track_index="..self.channel_to_track_index)
   local count = select(5,GetChannelDisplayInfo(self.channel_to_track_index))
   if count ~= nil then
      self:Print("Found ".. count .. " players in ["..self.channel_to_track_name.."]")
      for j=1, count, 1 do
         --self:Print("Player n° " .. j)
         --local name2, owner, moderator, muted, active, enabled = C_ChatInfo.GetChannelRosterInfo(target_channel_id, j)
         local name2, owner, moderator, guid = C_ChatInfo.GetChannelRosterInfo(self.channel_to_track_index, j)
         --self:Print("ChannelId=" .. target_channel_id .. " " .. name2)
         --wholib:UserInfo(name2, opts)
         --userinfo , t = wholib:CachedUserInfo(name2)

         --local guid = UnitGUID(name2)
         if guid~=nil then
            local localizedClass, englishClass, localizedRace, englishRace, sex, name3, realm = GetPlayerInfoByGUID(guid)
            local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo(guid)
            if englishClass ~= nil then
               self:Print(name2 .. "-"..englishClass .. " - " .. (guildName or "no guild data"))
            end
         end
      end
   else
      self:Print("Count is unkown for required chan data ...")
   end
   self:Print("Get_Channel_Player_List------- END -----")
      self:Print("")
      self:Print("")
      self:Print("")
      self:Print("")
end
