-- Globals
-- ADR = {} -- initialized in language file (en)
--ADR.loc = {} -- initialized in language file (en)
ADR.isAddonLoaded = false
ADR.appName = "ArkaysDonationReminder"
ADR.displayedAppName = "|cd5b526Arkays|r Donation Reminder"
ADR.version = "" -- will be set according to the the verion in manifest file
ADR.author = "DeadSoon"
ADR.website = "https://www.esoui.com/downloads/info2679-ArkaysDonationReminder.html"
ADR.postponed = false
ADR.chatBegin = "[ADR]: "
ADR.colors = {
	bronze = "|cAD8A56",
	silver = "|cD7D7D7",
	gold = "|cC9B037",
}
ADR.timestampLastWeekStart = 0
ADR.timestampCurrentWeekStart = 0
ADR.timestampNextWeekStart = 0
ADR.donationQueue = {}
ADR.donationDelay = 1800

ADR.donationConfigurations = {
	[1] = {
		days = 7,
		amount = 1115,
		color = ADR.colors.bronze,
		},
	[2] = {
		days = 7,
		amount = 2230,
		color = ADR.colors.silver,
		},
	[3] = {
		days = 7,
		amount = 3345,
		color = ADR.colors.gold,
		},
	[4] = {
		days = 30,
		amount = 4460,
		color = ADR.colors.bronze,
		},
	[5] = {
		days = 30,
		amount = 8920,
		color = ADR.colors.silver,
		},
	[6] = {
		days = 30,
		amount = 13380,
		color = ADR.colors.gold,
		},
	}

-- Arkays guilds (for guild note)
ADR.arkaysGuilds = {141844, 20465, 634370, 635976, 439872} -- Handelshaus, Handelsbund, Segen, Einrichtungshaus, Handelshof

ADR.dropdownConfChoices = {ADR.loc.dropdownConfDisabled, ADR.loc.dropdownConf1, ADR.loc.dropdownConf2, ADR.loc.dropdownConf3, ADR.loc.dropdownConf4, ADR.loc.dropdownConf5, ADR.loc.dropdownConf6, ADR.loc.dropdownConfCustom}
ADR.dropdownConfValues = {0, 1, 2, 3, 4, 5, 6, 7}

ADR.dropdownGuildChoices = {ADR.loc.dropdownGuildDisabled}
ADR.dropdownGuildValues = {0}
for i = 1, GetNumGuilds() do
	table.insert(ADR.dropdownGuildChoices, GetGuildName(GetGuildId(i)))
	table.insert(ADR.dropdownGuildValues, GetGuildId(i))
end

------------------------------------
-- initialization functions
local function playerInitAndReady()
    zo_callLater(function() ADR.initialize() end, 2000)
	EVENT_MANAGER:UnregisterForEvent(ADR.appName, EVENT_PLAYER_ACTIVATED)
end


