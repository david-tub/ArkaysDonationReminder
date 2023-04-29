-- ADDON NAEMPSACE INITIALIZATION - NEVER REMOVE
ADR = {}
ADR.loc = {}

--ENGLISH LANGUAGE LOCALIZATION

-- Settings
ADR.loc.introDescription = "First select the guild you want to donate regularly, then choose a configuration (regularity and amount of donation). When you then interact with the guild bank, the addon will remind you of your donation and execute it for you."
ADR.loc.guildSelectionName = "Guild"
ADR.loc.guildSelectionTooltip = "Guild to be donated to."
ADR.loc.configurationName = "Configuration"
ADR.loc.configurationTooltip = "Amount and frequency of the donation to be made."
ADR.loc.printLastDonationName = "Print last donation"
ADR.loc.printLastDonationTooltip = "Print the last executed transaction into the chat."
ADR.loc.deleteProtocolName = "Delete Protocol"
ADR.loc.deleteProtocolTooltip = "Reset the log of all executed transactions."
ADR.loc.headerCustomConf = "Custom Configuration"
ADR.loc.customConfDaysName = "Frequency in days"
ADR.loc.customConfDaysTootlip = "Frequency of the customized donation in days."
ADR.loc.customConfAmountName = "Amount"
ADR.loc.customConfAmountTootlip = "Amount of the customized donation."
ADR.loc.containerProfile = "Profile"

ADR.loc.dropdownGuildDisabled = "unset"

ADR.loc.dropdownConfDisabled = "Disabled"
ADR.loc.dropdownConf1 = "1.115 Gold every 7 days"
ADR.loc.dropdownConf2 = "2.230 Gold every 7 days"
ADR.loc.dropdownConf3 = "3.345 Gold every 7 days"
ADR.loc.dropdownConf4 = "4.460 Gold every 30 days"
ADR.loc.dropdownConf5 = "8.920 Gold every 30 days"
ADR.loc.dropdownConf6 = "13.380 Gold every 30 days"
ADR.loc.dropdownConfCustom = "Custom"

ADR.loc.onlyNotification = "Only weekly notifications"
ADR.loc.onlyNotificationTooltip = "You will be notified every 7 days. But no automatic donations will be made."

ADR.loc.headerAdvanced = "Advanced"
ADR.loc.displayDonationSum = "Show weekly guild income"
ADR.loc.displayDonationSumTooltip = "Displays the sum of all gold deposits and tax revenues of the last and current merchant week in the history tab of the guild menu. Since the history is limited by the game, a daily login is recommended to get the most accurate value. Otherwise, you can manually request more bank and sales events at any time (\"Show more\"). Finally, please make sure your rank is high enough to see gold deposits."

-- Chat Outputs
ADR.loc.donationExecuted = "Donation executed: "
ADR.loc.protocolDeleted = "Protocol reset"


-- Notifications
ADR.loc.reminderTitel = "Time for a donation"
ADR.loc.reminderBody = "The last time you donated was %d days ago.\nBesides, maybe you could put something in the guild store again."
ADR.loc.reminderBodyOnlyNotification = "Your weekly reminder to donate or put something in the guild store."



-- Dialogs
ADR.loc.initialSetupBody = "To use the addon you have to configure it first (very fast).\n\nConfirm this dialog to get to the settings."
ADR.loc.infoMultipleProfilesBody = "The addon now supports automatic donations for multiple guilds. Your existing configuration has been saved in Profile 1.\n\nConfirm this dialog to get to the settings."

ADR.loc.executeDonationTitle = "Execute donation now?"
ADR.loc.executeDonationBodyFirstTimeBody = "This is your first donation with %s. If you confirm this dailog, the configured donation will be executed automatically."
ADR.loc.executeDonationBody = "Your last donation was %d days ago. Execute donation automatically now?"
ADR.loc.loadingDonationTitle = "Please wait!"
ADR.loc.loadingDonationBody = "Transaction is being executed ..."


 -- Other
ADR.loc.textDonation = "Deposits: "
ADR.loc.textGuildTax = "Taxes: "