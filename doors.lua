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
		local RunService = game:GetService("RunService")
		RunService:BindToRenderStep("ForceFOV", Enum.RenderPriority.Last.Value + 1000, function()
			local Camera = workspace.CurrentCamera
			if Camera then
				Camera.FieldOfView = _G.FOVValue
			end
		end)
	end,
})

local FullBright = Visual:CreateToggle({
	Name = "Full Bright",
	Default = nil,
	Callback = function(enabled)
		local Lighting = game:GetService("Lighting")
		_G.FullBrightOn = enabled
		if not _G.FullBrightOld then
			_G.FullBrightOld = {
				Brightness = Lighting.Brightness,
				ClockTime = Lighting.ClockTime,
				FogEnd = Lighting.FogEnd,
				GlobalShadows = Lighting.GlobalShadows,
				Ambient = Lighting.Ambient,
				OutdoorAmbient = Lighting.OutdoorAmbient,
			}
		end
		if not enabled then
			for prop, val in pairs(_G.FullBrightOld) do
				Lighting[prop] = val
			end
		end
		if _G.FullBrightLoop then return end
		_G.FullBrightLoop = true
		task.spawn(function()
			while true do
				if _G.FullBrightOn then
					Lighting.Brightness = 2
					Lighting.ClockTime = 14
					Lighting.FogEnd = 100000
					Lighting.GlobalShadows = false
					Lighting.Ambient = Color3.fromRGB(255, 255, 255)
					Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
				end
				task.wait()
			end
		end)
	end,
})

local Doors = Visual:CreateToggle({
	Name = "Doors ESP",
	Default = nil,
	Callback = function(enabled)
		_G.DoorsESPOn = enabled
		if not enabled then
			for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
				local doorModel = room:FindFirstChild("Door")
				local door = doorModel and doorModel:FindFirstChild("Door")
				if door and door:FindFirstChild("DoorESP") then
					door.DoorESP:Destroy()
				end
			end
		end
		if _G.DoorsESPLoop then return end
		_G.DoorsESPLoop = true
		task.spawn(function()
			while true do
				if _G.DoorsESPOn then
					for _, room in pairs(workspace.CurrentRooms:GetChildren()) do
						local doorModel = room:FindFirstChild("Door")
						if doorModel then
							for _, part in pairs(doorModel:GetDescendants()) do
								if part:IsA("BasePart") and part.Name:lower() == "hidden" then
									part:Destroy()
								end
							end
							local door = doorModel:FindFirstChild("Door")
							if door and not door:FindFirstChild("DoorESP") then
								local highlight = Instance.new("Highlight")
								highlight.Name = "DoorESP"
								highlight.FillColor = Color3.fromRGB(255, 255, 255)
								highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
								highlight.FillTransparency = 0.5
								highlight.OutlineTransparency = 0
								highlight.Adornee = door
								highlight.Parent = door
							end
						end
					end
				end
				task.wait()
			end
		end)
	end,
})
