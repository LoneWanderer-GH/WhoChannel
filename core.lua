
local WhoChannel = LibStub("AceAddon-3.0"):NewAddon("WhoChannel", "AceEvent-3.0", "AceConsole-3.0", "AceTimer-3.0", "AceConfigCmd-3.0", "AceConfigDialog-3.0")
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

function WhoChannel:SlashCommandProcessor(input)
   if not input or input:trim() == "" then
    LibStub("AceConfigDialog-3.0"):Open("WhoChannel")
  else
    LibStub("AceConfigCmd-3.0").HandleCommand(WhoChannel, "wc", "WhoChannel", input)
  end

end


function WhoChannel:OnInitialize()
   self:Print("OnInitialize")

   self:RegisterChatCommand("wc", "SlashCommandProcessor")

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
   self:RegisterEvent("CHAT_MSG_CHANNEL_JOIN")
   self:RegisterEvent("CHANNEL_ROSTER_UPDATE")
   self:RegisterEvent("CHANNEL_COUNT_UPDATE")
   self:RegisterEvent("CHANNEL_FLAGS_UPDATED")
   self:RegisterEvent("CHAT_MSG_CHANNEL")
   self:RegisterEvent("CHAT_MSG_CHANNEL_LEAVE")
end


local function playerDataTableToString(playerDataTable)
   local t = {}
   for _, p in ipairs(playerDataTable) do
      local class_color_str = format("|c%s", RAID_CLASS_COLORS[p.class].colorStr)
      tinsert(t, class_color_str .. p.name .. "("..p.level ..")")
   end
   return table.concat( t, "|r, ")
end


function WhoChannel:ReportChanStatus()
   if self.playerCount <=0 then return end

   self:Print("--- Chan Status ---")
   self:Print("--- Total : " .. self.playerCount)
   for classEnglish, classList in pairs(self.classes_all_level) do
      local nb = #classList
      local format_str = "%2d %s %"..max_class_str_length.."s: %s" -- size it to max class name length
      local output

      if nb > 0 then
         local texture_path_str = texture_path_index[classEnglish] or "shit !"
         local s =playerDataTableToString(classList)
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
                  --self:Print("Got channel display index or name -> found its name=".. current_chan_name .. " displayindex="..currentDisplayIndex.." absolute ID="..i)
         break;
      end
   end

   if self.channel_found then
      self:Print("Channel found")
      --self:Get_Channel_Player_List()
      --if self.updatePlayerListTimer == nil then
      --   self.updatePlayerListTimer = self:ScheduleRepeatingTimer("Get_Channel_Player_List_Timer", 30, "foo")
      --end
      --self:UnregisterEvent("CHAT_MSG_CHANNEL_JOIN")
      self:UnregisterEvent("CHANNEL_FLAGS_UPDATED")
      --self:UnregisterEvent("CHAT_MSG_CHANNEL_LEAVE")
      self:UnregisterEvent("CHANNEL_COUNT_UPDATE")
      if self.reportTimer == nil then
         self:Print("Starting report timer")
         self.reportTimer = self:ScheduleRepeatingTimer("ReportChanStatus", 30, "foo")
      end
   end

   --self:Print("Inputs: absolute index="..(L_channelIndex or "nil") .. " displayIndex="..(displayIndex or "nil") .. " no chan name="..(current_chan_name or "nil"))
   --if L_channelIndex ~= nil then
   --   -- we know the channel absolute index :)
   --   self:Print("Go an abslute index="..L_channelIndex)
   --   current_chan_name, _, _, currentDisplayIndex, count, _, category, _, _ = GetChannelDisplayInfo(L_channelIndex)
   --   --self:Print("Got channel absolute ID -> found its name ".. current_chan_name)
   --elseif displayIndex ~=nil or current_chan_name ~= nil then
   --   -- determine channel by its display index
   --   self:Print("Go a displayIndex="..(displayIndex or "nil") .. " or a chan name="..(current_chan_name or "nil"))
   --   local channelCount = GetNumDisplayChannels()
   --   for L_channelIndex=0, channelCount, 1 do
   --      current_chan_name, _, _, currentDisplayIndex, count, _, category, _, _ = GetChannelDisplayInfo(L_channelIndex)
   --      if (displayIndex ~=nil and displayIndex == currentDisplayIndex) or (current_chan_name ~=nil and current_chan_name == channelName) then
   --         --self:Print("Got channel display index or name -> found its name=".. current_chan_name .. " displayindex="..currentDisplayIndex.." absolute ID="..i)
   --         break;
   --      end
   --   end
   --else
   --   -- wtf
   --end

   --if L_channelIndex == nil then
   --   self:Print("WTF !!!")
   --   self:Print("channelName="..(channelName or "nil").." displayIndex="..(displayIndex or "nil") .." channelIndex="..(channelIndex or "nil"))
   --end
   ----self:Print("SearchChannelIdentifiers - chan name is " .. current_chan_name)
   --if self.channel_to_track_name == current_chan_name then
   --   self:Print("SearchChannelIdentifiers - chan name is the one we want, index is ".. (L_channelIndex or "nil"))
   --   self.channel_to_track_index = L_channelIndex
   --   self:Get_Channel_Player_List()
   --   if self.updatePlayerListTimer == -1 then
   --      self.updatePlayerListTimer = self:ScheduleRepeatingTimer("Get_Channel_Player_List_Timer", 30, "foo")
   --   end
   --end
   --self:Print("EVERYTHING WENT FINE")
   --self:Print("--------------------------------------------------")
   --self:Print("")
   --self:Print("")
   --self:Print("")
   --self:Print("")
