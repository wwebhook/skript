local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/wwebhook/skript/refs/heads/main/lib.lua"))()

local Window = Library:CreateWindow({
	Title = "Webhook",
	Subtitle = "Doors",
	Accent = Color3.fromRGB(255, 255, 255),
	ToggleKey = Enum.KeyCode.RightControl,
})

local MainTab = Window:CreateTab({ Name = "Main", Icon = "rbxassetid://10709782497" })
local InfoTab = Window:CreateTab({ Name = "Information", Icon = "rbxassetid://10723415903" })
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "rbxassetid://6372755229" })

local Visual = MainTab:CreateSection("Visual")

local FOV = Visual:CreateSlider({
	Name = "Field Of View",
	Min = 0,
	Max = 120,
	Default = 70,
	Callback = function(value)
		_G.FOVValue = value
		if _G.FOVLoop then return end
		_G.FOVLoop = true
		task.spawn(function()
			while true do
				workspace.CurrentCamera.FieldOfView = _G.FOVValue
				task.wait()
			end
		end)
	end,
})