local function onAddonLoaded(eventCode, addonName)
    if (ADR.appName ~= addonName) then return end
	
	--Read the addon version from the addon's txt manifest file tag ##AddOnVersion
	local function GetAddonVersionFromManifest()
		local addOn_Name
		local ADDON_MANAGER = GetAddOnManager()
		for i = 1, ADDON_MANAGER:GetNumAddOns() do
			addOn_Name = ADDON_MANAGER:GetAddOnInfo(i)
			if addOn_Name == ADR.appName then
				return ADDON_MANAGER:GetAddOnVersion(i)
			end
		end
		return -1
		-- Fallback: return the -1 version if AddOnManager was not read properly
	end
	--Set the version dynamically
	ADR.version = tostring(GetAddonVersionFromManifest())

	-- defaults
    ADR.defaults = {
		firstStart = true,
		infoMultipleProfiles = false,			-- not read yet
		onlyNotification = false,
		lastNotificationTimestamp = 1601510400,  -- just a date in the past to initialize (2020/10/01)
		
		-- donation sums of the guilds (goldDepositSum_lastWeek[guildId] -> donation sum of the guild in last week)
		displayDonationSum = false, -- includes donations + fees
		goldDepositSum_lastWeek = {},
		goldDepositSum_currentWeek = {},
		newestBankEventId = {},
		oldestBankEventId = {},
		guildTaxSum_lastWeek = {},
		guildTaxSum_currentWeek = {},
		newestStoreEventId = {},
		oldestStoreEventId = {},
		
		profiles = {
			[1] = {
				guildId = 0,
				configuration = 0,
				customConfiguration = {
					days = 7,
					amount = 5000,
					color = ADR.colors.gold,
					},
				lastDonation = {}
			},
			[2] = {
				guildId = 0,
				configuration = 0,
				customConfiguration = {
					days = 7,
					amount = 5000,
					color = ADR.colors.gold,
					},
				lastDonation = {}
			},
			[3] = {
				guildId = 0,
				configuration = 0,
				customConfiguration = {
					days = 7,
					amount = 5000,
					color = ADR.colors.gold,
					},
				lastDonation = {}
			},
			[4] = {
				guildId = 0,
				configuration = 0,
				customConfiguration = {
					days = 7,
					amount = 5000,
					color = ADR.colors.gold,
					},
				lastDonation = {}
			},
			[5] = {
				guildId = 0,
				configuration = 0,
				customConfiguration = {
					days = 7,
					amount = 5000,
					color = ADR.colors.gold,
					},
				lastDonation = {}
			},
		}
    }
	
	-- February 2022
	-- change savedVars structure to allow support for multiple guilds
	local exSavedVars = ZO_SavedVars:NewAccountWide("ArkaysDonationReminder_SV", 1, nil, nil, nil)
	ADR.savedVars = ZO_SavedVars:NewAccountWide("ArkaysDonationReminder_SV", 2, nil, ADR.defaults, GetWorldName())
	
	if type(exSavedVars.firstStart) == "boolean" then
		-- copy existing savedVars to new structure
		ADR.savedVars.firstStart = false
		ADR.savedVars.onlyNotification = exSavedVars.onlyNotification
		ADR.savedVars.lastNotificationTimestamp = exSavedVars.lastNotificationTimestamp
		ADR.savedVars.displayDonationSum = exSavedVars.displayDonationSum
		
		-- copy existing profile into first slot
		ADR.savedVars.profiles[1].guildId = exSavedVars.guildId
		ADR.savedVars.profiles[1].configuration = exSavedVars.configuration
		ADR.savedVars.profiles[1].customConfiguration = exSavedVars.customConfiguration
		-- retreive only last donation
		ADR.savedVars.profiles[1].lastDonation = {exSavedVars.donations[#exSavedVars.donations]}
		
		-- finally, clear/delete existing/old savedVars
		-- reset by increasing version
		exSavedVars = ZO_SavedVars:NewAccountWide("ArkaysDonationReminder_SV", 2, nil, nil, nil)
	end
	
	EVENT_MANAGER:RegisterForEvent(ADR.appName, EVENT_PLAYER_ACTIVATED, playerInitAndReady)	
end


function ADR.initialize()
	-- build settings menu
	ADR.initializeSettingsMenu()
	-- register for events
	EVENT_MANAGER:RegisterForEvent(ADR.appName, EVENT_OPEN_GUILD_BANK, ADR.checkForDonation)
	--EVENT_MANAGER:RegisterForEvent(ADR.appName, EVENT_GUILD_BANK_SELECTED, ADR.onGuildBankSelected)
	
	-- register chat commands
	ADR.registerChatCommands()
	
	-- check for notification
	ADR.checkForNotification()
	
	if ADR.savedVars.displayDonationSum then
		-- first, generate two text controls in guilds menus (history tab)
		ADR.createTextControlsGuildHistory()
		
		-- process guild events and update and display income for current and last week
		-- event below is triggered always when receiving guild events. However, after reloading the data remains (will not again requested)
		ADR.displayGuildsIncome()
	
		-- swap values in guild history tab depending on selected guild
		CALLBACK_MANAGER:RegisterCallback("OnGuildSelected", function()
			ADR.setIncomeText(GUILD_SELECTOR.guildId)
		end)
		
		-- listen for new data (especially if user manually or other addons (MM or LibHistoire) request more data)
		EVENT_MANAGER:RegisterForEvent(ADR.appName, EVENT_GUILD_HISTORY_RESPONSE_RECEIVED, ADR.newDataReceived)
	end
end


function ADR.newDataReceived(eventCode, guildId, category)
	--d("ADR: New Data recieved!")
	if category == GUILD_HISTORY_BANK or category == GUILD_HISTORY_STORE then
		--d("ADR: New relevant History Data received!")
		
		-- process guild events and update and display income for current and last week
		ADR.displayGuildsIncome()
	end
end


function ADR.initializeSettingsMenu()
	local LAM = LibAddonMenu2
	
	local panelData = {
		type 				= 'panel',
		name 				= ADR.appName,
		displayName 		= ADR.displayedAppName,
		author 				= ADR.author,
		version 			= ADR.version,
		website             = ADR.website,
	--	feedback            = "",
		registerForRefresh  = true,
		registerForDefaults = true,
       }
	
	ADR.SettingsPanel = LAM:RegisterAddonPanel(ADR.appName .. "Options", panelData) -- for quick access
	
	-- build 5 submenus with settings in it
	local profileSubmenus = {}
	for i=1, #ADR.defaults.profiles do
		local submenu = {
			type = "submenu",
			name = ADR.loc.containerProfile .. " " .. tostring(i),
			controls = {
				{
					type = "dropdown",
					name = ADR.loc.guildSelectionName,
					tooltip = ADR.loc.guildSelectionTooltip,
					choices = ADR.dropdownGuildChoices,
					choicesValues = ADR.dropdownGuildValues,
					getFunc = function() return ADR.savedVars.profiles[i].guildId end,
					setFunc = function(value) ADR.savedVars.profiles[i].guildId = value end,
					disabled = function() return ADR.savedVars.onlyNotification end,
					default = ADR.defaults.profiles[i].guildId,
				},
				{
					type = "dropdown",
					name = ADR.loc.configurationName,
					tooltip = ADR.loc.configurationTooltip,
					choices = ADR.dropdownConfChoices,
					choicesValues = ADR.dropdownConfValues,
					getFunc = function() return ADR.savedVars.profiles[i].configuration end,
					setFunc = function(value) ADR.savedVars.profiles[i].configuration = value end,
					disabled = function() return (ADR.savedVars.profiles[i].guildId == ADR.defaults.profiles[i].guildId) or ADR.savedVars.onlyNotification end, -- disabled if no guild is set (default) or onlyNotification is active
					default = ADR.defaults.profiles[i].configuration,
				},
				{
					type = "button",
					name = ADR.loc.printLastDonationName,
					tooltip = ADR.loc.printLastDonationTooltip,
					func = function() ADR.printLastDonation(i) end,
					width = "half",
				},
				{
					type = "header",
					name = ADR.loc.headerCustomConf,
				},
				{
					type = "slider",
					name = ADR.loc.customConfDaysName,
					tooltip = ADR.loc.customConfDaysTootlip,
					min = 1,
					max = 60,
					getFunc = function() return ADR.savedVars.profiles[i].customConfiguration.days end,
					setFunc = function(value) ADR.savedVars.profiles[i].customConfiguration.days = value end,
					disabled = function() return (ADR.savedVars.profiles[i].guildId == ADR.defaults.profiles[i].guildId or ADR.savedVars.profiles[i].configuration ~= 7 or ADR.savedVars.onlyNotification) end,
					default = ADR.defaults.profiles[i].customConfiguration.days,
				},
				{
					type = "slider",
					name = ADR.loc.customConfAmountName,
					tooltip = ADR.loc.customConfAmountTootlip,
					min = 100,
					max = 100000,
					getFunc = function() return ADR.savedVars.profiles[i].customConfiguration.amount end,
					setFunc = function(value) ADR.savedVars.profiles[i].customConfiguration.amount = value end,
					disabled = function() return (ADR.savedVars.profiles[i].guildId == ADR.defaults.profiles[i].guildId or ADR.savedVars.profiles[i].configuration ~= 7 or ADR.savedVars.onlyNotification) end,
					default = ADR.defaults.profiles[i].customConfiguration.amount,
				},
			}
		}
		table.insert(profileSubmenus, submenu)
	end
		
	local optionsData1 = {
	    {
            type = "description",
            text = ADR.loc.introDescription,
        }
	}
	
	local optionsData2 = {
		{
            type = "header",
            name = ADR.loc.headerAdvanced,
        },
		{
            type = "checkbox",
            name = ADR.loc.onlyNotification,
            tooltip = ADR.loc.onlyNotificationTooltip,
            getFunc = function() return ADR.savedVars.onlyNotification end,
			setFunc = function(value) ADR.savedVars.onlyNotification = value end,
			default = ADR.defaults.onlyNotification,
        },
		{
            type = "checkbox",
            name = ADR.loc.displayDonationSum,
            tooltip = ADR.loc.displayDonationSumTooltip,
            getFunc = function() return ADR.savedVars.displayDonationSum end,
			setFunc = function(value) ADR.savedVars.displayDonationSum = value end,
			default = ADR.defaults.displayDonationSum,
			requiresReload = true,
        },
	}
	
	local optionsDataSum = {}
	-- add first part
	for _, options in ipairs(optionsData1) do
		table.insert(optionsDataSum, options)
	end
	-- add profile submenus
	for _, submenu in ipairs(profileSubmenus) do
		table.insert(optionsDataSum, submenu)
	end
	-- add ending part
	for _, options in ipairs(optionsData2) do
		table.insert(optionsDataSum, options)
	end
	
	LAM:RegisterOptionControls(ADR.appName .. "Options", optionsDataSum)
end


function ADR.registerChatCommands()
	--SLASH_COMMANDS["/adr/last"] = ADR.printLastDonation(1)
end
------------------------------------


-- triggered on guild bank open
-- check for planned donations
-- create list of all donation actions to execute in queue
function ADR.checkForDonation()
	-- clear donation list
	ADR.donationQueue = {}
	-- check all profiles
	for i=1, #ADR.savedVars.profiles do
		if ADR.savedVars.profiles[i].guildId ~= 0 and ADR.savedVars.profiles[i].configuration ~= 0 and IsPlayerInGuild(ADR.savedVars.profiles[i].guildId) then
			local configuration
			if ADR.savedVars.profiles[i].configuration == 7 then
				-- use custom configuration
				configuration = ADR.savedVars.profiles[i].customConfiguration
			else
				-- use predefined configuration
				configuration = ADR.donationConfigurations[ADR.savedVars.profiles[i].configuration]
			end
			
			local lastDonationTime = 0 
			local lastDonationEntry = ADR.savedVars.profiles[i].lastDonation[#ADR.savedVars.profiles[i].lastDonation]
			
			if lastDonationEntry and lastDonationEntry.timestamp then
				lastDonationTime = lastDonationEntry.timestamp
			end
			
			local daysLeft = math.floor(GetDiffBetweenTimeStamps(GetTimeStamp(), lastDonationTime)/86400) -- in days
			if daysLeft >= configuration.days and not ADR.postponed then
				-- add donation to global queue
				table.insert(ADR.donationQueue, {profileIndex=i, lastDonationTime=lastDonationTime, daysLeft=daysLeft, configuration=configuration})
				--zo_callLater(function() ADR.showDonationDialog(profileIndex, lastDonationTime, daysLeft, configuration) end, 500)
			end	
		end
	end
	-- show donation dialogs
	ADR.processDonationQueue()
end


-- process global donation queue
-- executes all donations one by one
-- this function is called again after the transaction
function ADR.processDonationQueue()
	-- retreive frist element
	local donation = table.remove(ADR.donationQueue, 1)
	if donation then
		-- execute donation
		zo_callLater(function() ADR.showDonationDialog(donation.profileIndex, donation.lastDonationTime, donation.daysLeft, donation.configuration) end, 400)
	end
end


-- show donation dialog
function ADR.showDonationDialog(profileIndex, lastDonationTime, daysLeft, configuration)
	-- setup dialog
	local dialogName = "ExecuteDonation"
	local guildId = ADR.savedVars.profiles[profileIndex].guildId
	-- select body text
	local title = ADR.loc.executeDonationTitle
	local body = string.format(ADR.loc.executeDonationBody, daysLeft) .. "\n\n" .. ADR.formatGold(configuration.amount) .. " Gold -> " .. GetGuildName(guildId)
	if lastDonationTime == 0 then
		-- first donation
		body = string.format(ADR.loc.executeDonationBodyFirstTimeBody, ADR.appName) .. "\n\n" .. ADR.formatGold(configuration.amount) .. " Gold -> " .. GetGuildName(guildId)
	end
	
	-- show the dialog
	ADR.showDialogSimple(dialogName, title, body, function() ADR.executeDonation(profileIndex, configuration) end, function() ADR.postponeDonation() end)
end


------------------------

-- register and show basic dialogs
function ADR.showDialogSimple(dialogName, dialogTitle, dialogBody, callbackYes, callbackNo)
	local dialogInfo = {
		canQueue = true,
		title = {text=dialogTitle},
		mainText = {align=TEXT_ALIGN_LEFT, text=dialogBody},
	}
	
	if callbackYes or callbackNo then
		dialogInfo.buttons = {
			{
				text = SI_DIALOG_CONFIRM,
				keybind = "DIALOG_PRIMARY",
				callback = callbackYes,
			},
			{
				text = SI_DIALOG_CANCEL,
				keybind = "DIALOG_NEGATIVE",
				callback = callbackNo,
			},
		}
	else
		-- show only one button if both callbacks are nil
		dialogInfo.buttons = {
			{
				text = SI_DIALOG_CLOSE,
				keybind = "DIALOG_NEGATIVE",
			},
		}
	end
	
	return ADR.showDialogCustom(dialogName, dialogInfo)
end


-- register and show custom dialogs with given dialogInfo
function ADR.showDialogCustom(dialogName, dialogInfoObject)
	local dialogInfo = dialogInfoObject
	
	-- register dialog globally
	local globalDialogName = ADR.appName .. dialogName
	
	ESO_Dialogs[globalDialogName] = dialogInfo
	dialogReference = ZO_Dialogs_ShowDialog(globalDialogName)
	return globalDialogName, dialogReference
end

------------------------


-- execute donation
-- show loading dialog for the same time as the execution delay
function ADR.executeDonation(profileIndex, configuration)
	-- build dialogInfo object
	dialogInfo = {canQueue=true, showLoadingIcon=ZO_Anchor:New(BOTTOM, ZO_Dialog1Text, BOTTOM, 0, 40), title = {text=ADR.loc.loadingDonationTitle}, mainText = {align=TEXT_ALIGN_CENTER, text=ADR.loc.loadingDonationBody}, buttons = {}}
	local globalDialogName = ADR.showDialogCustom("LoadingDonation", dialogInfo)
	-- release after delay
	zo_callLater(function() ZO_Dialogs_ReleaseDialog(globalDialogName) end, ADR.donationDelay)
	
	local guildId = ADR.savedVars.profiles[profileIndex].guildId
	-- switch to correct guild
	if GetSelectedGuildBankId() ~= guildId then
		SelectGuildBank(guildId)
	end
	
	zo_callLater(function()
		-- execute donation
		TransferCurrency(CURT_MONEY, configuration.amount, CURRENCY_LOCATION_CHARACTER, CURRENCY_LOCATION_GUILD_BANK)
		-- print info to chat
		d(ADR.chatBegin .. ADR.loc.donationExecuted .. GetGuildName(guildId) .. " (" .. ADR.formatGold(configuration.amount) .. " Gold)")
		-- check queue for another donation
		ADR.processDonationQueue()
	
		-- save donation
		local newEntry = {}
		newEntry.timestamp = GetTimeStamp()
		newEntry.guildId = guildId
		newEntry.amount = configuration.amount
		--table.insert(ADR.savedVars.profiles[profileIndex].lastDonation, newEntry)
		-- save only last donation
		ADR.savedVars.profiles[profileIndex].lastDonation = {newEntry}
		
		-- add info to guild note (Arkays guilds only)
		if ADR.hasValue(ADR.arkaysGuilds, guildId) then
			ADR.addInfoToMemberNote(guildId, configuration)
		end
		
		-- request prioritized saving of the savedVars
		GetAddOnManager():RequestAddOnSavedVariablesPrioritySave(ADR.appName)
	end, ADR.donationDelay)
end


-- for Arkays guilds only: add guild note on first donation (if not already added)
function ADR.addInfoToMemberNote(guildId, configuration)
	local memberIndex = GetPlayerGuildMemberIndex(guildId)
	local _, existingNote = GetGuildMemberInfo(guildId, memberIndex)
	if not memberIndex or not existingNote then return end
	
	local note = ""
	local donationDate = GetDateStringFromTimestamp(GetTimeStamp())
	local amount = configuration.amount
	
	-- build note according to the configuration
	--local texture = "|t32:32:esoui/art/currency/currency_gold_32.dds|t"
	--local texture = "|t32:32:esoui/art/currency/currency_telvar_32.dds|t"
	
	local textToAdd = ADR.displayedAppName .. ":\n" .. configuration.color .. "Edler Spender\n(" .. donationDate .. " " .. ADR.formatGold(amount) .. " G)"
	
	-- check if ADR note is already there (replace or append)
	local startPosition, endPosition = string.find(existingNote, ADR.displayedAppName)
	if not startPosition then
		note = existingNote .. "\n\n" .. textToAdd
	else
		note = string.sub(existingNote, 1, startPosition-1) .. textToAdd
	end
	
	SetGuildMemberNote(guildId, memberIndex, note)
end


-- postpone donation -> block dialog until next reload
function ADR.postponeDonation()
	ADR.postponed = true
end


-- output only last donation of a profile
function ADR.printLastDonation(profileIndex)
	local numLastDonations = #ADR.savedVars.profiles[profileIndex].lastDonation
	if numLastDonations >= 1 then
		local lastEntry = ADR.savedVars.profiles[profileIndex].lastDonation[numLastDonations]
		local dateString = GetDateStringFromTimestamp(lastEntry.timestamp)
		d(ADR.chatBegin .. dateString .. ": " .. ADR.formatGold(lastEntry.amount) .. " Gold -> " .. GetGuildName(lastEntry.guildId))
	end
end


-- checks for any notification
-- display notification after interval + 1 day after last donation
function ADR.checkForNotification()
	-- check for first start
	local LAM = LibAddonMenu2
	if ADR.savedVars.firstStart then
		-- show setup info dialog
		ADR.showDialogSimple("InitialSetup", ADR.displayedAppName, ADR.loc.initialSetupBody, function() LAM:OpenToPanel(ADR.SettingsPanel) ADR.savedVars.firstStart = false ADR.savedVars.infoMultipleProfiles = true end, nil)
		return
	elseif not ADR.savedVars.infoMultipleProfiles then
		-- show info dialog that ADR now supports multiple profiles
		ADR.showDialogSimple("InfoMultipleProfiles", ADR.displayedAppName, ADR.loc.infoMultipleProfilesBody, function() LAM:OpenToPanel(ADR.SettingsPanel) ADR.savedVars.infoMultipleProfiles = true end, function() ADR.savedVars.infoMultipleProfiles = true end)
	end
	
	-- check if all profiles are valid (may the user leaved a guild)
	for i=1, #ADR.savedVars.profiles do
		local guildId = ADR.savedVars.profiles[i].guildId
		if guildId ~= 0 and not IsPlayerInGuild(guildId) then
			-- disable profile
			ADR.savedVars.profiles[i].guildId = 0
		end
	end
	
	-- check for donation notifications
	if ADR.savedVars.onlyNotification then
		-- if only notification is active
		local lastNotification = ADR.savedVars.lastNotificationTimestamp
		local daysLeft = math.floor(GetDiffBetweenTimeStamps(GetTimeStamp(), lastNotification)/86400)
		if daysLeft > 7 then
			-- show dialog and save current time
			zo_callLater(function()
				CENTER_SCREEN_ANNOUNCE:AddMessage(0, CSA_CATEGORY_LARGE_TEXT, SOUNDS.LEVEL_UP, ADR.loc.reminderTitel, ADR.loc.reminderBodyOnlyNotification, nil, "EsoUI/Art/Achievements/achievements_iconBG.dds", nil, nil, 10000)
			end, 10000)
			ADR.savedVars.lastNotificationTimestamp = GetTimeStamp()
		end
	else
		-- go over all profiles and check if any has expired "cooldown"
		local showNotification = false
		local maxDaysLeft = 0	-- maximum of the daysLeft of the notifications
		for i=1, #ADR.savedVars.profiles do
			if ADR.savedVars.profiles[i].guildId ~= 0 and ADR.savedVars.profiles[i].configuration ~= 0 and IsPlayerInGuild(ADR.savedVars.profiles[i].guildId) then
				local configuration
				if ADR.savedVars.profiles[i].configuration == 7 then
					-- use custom configuration
					configuration = ADR.savedVars.profiles[i].customConfiguration
				else
					-- use predefined configuration
					configuration = ADR.donationConfigurations[ADR.savedVars.profiles[i].configuration]
				end
				-- check time
				local lastDonationEntry = ADR.savedVars.profiles[i].lastDonation[#ADR.savedVars.profiles[i].lastDonation]
				if lastDonationEntry then
					local daysLeft = math.floor(GetDiffBetweenTimeStamps(GetTimeStamp(), lastDonationEntry.timestamp)/86400)
					if daysLeft >= (configuration.days + 1) then
						showNotification = true
						if daysLeft > maxDaysLeft then
							-- update max days left
							maxDaysLeft = daysLeft
						end
					end
				end
			end
		end
		-- check if any profile triggers notification
		if showNotification then
			zo_callLater(function()
				CENTER_SCREEN_ANNOUNCE:AddMessage(0, CSA_CATEGORY_LARGE_TEXT, SOUNDS.LEVEL_UP, ADR.loc.reminderTitel, string.format(ADR.loc.reminderBody, maxDaysLeft), nil, "EsoUI/Art/Achievements/achievements_iconBG.dds", nil, nil, 10000)
			end, 10000)
		end
	end
end


function ADR.hasValue(tab, val)
	if type(tab) == "table" then
		for index, value in pairs(tab) do
			if value == val then
				return true
			end
		end
	end
    return false
end


-- displays the revenue of the guilds (for each guild)
function ADR.displayGuildsIncome()
	local numGuilds = GetNumGuilds()
	if numGuilds < 1 then return end
	
	-- calculate last and current week start
	ADR.calculatetimestampCurrentWeekStart()
	
	-- for each guild, calculate income for last and current week
	for i=1, numGuilds do
		local guildId = GetGuildId(i)
		-- check for initialization
		ADR.initializeIncomeValues(guildId)
		-- update income of last and current week and store in savedVars
		ADR.processGuildEvents(guildId)
	end
	
	-- display values for current selected guild
	ADR.setIncomeText(GUILD_SELECTOR.guildId)
end


-- check if all values are initialized and initialize them if necessary
function ADR.initializeIncomeValues(guildId)
	-- donations
	if ADR.savedVars.goldDepositSum_currentWeek[guildId] == nil then
		ADR.savedVars.goldDepositSum_currentWeek[guildId] = 0
	end
	if ADR.savedVars.goldDepositSum_lastWeek[guildId] == nil then
		ADR.savedVars.goldDepositSum_lastWeek[guildId] = 0
	end
	if ADR.savedVars.newestBankEventId[guildId] == nil then
		ADR.savedVars.newestBankEventId[guildId] = 0
	end
	if ADR.savedVars.oldestBankEventId[guildId] == nil then
		ADR.savedVars.oldestBankEventId[guildId] = 0
	end
	
	-- guild tax / fees that go to guild bank
	if ADR.savedVars.guildTaxSum_currentWeek[guildId] == nil then
		ADR.savedVars.guildTaxSum_currentWeek[guildId] = 0
	end
	if ADR.savedVars.guildTaxSum_lastWeek[guildId] == nil then
		ADR.savedVars.guildTaxSum_lastWeek[guildId] = 0
	end	
	if ADR.savedVars.newestStoreEventId[guildId] == nil then
		ADR.savedVars.newestStoreEventId[guildId] = 0
	end
	if ADR.savedVars.oldestStoreEventId[guildId] == nil then
		ADR.savedVars.oldestStoreEventId[guildId] = 0
	end
end


-- create text control for last and for current week in guild history window
function ADR.createTextControlsGuildHistory()
	-- font
	local fontSize = 22
	local fontStyle = ZoFontGame:GetFontInfo()
	local fontWeight = "soft-shadow-thin"
	local font = string.format("%s|$(KB_%s)|%s", fontStyle, fontSize, fontWeight)
	
	local parent = GUILD_HISTORY.control
	
	-- last week
	ADR.guildHistoryTextControl_lastWeek = WINDOW_MANAGER:CreateControl(nil, parent, CT_LABEL)
	ADR.guildHistoryTextControl_lastWeek:SetAnchor(TOPRIGHT, parent, TOPRIGHT, -300, 10)
	ADR.guildHistoryTextControl_lastWeek:SetFont(font)
	ADR.guildHistoryTextControl_lastWeek:SetText("")
	-- tooltip text
	ADR.guildHistoryTextControl_lastWeek.tooltipText = ""
	-- tooltip handler
	ADR.guildHistoryTextControl_lastWeek:SetHandler("OnMouseEnter", function(self)
		ZO_Tooltips_ShowTextTooltip(self, BOTTOM, self.tooltipText)
	end)
	ADR.guildHistoryTextControl_lastWeek:SetHandler("OnMouseExit", function(self)
		ZO_Tooltips_HideTextTooltip()
	end)
	ADR.guildHistoryTextControl_lastWeek:SetMouseEnabled(true)
	
	--current week
	ADR.guildHistoryTextControl_currentWeek = WINDOW_MANAGER:CreateControl(nil, parent, CT_LABEL)
	ADR.guildHistoryTextControl_currentWeek:SetAnchor(TOPRIGHT, parent, TOPRIGHT, -100, 10)
	ADR.guildHistoryTextControl_currentWeek:SetFont(font)
	ADR.guildHistoryTextControl_currentWeek:SetText("")
	-- tooltip text
	ADR.guildHistoryTextControl_currentWeek.tooltipText = ""
	-- tooltip handler
	ADR.guildHistoryTextControl_currentWeek:SetHandler("OnMouseEnter", function(self)
		ZO_Tooltips_ShowTextTooltip(self, BOTTOM, self.tooltipText)
	end)
	ADR.guildHistoryTextControl_currentWeek:SetHandler("OnMouseExit", function(self)
		ZO_Tooltips_HideTextTooltip()
	end)
	ADR.guildHistoryTextControl_currentWeek:SetMouseEnabled(true)
end


-- update/calculate the income (last and current week)
function ADR.processGuildEvents(guildId)
	-- BANK EVENTS (DONATIONS)
	local numBankEvents = GetNumGuildEvents(guildId, GUILD_HISTORY_BANK)
	if numBankEvents > 0 then
		local oldestBankEventId = 0
		local newestBankEventId = 0
		
		-- go from oldest to newest event
		for i=numBankEvents, 1, -1 do
			local eventType, secsSinceEvent, name, amount, _, _, _, _, eventId = GetGuildEventInfo(guildId, GUILD_HISTORY_BANK, i)
			-- for donations: param1 = displayNameDonator | param2 = amount
			-- consider only events that are not already processed
			if eventId < ADR.savedVars.oldestBankEventId[guildId] or eventId > ADR.savedVars.newestBankEventId[guildId] then
				-- consider only gold donations
				if eventType == GUILD_EVENT_BANKGOLD_ADDED and amount ~= nil and amount > 0 then
					--d("ADDED: ID: " .. eventId .. " | amount: " .. amount .. " | name: " .. name .. " || oldest: " .. ADR.savedVars.oldestBankEventId[guildId] .. " | newest: " .. ADR.savedVars.newestBankEventId[guildId])
					local eventTimestamp = GetTimeStamp()-secsSinceEvent
					-- consider only events that are not older than the last trader week
					if eventTimestamp >= ADR.timestampLastWeekStart then
						if eventTimestamp < ADR.timestampCurrentWeekStart then
							-- event belongs to last week
							ADR.savedVars.goldDepositSum_lastWeek[guildId] = ADR.savedVars.goldDepositSum_lastWeek[guildId] + amount
						else
							-- event belongs to current week
							ADR.savedVars.goldDepositSum_currentWeek[guildId] = ADR.savedVars.goldDepositSum_currentWeek[guildId] + amount
						end
					end
				end
			end
			-- remember oldest and newest considered event
			if i == numBankEvents then
				oldestBankEventId = eventId
			elseif i == 1 then
				newestBankEventId = eventId
			end
		end
		ADR.savedVars.oldestBankEventId[guildId] = oldestBankEventId
		ADR.savedVars.newestBankEventId[guildId] = newestBankEventId
	end
	
	-- STORE EVENTS (PURCHASES -> TAX)
	local numStoreEvents = GetNumGuildEvents(guildId, GUILD_HISTORY_STORE)
	if numStoreEvents > 0 then
		local oldestStoreEventId = 0
		local newestStoreEventId = 0
		
		-- go from oldest to newest event
		for i=numStoreEvents, 1, -1 do
			local eventType, secsSinceEvent, _, _, _, _, _, tax, eventId = GetGuildEventInfo(guildId, GUILD_HISTORY_STORE, i)
			-- for sales: param1 = displayNameSeller | param2 = displayNameBuyer | param3 = quantity | param 4 = itemName | param5 = price | param6 = guildTax
			-- consider only events that are not already processed
			if eventId < ADR.savedVars.oldestStoreEventId[guildId] or eventId > ADR.savedVars.newestStoreEventId[guildId] then
				-- consider only guild sales
				if eventType == GUILD_EVENT_ITEM_SOLD and tax ~= nil and tax  > 0 then
					local eventTimestamp = GetTimeStamp()-secsSinceEvent
					-- consider only events that are not older than the last trader week
					if eventTimestamp >= ADR.timestampLastWeekStart then
						if eventTimestamp < ADR.timestampCurrentWeekStart then
							-- event belongs to last week
							ADR.savedVars.guildTaxSum_lastWeek[guildId] = ADR.savedVars.guildTaxSum_lastWeek[guildId] + tax
						else
							ADR.savedVars.guildTaxSum_currentWeek[guildId] = ADR.savedVars.guildTaxSum_currentWeek[guildId] + tax
						end
					end
				end
			end
			-- remember oldest and newest considered event
			if i == numStoreEvents then
				oldestStoreEventId = eventId
			elseif i == 1 then
				newestStoreEventId = eventId
			end
		end
		ADR.savedVars.oldestStoreEventId[guildId] = oldestStoreEventId
		ADR.savedVars.newestStoreEventId[guildId] = newestStoreEventId
	end

end


-- calculates trader weeks start
-- trader week starts always Tuesday - 14:00°° (UTC)
function ADR.calculatetimestampCurrentWeekStart()
	local step = 604800 -- exact 7 days
	local nextTimestamp = 1614693600 -- 2021/03/02 - 14:00 UTC
	local lastTimestamp = 1614693600 - step

    while nextTimestamp < GetTimeStamp() do
		-- add 7 days again and again until nextTimestamp is bigger than the current -> last timestamp is last Tuesday 14:00 (UTC)
		lastTimestamp = nextTimestamp
		nextTimestamp = nextTimestamp + step
	end
	
	-- lastTimestamp is last trader change
	-- first, check if new week began
	if ADR.timestampNextWeekStart == lastTimestamp then
		-- new week
		ADR.savedVars.goldDepositSum_lastWeek[guildId] = ADR.savedVars.goldDepositSum_currentWeek[guildId]
		ADR.savedVars.goldDepositSum_currentWeek[guildId] = 0
		ADR.savedVars.guildTaxSum_lastWeek[guildId] = ADR.savedVars.guildTaxSum_currentWeek[guildId]
		ADR.savedVars.guildTaxSum_currentWeek[guildId] = 0
	end
	-- save timestamps
	ADR.timestampLastWeekStart = lastTimestamp - step
	ADR.timestampCurrentWeekStart = lastTimestamp
	ADR.timestampNextWeekStart = nextTimestamp
end


-- display values for current selected guild
function ADR.setIncomeText(guildId)
	if guildId then
		-- check for initialization because the player may changed guild during game
		ADR.initializeIncomeValues(guildId)
		-- gold sum
		ADR.guildHistoryTextControl_lastWeek:SetText("LW:\n" .. ADR.colors.gold .. ADR.formatGold(ADR.savedVars.goldDepositSum_lastWeek[guildId] + ADR.savedVars.guildTaxSum_lastWeek[guildId]))
		ADR.guildHistoryTextControl_currentWeek:SetText("AW:\n" .. ADR.colors.gold .. ADR.formatGold(ADR.savedVars.goldDepositSum_currentWeek[guildId] + ADR.savedVars.guildTaxSum_currentWeek[guildId]))
		-- dates and values
		ADR.guildHistoryTextControl_lastWeek.tooltipText = tostring(os.date('%Y/%m/%d %H:%M', ADR.timestampLastWeekStart)) .. "  -  " .. tostring(os.date('%Y/%m/%d %H:%M', ADR.timestampCurrentWeekStart)) .. "\n" .. ADR.loc.textGuildTax .. ADR.formatGold(ADR.savedVars.guildTaxSum_lastWeek[guildId]) .. "\n" .. ADR.loc.textDonation .. ADR.formatGold(ADR.savedVars.goldDepositSum_lastWeek[guildId])
		ADR.guildHistoryTextControl_currentWeek.tooltipText = tostring(os.date('%Y/%m/%d %H:%M', ADR.timestampCurrentWeekStart)) .. "  -  " .. tostring(os.date('%Y/%m/%d %H:%M', ADR.timestampNextWeekStart)) .. "\n" .. ADR.loc.textGuildTax .. ADR.formatGold(ADR.savedVars.guildTaxSum_currentWeek[guildId]) .. "\n" .. ADR.loc.textDonation .. ADR.formatGold(ADR.savedVars.goldDepositSum_currentWeek[guildId])
	end
end


-- format the gold to a comfortable format and returns a string
function ADR.formatGold(num)
	return tostring(num):reverse():gsub("%d%d%d", "%1."):reverse():gsub("^%.", "")
end




-- START HERE
EVENT_MANAGER:RegisterForEvent(ADR.appName, EVENT_ADD_ON_LOADED, onAddonLoaded)

