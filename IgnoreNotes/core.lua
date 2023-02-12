-- © 2023 Josh 'Kkthnx' Russell All Rights Reserved

--[[
	Ignore Notes allows players to add notes for players in their ignore list.
	This feature is useful for players to keep track of why certain players are ignored and helps with organization.
	The notes are displayed in the ignore list and can be edited by double clicking on the ignore playe name.
	The notes are saved in a database for future use.
	The addon also provides a help tip for new users to explain how to add notes to the ignore list.
-- ]]

local IgnoreNotesFrame = CreateFrame("Frame")
IgnoreNotesFrame:RegisterEvent("PLAYER_LOGIN")
IgnoreNotesFrame:RegisterEvent("VARIABLES_LOADED")

-- Create a lookup table to store the translations
local LocaleTable = {
	-- Translations for the stranger
	["IgnoreNotesHelp_deDE"] = "Notizen zu blockierten Spielern hinzufügen, indem Sie auf ihren Namen doppelt klicken.",
	["IgnoreNotesHelp_esES"] = "Agregue notas a los jugadores ignorados haciendo doble clic en su nombre.",
	["IgnoreNotesHelp_esMX"] = "Agregue notas a los jugadores ignorados haciendo doble clic en su nombre.",
	["IgnoreNotesHelp_frFR"] = "Ajoutez des notes aux joueurs ignorés en double-cliquant sur leur nom.",
	["IgnoreNotesHelp_itIT"] = "Aggiungi note ai giocatori ignorati facendo doppio clic sul loro nome.",
	["IgnoreNotesHelp_koKR"] = "무시된 플레이어의 이름을 두 번 클릭하여 노트를 추가하십시오.",
	["IgnoreNotesHelp_ptBR"] = "Adicione notas aos jogadores ignorados clicando duas vezes em seu nome.",
	["IgnoreNotesHelp_ruRU"] = "Добавляйте заметки к игрокам, игнорируемым двойным щелчком по их имени.",
	["IgnoreNotesHelp_zhCN"] = "通过双击忽略的玩家的名字添加注释。",
	["IgnoreNotesHelp_zhTW"] = "通過雙擊忽略的玩家的名稱添加註釋。",
}

-- Retrieve the current locale and store the translation in `IgnoreNotesHelp`
-- If the locale is not found in the `LocaleTable`, the default value of "Stranger" is used
local IgnoreNotesString = LocaleTable["IgnoreNotesHelp_" .. GetLocale()] or "Add notes to ignored players by double-clicking their name."
-- Define variables to store the unit's name and the note string format
local unitName
local noteString = "|T" .. "Interface\\Buttons\\UI-GuildButton-PublicNote-Up" .. ":12|t %s"

-- Function to initialize the IgnoreNotesDB table
local function CreateDatabase()
	-- Check if the IgnoreNotesDB table does not exist
	if not IgnoreNotesDB then
		-- Initialize the IgnoreNotesDB table
		IgnoreNotesDB = {}
	end

	-- Initialize the HelpTip and Notes sub-tables within the IgnoreNotesDB table
	IgnoreNotesDB.HelpTip = IgnoreNotesDB.HelpTip or {}
	IgnoreNotesDB.Notes = IgnoreNotesDB.Notes or {}
end

-- Define a function to get the name of a button
local function GetButtonName(button)
	-- Get the text of the name property of the button
	local name = button.name:GetText()

	-- Check if the name does not contain a dash
	if not name:match("-") then
		-- If not, append the realm name to the name, separated by a dash
		name = name .. "-" .. GetRealmName()
	end

	-- Return the final name
	return name
end

-- Define a function to handle the OnClick event of the Ignore button
local function IgnoreButton_OnClick(self)
	-- Get the name of the button using the GetButtonName function
	unitName = GetButtonName(self)

	-- Show a static popup with the IGNORE_NOTES message and the unit name as the argument
	StaticPopup_Show("IGNORE_NOTES", unitName)
end

-- Define a function to handle the OnEnter event of the Ignore button
local function IgnoreButton_OnEnter(self)
	-- Get the name of the button using the GetButtonName function
	local name = GetButtonName(self)

	-- Retrieve the saved note for the given name from the IgnoreNotesDB
	local savedNote = IgnoreNotesDB["Notes"][name]

	-- Check if a saved note exists for the name
	if savedNote then
		-- Set the owner of the GameTooltip to the Ignore button
		GameTooltip:SetOwner(self, "ANCHOR_NONE")

		-- Set the position of the GameTooltip to the top right of the Ignore button
		GameTooltip:SetPoint("TOPLEFT", self, "TOPRIGHT", 35, 0)

		-- Clear any previous lines from the GameTooltip
		GameTooltip:ClearLines()

		-- Add the name as the first line of the GameTooltip
		GameTooltip:AddLine(name)

		-- Add the saved note to the GameTooltip, using the format of the noteString
		GameTooltip:AddLine(format(noteString, savedNote), 1, 1, 1, 1)

		-- Show the GameTooltip
		GameTooltip:Show()
	end
end