--else
--   local s = "no timer"
--   if self.updatePlayerListTimer ~=nil then
--      s = "yes has timer"
--   end
--   self:Print("WTF ???? (timer exists ?".. s .." & channel_to_track_index="..(self.channel_to_track_index or "no channel yet"))
--end
end


function WhoChannel:GetClassesStats()
   local current_count = select(5,GetChannelDisplayInfo(self.channel_to_track_index))
   if current_count == nil or self.playerCount == nil or current_count ~= self.playerCount then
      -- game not ready to tell us how many players in chan
      -- self:Print("Counting disagree ? Last event said ".. self.playerCount .." current GetChannelDisplayInfo says "..current_count)
      return
   end

   local classes_all_level = {
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
   --local classes_max_level = {
   --   [WARRIOR] = {},
   --   [MAGE] = {},
   --   [ROGUE] = {},
   --   [DRUID] = {},
   --   [HUNTER] = {},
   --   [SHAMAN] = {},
   --   [PRIEST] = {},
   --   [WARLOCK] = {},
   --   [PALADIN] = {},
   --}
   -- self:Print("Found ".. current_count .. " players in ["..self.channel_to_track_name.."]")
   for j=1, current_count, 1 do
      --self:Print("Player n° " .. j)
      --local name2, owner, moderator, muted, active, enabled = C_ChatInfo.GetChannelRosterInfo(target_channel_id, j)
      local _, _, _, guid = C_ChatInfo.GetChannelRosterInfo(self.channel_to_track_index, j)
      --self:Print("ChannelId=" .. target_channel_id .. " " .. name2)
      --wholib:UserInfo(name2, opts)
      --userinfo , t = wholib:CachedUserInfo(name2)

      --local guid = UnitGUID(name2)
      if guid ~= nil then
         local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(guid)
         local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo(guid)
         -- local inMyGuild = UnitIsInMyGuild(guid)
         local level = UnitLevel(guid)

         local p = {
            name = name,
            class = englishClass,
            localizedClass = localizedClass,
            guildName = guildName or "undefined",
            level = level or "undefined",
            guid = guid
         }
         --local p = name
         tinsert(classes_all_level[englishClass], p)
         --if englishClass ~= nil then
         --   self:Print(name2 .. "-"..englishClass .. " - " .. (guildName or "no guild data"))
         --end
      end
   end
   --for classEnglish, classList in pairs(self.classes_all_level) do
   --   local nb = #classList
   --   if nb > 0 then
   --      local texture_path_str = texture_path_index[classEnglish] or "shit !"
   --      local s =playerDataTableToString(classList)
   --      -- table.concat( classList, ", ")
   --      self:Print(nb .. texture_path_str.. classEnglish .. " " .. s)
   --   end
   --end
   self:Print("Updating internal classes list status")
   self.classes_all_level = classes_all_level
end


function WhoChannel:SetPlayerCount(channelIndex, count)
   if count == nil or count < 0 then return end
   if channelIndex == nil or channelIndex ~= self.channel_to_track_index then return end

   if not self.channel_found then return end
   self.playerCount = count
   self:Print("PlayerCount in [ "..self.channel_to_track_name.." ] = [ "..self.playerCount.." ]")
   --self:GetClassesStats()
   --self:ReportChanStatus()
end

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
   local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo(guid)

   local level = UnitLevel(guid)
   local p = {
            name = name,
            class = englishClass,
            localizedClass = localizedClass,
            guildName = guildName or "undefined",
            level = level or "undefined",
            guid = guid
         }
   tinsert(self.classes_all_level[englishClass], p)
end

function WhoChannel:RemovePlayer(guid)
   self.playerCount = self.playerCount - 1
   --self:SetPlayerCount(self.channel_to_track_index, self.playerCount)
   local localizedClass, englishClass, localizedRace, englishRace, sex, name3, realm = GetPlayerInfoByGUID(guid)
   --local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo(guid)

   --local level = UnitLevel(guid)
   --local p = {
   --         name = name,
   --         class = englishClass,
   --         localizedClass = localizedClass,
   --         guildName = guildName or "undefined",
   --         level = level or "undefined"
   --      }
   -- tinsert(self.classes_all_level[englishClass], p)
   local i_to_remove
   for i, playerData in pairs(self.classes_all_level[englishClass]) do
      if playerData.guid == guid then
         i_to_remove = i
         break
      end
   end
   tremove(self.classes_all_level[englishClass], i_to_remove)
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
   self:SetPlayerCount(channelIndex, count)
   self:GetClassesStats()
   self:ReportChanStatus()
end

function WhoChannel:CHANNEL_COUNT_UPDATE(_, channelIndex, new_count)
   -- self:Print("CHANNEL_COUNT_UPDATE - channelIndex="..channelIndex)
   if self.channel_found and self.channel_to_track_index == channelIndex then
      self:Print("CHANNEL_ROSTER_UPDATE for "..self.channel_to_track_name)
   end
   self:SearchChannelIdentifiers(nil, nil, channelIndex)
   self:SetPlayerCount(channelIndex, new_count)
   self:GetClassesStats()
   self:ReportChanStatus()
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
