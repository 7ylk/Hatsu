-- Hatsu Loader configuration for auto execute on teleport (always keep at the top of your script execution)
getgenv().HatsuLoader = [[
local repo = "https://raw.githubusercontent.com/7ylk/Hatsu/main/Obsidian-main/"
loadstring(game:HttpGet(repo .. "Example.lua?t=" .. os.time()))()
]]

local repo = "https://raw.githubusercontent.com/7ylk/Hatsu/main/Obsidian-main/"
local function get(file)
    return game:HttpGet(repo .. file .. "?t=" .. os.time())
end
local Library = loadstring(get("Hatsu.lua"))()
local ThemeManager = loadstring(get("addons/ThemeManager.lua"))()
local SaveManager = loadstring(get("addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "Hatsu",
	Footer = "version: example",
	Icon = "Logo",
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Main = Window:AddTab("Main", "user"),
	Player = Window:AddTab("Player", "user"),
	Util = Window:AddTab("Util", "wrench"),
	Misc = Window:AddTab("Misc", "globe"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

--// Main Tab \\--
local LeftGroupBox = Tabs.Main:AddLeftGroupbox("Groupbox", "boxes")

LeftGroupBox:AddToggle("MyToggle", {
	Text = "This is a toggle",
	Tooltip = "This is a tooltip",
	Default = true,
})

Toggles.MyToggle:OnChanged(function()
	print("MyToggle changed to:", Toggles.MyToggle.Value)
end)

Toggles.MyToggle:SetValue(false)

--// Misc Tab (Server Hop) \\--
local MiscGroupbox = Tabs.Misc:AddLeftGroupbox("Server Utility", "globe")

MiscGroupbox:AddDropdown("ServerHopMethod", {
	Values = { "Lowest players", "Lowest Ping" },
	Default = 1,
	Text = "Server Hop Method",
	Tooltip = "Pick the server hop method",
})

local function ServerHop(method)
	local HttpService = game:GetService("HttpService")
	local TeleportService = game:GetService("TeleportService")
	local PlaceId = game.PlaceId
	local LocalPlayer = game.Players.LocalPlayer
	
	local nextPageCursor = ""
	local servers = {}
	
	for i = 1, 3 do
		local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100&cursor=" .. nextPageCursor
		local success, response = pcall(game.HttpGet, game, url)
		if success and response then
			local data = HttpService:JSONDecode(response)
			if data and data.data then
				for _, server in ipairs(data.data) do
					if server.id ~= game.JobId and server.playing < server.maxPlayers and server.playing > 0 then
						table.insert(servers, server)
					end
				end
				nextPageCursor = data.nextPageCursor
				if not nextPageCursor or nextPageCursor == "" then
					break
				end
			else
				break
			end
		else
			break
		end
	end
	
	if #servers == 0 then
		Library:Notify("No suitable server found!")
		return
	end
	
	if method == "Lowest players" then
		table.sort(servers, function(a, b)
			return a.playing < b.playing
		end)
	elseif method == "Lowest Ping" then
		table.sort(servers, function(a, b)
			return (a.ping or 999) < (b.ping or 999)
		end)
	end
	
	local targetServer = servers[1]
	if targetServer then
		Library:Notify("Teleporting to server with " .. targetServer.playing .. " players and " .. (targetServer.ping or "unknown") .. " ping...")
		local queueTeleport = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
		if queueTeleport then
			local autoExecuteToggle = Toggles.SaveManager_AutoExecuteOnTeleport
			if autoExecuteToggle and autoExecuteToggle.Value then
				local loader = getgenv().HatsuLoader or (isfile and isfile("Hatsu/loader.lua") and readfile("Hatsu/loader.lua"))
				if loader then
					pcall(queueTeleport, loader)
				end
			end
		end
		task.wait(1)
		TeleportService:TeleportToPlaceInstance(PlaceId, targetServer.id, LocalPlayer)
	else
		Library:Notify("No target server found!")
	end
end

MiscGroupbox:AddButton({
	Text = "Server Hop",
	Func = function()
		ServerHop(Options.ServerHopMethod.Value)
	end,
	DoubleClick = false,
	Tooltip = "Teleport to another server based on the selected method",
})

--// UI Settings Tab \\--
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})

MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "DPI Scale",
	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)
		Library:SetDPIScale(DPI)
	end,
})

MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		Window:SetCornerRadius(value)
	end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
	print("Unloaded!")
end)