-- Define a function to handle the OnHook event of the Ignore button
local function IgnoreButton_OnHook(self)
	-- Check if the Ignore button has a title, and return if it does
	if self.Title then
		return
	end

	-- Check if the Ignore button has not been hooked yet
	if not self.hooked then
		-- Set the font of the name to the Game14Font
		self.name:SetFontObject(Game14Font)

		-- Hook the OnDoubleClick event to the IgnoreButton_OnClick function
		self:HookScript("OnDoubleClick", IgnoreButton_OnClick)

		-- Hook the OnEnter event to the IgnoreButton_OnEnter function
		self:HookScript("OnEnter", IgnoreButton_OnEnter)

		-- Hook the OnLeave event to the GameTooltip_Hide function
		self:HookScript("OnLeave", GameTooltip_Hide)

		-- Create a texture for the note icon
		self.noteTex = self:CreateTexture()

		-- Set the size of the note icon texture
		self.noteTex:SetSize(16, 16)

		-- Set the texture of the note icon to the guild public note icon
		self.noteTex:SetTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up")

		-- Set the position of the note icon to the top right of the Ignore button
		self.noteTex:SetPoint("RIGHT", -5, 0)

		-- Set a flag to indicate that the Ignore button has been hooked
		self.hooked = true
	end

	-- Show or hide the note icon based on the presence of a saved note for the button
	self.noteTex:SetShown(IgnoreNotesDB["Notes"][GetButtonName(self)])
end

-- This code defines the dialog box for the "IGNORE_NOTES" static popup
StaticPopupDialogs["IGNORE_NOTES"] = {
	-- The text to be displayed on the dialog box
	text = SET_FRIENDNOTE_LABEL,
	-- The text for the first button
	button1 = OKAY,
	-- The text for the second button
	button2 = CANCEL,
	-- Function to be executed when the dialog box is shown
	OnShow = function(self)
		-- Get the saved note for the current unit
		local savedNote = IgnoreNotesDB["Notes"][unitName]
		-- If a saved note exists for the current unit
		if savedNote then
			-- Set the text of the edit box to the saved note
			self.editBox:SetText(savedNote)
			-- Highlight the text in the edit box
			self.editBox:HighlightText()
		end
	end,
	-- Function to be executed when the first button is clicked
	OnAccept = function(self)
		-- Get the text entered in the edit box
		local text = self.editBox:GetText()
		-- If the text is not empty
		if text and text ~= "" then
			-- Set the note for the current unit to the entered text
			IgnoreNotesDB["Notes"][unitName] = text
		else
			-- Remove the note for the current unit
			IgnoreNotesDB["Notes"][unitName] = nil
		end
	end,
	-- Function to be executed when the "Escape" key is pressed in the edit box
	EditBoxOnEscapePressed = function(editBox)
		-- Hide the dialog box
		editBox:GetParent():Hide()
	end,
	-- Function to be executed when the "Enter" key is pressed in the edit box
	EditBoxOnEnterPressed = function(editBox)
		-- Get the text entered in the edit box
		local text = editBox:GetText()
		-- If the text is not empty
		if text and text ~= "" then
			-- Set the note for the current unit to the entered text
			IgnoreNotesDB["Notes"][unitName] = text
		else
			-- Remove the note for the current unit
			IgnoreNotesDB["Notes"][unitName] = nil
		end
		-- Hide the dialog box
		editBox:GetParent():Hide()
	end,
	-- Show the dialog box even if the player is dead
	whileDead = 1,
	-- Indicates that the dialog box has an edit box
	hasEditBox = 1,
	-- The width of the edit box
	editBoxWidth = 250,
}

-- Helper function to mark the help tip has been acknowledged
local function IgnoreNotesHelpInfo(callbackArg)
	IgnoreNotesDB["HelpTip"][callbackArg] = true
end

-- Function to create the ignore notes feature
local function CreateIgnoreNotes()
	-- Call the CreateDatabase function to initialize the database
	CreateDatabase()

	-- Define the help info for the ignore list
	if WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE then
		local ignoreHelpInfo = {
			text = IgnoreNotesString,
			buttonStyle = HelpTip.ButtonStyle.GotIt,
			targetPoint = HelpTip.Point.RightEdgeCenter,
			onAcknowledgeCallback = IgnoreNotesHelpInfo,
			callbackArg = "IgnoreNotes",
		}

		-- Show the help tip when the ignore list is shown
		IgnoreListFrame:HookScript("OnShow", function(frame)
			if not IgnoreNotesDB["HelpTip"]["IgnoreNotes"] then
				HelpTip:Show(frame, ignoreHelpInfo)
			end
		end)
	end

	-- Hook the Update method of the ScrollBox to run the IgnoreButton_OnHook function on each frame
	hooksecurefunc(IgnoreListFrame.ScrollBox, "Update", function(self)
		self:ForEachFrame(IgnoreButton_OnHook)
	end)

	-- Hook the OnClick method of the UnsquelchButton to remove the note for the selected ignore
	FriendsFrameUnsquelchButton:HookScript("OnClick", function()
		local name = C_FriendList.GetIgnoreName(C_FriendList.GetSelectedIgnore())
		if name then
			-- Check if the name already includes the realm name
			if not name:match("-") then
				name = name .. "-" .. GetRealmName()
			end
			IgnoreNotesDB["Notes"][name] = nil
		end
	end)
end

-- Register event for the IgnoreNotesFrame frame
local function IgnoreNotesFrame_OnEvent(self, event)
	-- Check if the event is player login
	if event == "PLAYER_LOGIN" then
		-- Create ignore notes
		CreateIgnoreNotes()
	-- Check if the event is variables loaded
	elseif event == "VARIABLES_LOADED" then
		-- Create the database
		CreateDatabase()
	end
end

-- Set the script for the IgnoreNotesFrame frame to handle events
IgnoreNotesFrame:SetScript("OnEvent", IgnoreNotesFrame_OnEvent)
