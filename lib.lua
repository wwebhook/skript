local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Library = {}
DarkLib.Version = "1.0.0"

DarkLib.Theme = {
	Background = Color3.fromRGB(14, 14, 17),
	BackgroundTransparency = 0.1,
	Sidebar = Color3.fromRGB(0, 0, 0),
	SidebarTransparency = 0.55,
	Card = Color3.fromRGB(255, 255, 255),
	CardTransparency = 0.965,
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.9,
	Divider = Color3.fromRGB(255, 255, 255),
	DividerTransparency = 0.93,
	Hover = Color3.fromRGB(255, 255, 255),
	HoverTransparency = 0.955,
	SelectedTransparency = 0.92,
	Text = Color3.fromRGB(236, 236, 241),
	SubText = Color3.fromRGB(150, 150, 160),
	MutedText = Color3.fromRGB(98, 98, 108),
	Accent = Color3.fromRGB(10, 132, 255),
	ToggleOff = Color3.fromRGB(58, 58, 64),
	Red = Color3.fromRGB(255, 95, 87),
	Yellow = Color3.fromRGB(254, 188, 46),
	Green = Color3.fromRGB(40, 200, 64),
}

local FONT = Enum.Font.Gotham
local FONT_MEDIUM = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local TOPBAR_HEIGHT = 46
local SIDEBAR_WIDTH = 170
local USER_CARD_HEIGHT = 54
local BUBBLE_SIZE = 54
local SLIDER_KNOB = 14
local CORNER_RADIUS = 12
local ROUND = UDim.new(1, 0)

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function create(className, props, children)
	local instance = Instance.new(className)
	if instance:IsA("GuiObject") then
		instance.BorderSizePixel = 0
	end

	local parent = nil
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			instance[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = instance
	end
	if parent then
		instance.Parent = parent
	end
	return instance
end

local function tween(instance, duration, goal, style)
	local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local t = TweenService:Create(instance, info, goal)
	t:Play()
	return t
end

local function corner(radius)
	return create("UICorner", {
		CornerRadius = typeof(radius) == "UDim" and radius or UDim.new(0, radius),
	})
end

local function stroke(color, transparency)
	return create("UIStroke", {
		Color = color,
		Transparency = transparency,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function padding(top, right, bottom, left)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right or top),
		PaddingBottom = UDim.new(0, bottom or top),
		PaddingLeft = UDim.new(0, left or right or top),
	})
end

local function list(spacing, direction)
	local horizontal = direction == Enum.FillDirection.Horizontal
	return create("UIListLayout", {
		Padding = UDim.new(0, spacing or 0),
		FillDirection = direction or Enum.FillDirection.Vertical,
		VerticalAlignment = horizontal and Enum.VerticalAlignment.Center or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

-- Tracks a press that starts on `handle`: onStart(input), then onMove(input) while
-- it's held and moving, then onEnd(). Returns the global InputChanged connection.
local function onDrag(handle, onStart, onMove, onEnd)
	local dragging = false
	local touch = nil

	handle.InputBegan:Connect(function(input)
		if not isPress(input) then
			return
		end
		dragging = true
		touch = input.UserInputType == Enum.UserInputType.Touch and input or nil
		onStart(input)

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				connection:Disconnect()
				dragging = false
				onEnd()
			end
		end)
	end)

	return UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if touch then
			if input ~= touch then
				return
			end
		elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		onMove(input)
	end)
end

-- Icons can be an image id (123, "123", "rbxassetid://123") or a short text
-- glyph such as an emoji ("⚡"). Returns an ImageLabel or a TextLabel.
local function createIcon(icon, size, color, props)
	local base = {
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
	}
	for key, value in pairs(props) do
		base[key] = value
	end

	local id = icon
	if type(id) == "number" or (type(id) == "string" and id:match("^%d+$")) then
		id = "rbxassetid://" .. id
	end
	if type(id) == "string" and id:find("://") then
		base.Image = id
		base.ImageColor3 = color
		base.ScaleType = Enum.ScaleType.Fit
		return create("ImageLabel", base)
	end

	base.Text = tostring(icon)
	base.TextColor3 = color
	base.TextSize = size
	base.Font = FONT_MEDIUM
	return create("TextLabel", base)
end

local function iconGoal(icon, color, transparency)
	if icon:IsA("ImageLabel") then
		return { ImageColor3 = color, ImageTransparency = transparency }
	end
	return { TextColor3 = color, TextTransparency = transparency }
end

local function ripple(container, position)
	local origin = Vector2.new(position.X, position.Y) - container.AbsolutePosition
	local size = math.max(container.AbsoluteSize.X, container.AbsoluteSize.Y) * 2.2
	local circle = create("Frame", {
		Name = "Ripple",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(origin.X, origin.Y),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.88,
		Parent = container,
	}, { corner(ROUND) })

	tween(circle, 0.6, { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
	task.delay(0.6, function()
		circle:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- Window
--------------------------------------------------------------------------------

function DarkLib:CreateWindow(config)
	config = config or {}

	local player = Players.LocalPlayer
	assert(player, "DarkLib has to be required from a LocalScript")
	local playerGui = player:WaitForChild("PlayerGui")

	local theme = table.clone(DarkLib.Theme)
	for key, value in pairs(config.Theme or {}) do
		theme[key] = value
	end
	theme.Accent = config.Accent or theme.Accent

	local size = config.Size or Vector2.new(580, 380)
	if typeof(size) == "UDim2" then
		size = Vector2.new(size.X.Offset, size.Y.Offset)
	end

	local window = setmetatable({
		Title = config.Title or "DarkLib",
		Subtitle = config.Subtitle or "",
		Theme = theme,
		Tabs = {},
		ActiveTab = nil,
		_size = size,
		_restScale = 1,
		_closed = false,
		_minimized = false,
		_maximized = false,
		_busy = false,
		_connections = {},
	}, Window)

	-- Re-running the script (e.g. from StarterGui) replaces the old window.
	local guiName = "DarkLib_" .. window.Title
	local existing = playerGui:FindFirstChild(guiName)
	if existing then
		existing:Destroy()
	end

	local gui = create("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
	})

	local mainCorner = corner(CORNER_RADIUS)
	local mainStroke = stroke(theme.Stroke, 1)
	local mainScale = create("UIScale", { Scale = 0.94 })
	local main = create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundColor3 = theme.Background,
		BackgroundTransparency = 1,
		Parent = gui,
	}, { mainCorner, mainStroke, mainScale })

	-- Everything inside the window lives in a CanvasGroup so it can fade as one.
	local canvas = create("CanvasGroup", {
		Name = "Canvas",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Parent = main,
	}, { corner(CORNER_RADIUS) })

	-- Sidebar ----------------------------------------------------------------

	local bodyHeight = size.Y - TOPBAR_HEIGHT
	local sidebar = create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0),
		BackgroundColor3 = theme.Sidebar,
		BackgroundTransparency = theme.SidebarTransparency,
		Parent = canvas,
	})
	create("Frame", {
		Name = "Divider",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = theme.Divider,
		BackgroundTransparency = theme.DividerTransparency,
		Parent = sidebar,
	})

	-- Body heights are fixed offsets (not scale) so minimizing rolls the window
	-- up like a blind instead of squashing everything inside it.
	local sidebarBody = create("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, TOPBAR_HEIGHT),
		Size = UDim2.new(1, -1, 0, bodyHeight),
		BackgroundTransparency = 1,
		Parent = sidebar,
	})

	local showUser = config.ShowUser ~= false
	local tabList = create("ScrollingFrame", {
		Name = "Tabs",
		Size = UDim2.new(1, 0, 1, showUser and -USER_CARD_HEIGHT or 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = sidebarBody,
	}, { list(2), padding(4, 10, 10, 10) })

	if showUser then
		local userCard = create("Frame", {
			Name = "User",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, USER_CARD_HEIGHT),
			BackgroundTransparency = 1,
			Parent = sidebarBody,
		})
		create("Frame", {
			Name = "Divider",
			Position = UDim2.fromOffset(12, 0),
			Size = UDim2.new(1, -24, 0, 1),
			BackgroundColor3 = theme.Divider,
			BackgroundTransparency = theme.DividerTransparency,
			Parent = userCard,
		})
		local avatar = create("ImageLabel", {
			Name = "Avatar",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = theme.Hover,
			BackgroundTransparency = 0.92,
			Parent = userCard,
		}, { corner(ROUND) })
		create("TextLabel", {
			Name = "DisplayName",
			Position = UDim2.fromOffset(52, 12),
			Size = UDim2.new(1, -60, 0, 15),
			BackgroundTransparency = 1,
			Font = FONT_MEDIUM,
			TextSize = 12,
			Text = player.DisplayName,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = userCard,
		})
		create("TextLabel", {
			Name = "Username",
			Position = UDim2.fromOffset(52, 28),
			Size = UDim2.new(1, -60, 0, 13),
			BackgroundTransparency = 1,
			Font = FONT,
			TextSize = 11,
			Text = "@" .. player.Name,
			TextColor3 = theme.MutedText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = userCard,
		})

		-- Test players in Studio can have negative ids, so this may fail.
		task.spawn(function()
			local ok, image = pcall(function()
				return Players:GetUserThumbnailAsync(
					player.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size100x100
				)
			end)
			if ok and avatar.Parent then
				avatar.Image = image
			end
		end)
	end

	-- Top bar ----------------------------------------------------------------

	local header = create("Frame", {
		Name = "Header",
		Position = UDim2.fromOffset(SIDEBAR_WIDTH, 0),
		Size = UDim2.new(1, -SIDEBAR_WIDTH, 0, TOPBAR_HEIGHT),
		BackgroundTransparency = 1,
		Parent = canvas,
	})

	local hasSubtitle = window.Subtitle ~= ""
	create("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(18, hasSubtitle and 8 or 0),
		Size = UDim2.new(1, -36, 0, hasSubtitle and 17 or TOPBAR_HEIGHT),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		TextSize = 14,
		Text = window.Title,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = header,
	})
	create("TextLabel", {
		Name = "Subtitle",
		Position = UDim2.fromOffset(18, 26),
		Size = UDim2.new(1, -36, 0, 13),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 12,
		Text = window.Subtitle,
		TextColor3 = theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = hasSubtitle,
		Parent = header,
	})

	local headerLine = create("Frame", {
		Name = "Divider",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = theme.Divider,
		BackgroundTransparency = theme.DividerTransparency,
		Parent = header,
	})

	local pages = create("Frame", {
		Name = "Pages",
		Position = UDim2.fromOffset(SIDEBAR_WIDTH, TOPBAR_HEIGHT),
		Size = UDim2.new(1, -SIDEBAR_WIDTH, 0, bodyHeight),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = canvas,
	})

	-- macOS window controls ----------------------------------------------------

	local controls = create("Frame", {
		Name = "Controls",
		Position = UDim2.fromOffset(16, 0),
		Size = UDim2.fromOffset(56, TOPBAR_HEIGHT),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = canvas,
	}, { list(8, Enum.FillDirection.Horizontal) })

	-- The little x / - / + marks only show while hovering, like on a Mac.
	local glyphs = {}
	local function glyph(parent, width, height, rotation)
		table.insert(glyphs, create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(width, height),
			Rotation = rotation or 0,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			Parent = parent,
		}))
	end

	local function control(name, order, color, onClick)
		local button = create("TextButton", {
			Name = name,
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = color,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = order,
			Parent = controls,
		}, { corner(ROUND), stroke(Color3.new(0, 0, 0), 0.8) })

		local function release()
			tween(button, 0.2, { BackgroundColor3 = color })
		end
		button.MouseButton1Down:Connect(function()
			tween(button, 0.1, { BackgroundColor3 = color:Lerp(Color3.new(0, 0, 0), 0.25) })
		end)
		button.MouseButton1Up:Connect(release)
		button.MouseLeave:Connect(release)
		button.Activated:Connect(onClick)
		return button
	end

	local closeButton = control("Close", 1, theme.Red, function()
		window:Close()
	end)
	glyph(closeButton, 8, 2, 45)
	glyph(closeButton, 8, 2, -45)

	local minimizeButton = control("Minimize", 2, theme.Yellow, function()
		window:Minimize()
	end)
	glyph(minimizeButton, 6, 2)

	local maximizeButton = control("Maximize", 3, theme.Green, function()
		window:Maximize()
	end)
	glyph(maximizeButton, 6, 2)
	glyph(maximizeButton, 2, 6)

	controls.MouseEnter:Connect(function()
		for _, bar in ipairs(glyphs) do
			tween(bar, 0.15, { BackgroundTransparency = 0.45 })
		end
	end)
	controls.MouseLeave:Connect(function()
		for _, bar in ipairs(glyphs) do
			tween(bar, 0.2, { BackgroundTransparency = 1 })
		end
	end)

	-- Everything in the top bar right of the controls drags the window.
	local dragArea = create("Frame", {
		Name = "DragArea",
		Position = UDim2.fromOffset(84, 0),
		Size = UDim2.new(1, -84, 0, TOPBAR_HEIGHT),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Parent = canvas,
	})

	-- The circle the window turns into when closed ------------------------------

	local bubble = create("TextButton", {
		Name = "Bubble",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 5,
		Parent = main,
	})

	local bubbleProps = {
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = bubble,
	}
	local bubbleIcon
	if config.Icon then
		bubbleIcon = createIcon(config.Icon, 22, theme.Text, bubbleProps)
	else
		bubbleProps.Size = UDim2.fromScale(1, 1)
		bubbleProps.BackgroundTransparency = 1
		bubbleProps.Font = FONT_BOLD
		bubbleProps.TextSize = 20
		bubbleProps.Text = string.upper(string.sub(window.Title, 1, 1))
		bubbleProps.TextColor3 = theme.Text
		bubbleIcon = create("TextLabel", bubbleProps)
	end
	for key, value in pairs(iconGoal(bubbleIcon, theme.Text, 1)) do
		bubbleIcon[key] = value
	end

	bubble.MouseEnter:Connect(function()
		if window._closed and not window._busy then
			tween(mainScale, 0.25, { Scale = window._restScale * 1.08 })
		end
	end)
	bubble.MouseLeave:Connect(function()
		if window._closed then
			tween(mainScale, 0.25, { Scale = window._restScale })
		end
	end)

	window._gui = gui
	window._main = main
	window._mainCorner = mainCorner
	window._mainStroke = mainStroke
	window._mainScale = mainScale
	window._canvas = canvas
	window._sidebarBody = sidebarBody
	window._tabList = tabList
	window._headerLine = headerLine
	window._pages = pages
	window._bubble = bubble
	window._bubbleIcon = bubbleIcon

	local lastClick = 0
	window:_makeDraggable(dragArea, function()
		-- double-click the top bar to zoom, like on a Mac
		local now = os.clock()
		if now - lastClick < 0.35 then
			lastClick = 0
			window:Maximize()
		else
			lastClick = now
		end
	end)
	window:_makeDraggable(bubble, function()
		window:Open()
	end)

	local toggleKey = config.ToggleKey
	if toggleKey == nil then
		toggleKey = Enum.KeyCode.RightControl
	end
	if toggleKey then
		table.insert(window._connections, UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == toggleKey then
				window:Toggle()
			end
		end))
	end

	gui.Parent = playerGui

	-- Shrink to fit small screens (phones, tiny Studio viewports).
	local screen = gui.AbsoluteSize
	if screen.X > 0 and screen.Y > 0 then
		window._restScale = math.min(1, (screen.X - 24) / size.X, (screen.Y - 24) / size.Y)
	end

	-- Intro: fade + slight zoom in.
	mainScale.Scale = window._restScale * 0.94
	tween(mainScale, 0.5, { Scale = window._restScale })
	tween(main, 0.4, { BackgroundTransparency = theme.BackgroundTransparency })
	tween(mainStroke, 0.4, { Transparency = theme.StrokeTransparency })
	tween(canvas, 0.4, { GroupTransparency = 0 })

	return window
end

-- Drags the whole window by `handle`. A press that never moves counts as a click.
function Window:_makeDraggable(handle, onClick)
	local moved, startInput, startPosition

	table.insert(self._connections, onDrag(handle, function(input)
		moved = false
		startInput = input.Position
		startPosition = self._main.Position
	end, function(input)
		local delta = input.Position - startInput
		if not moved and delta.Magnitude < 4 then
			return
		end
		moved = true
		tween(self._main, 0.12, {
			Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			),
		}, Enum.EasingStyle.Quad)
	end, function()
		if not moved and onClick then
			onClick()
		end
	end))
end

function Window:_fullSize()
	if not self._maximized then
		return self._size
	end
	local screen = self._gui.AbsoluteSize
	return Vector2.new(
		math.floor(math.max(self._size.X, screen.X * 0.8)),
		math.floor(math.max(self._size.Y, screen.Y * 0.8))
	)
end

function Window:_windowSize()
	local full = self:_fullSize()
	return Vector2.new(full.X, self._minimized and TOPBAR_HEIGHT or full.Y)
end

-- Animates the window to whatever size its minimized/maximized state asks for.
function Window:_resize(position)
	local bodyHeight = self:_fullSize().Y - TOPBAR_HEIGHT
	local size = self:_windowSize()

	tween(self._main, 0.45, { Size = UDim2.fromOffset(size.X, size.Y), Position = position })
	tween(self._sidebarBody, 0.45, { Size = UDim2.new(1, -1, 0, bodyHeight) })
	tween(self._pages, 0.45, { Size = UDim2.new(1, -SIDEBAR_WIDTH, 0, bodyHeight) })
	tween(self._headerLine, 0.3, {
		BackgroundTransparency = self._minimized and 1 or self.Theme.DividerTransparency,
	})
end

-- Where the window should land when it opens from the circle, kept on screen.
function Window:_openPosition()
	local screen = self._gui.AbsoluteSize
	local size = self:_windowSize() * self._restScale
	local center = self._main.AbsolutePosition + self._main.AbsoluteSize / 2
	local margin = 8
	local x = math.max(size.X / 2 + margin, math.min(center.X, screen.X - size.X / 2 - margin))
	local y = math.max(size.Y / 2 + margin, math.min(center.Y, screen.Y - size.Y / 2 - margin))
	return UDim2.fromOffset(x, y)
end

function Window:Minimize()
	if self._closed or self._busy then
		return
	end
	self._minimized = not self._minimized
	self:_resize()
end

function Window:Maximize()
	if self._closed or self._busy then
		return
	end
	self._maximized = not self._maximized
	self._minimized = false

	local position
	if self._maximized then
		self._restorePosition = self._main.Position
		position = UDim2.fromScale(0.5, 0.5)
	else
		position = self._restorePosition
	end
	self:_resize(position)
end

-- Fades the content out, then morphs the window into a circle.
function Window:Close()
	if self._closed or self._busy then
		return
	end
	self._closed = true
	self._busy = true
	local theme = self.Theme

	task.spawn(function()
		tween(self._canvas, 0.2, { GroupTransparency = 1 }, Enum.EasingStyle.Quad).Completed:Wait()
		self._canvas.Visible = false

		tween(self._main, 0.5, { Size = UDim2.fromOffset(BUBBLE_SIZE, BUBBLE_SIZE) })
		tween(self._mainCorner, 0.5, { CornerRadius = UDim.new(0, BUBBLE_SIZE / 2) })
		tween(self._mainStroke, 0.5, { Color = theme.Accent, Transparency = 0.35 })
		self._bubble.Visible = true

		task.wait(0.2)
		tween(self._bubbleIcon, 0.3, iconGoal(self._bubbleIcon, theme.Text, 0)).Completed:Wait()
		self._busy = false
	end)
end

-- Grows the circle back into the window, right where the circle is.
function Window:Open()
	if not self._closed or self._busy then
		return
	end
	self._closed = false
	self._busy = true
	local theme = self.Theme

	task.spawn(function()
		tween(self._mainScale, 0.2, { Scale = self._restScale })
		tween(self._bubbleIcon, 0.15, iconGoal(self._bubbleIcon, theme.Text, 1), Enum.EasingStyle.Quad).Completed:Wait()
		self._bubble.Visible = false

		self:_resize(self:_openPosition())
		tween(self._mainCorner, 0.45, { CornerRadius = UDim.new(0, CORNER_RADIUS) })
		tween(self._mainStroke, 0.45, { Color = theme.Stroke, Transparency = theme.StrokeTransparency })

		task.wait(0.15)
		self._canvas.Visible = true
		tween(self._canvas, 0.35, { GroupTransparency = 0 }).Completed:Wait()
		self._busy = false
	end)
end

function Window:Toggle()
	if self._closed then
		self:Open()
	else
		self:Close()
	end
end

function Window:Destroy()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	self._gui:Destroy()
end

--------------------------------------------------------------------------------
-- Tabs
--------------------------------------------------------------------------------

function Window:CreateTab(config, icon)
	if type(config) == "string" then
		config = { Name = config, Icon = icon }
	end
	config = config or {}
	local theme = self.Theme
	local index = #self.Tabs + 1

	local tab = setmetatable({
		Window = self,
		Name = config.Name or ("Tab " .. index),
		_sections = 0,
	}, Tab)

	local button = create("TextButton", {
		Name = tab.Name,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = theme.Hover,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = index,
		Parent = self._tabList,
	}, { corner(8) })

	local indicator = create("Frame", {
		Name = "Indicator",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.fromOffset(3, 0),
		BackgroundColor3 = theme.Accent,
		Parent = button,
	}, { corner(ROUND) })

	local textOffset = 14
	local iconObject = nil
	if config.Icon then
		iconObject = createIcon(config.Icon, 16, theme.SubText, {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Parent = button,
		})
		textOffset = 38
	end

	local label = create("TextLabel", {
		Name = "Label",
		Position = UDim2.fromOffset(textOffset, 0),
		Size = UDim2.new(1, -textOffset - 8, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT_MEDIUM,
		TextSize = 13,
		Text = tab.Name,
		TextColor3 = theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = button,
	})

	local layout = list(16)
	local page = create("ScrollingFrame", {
		Name = tab.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Color3.new(1, 1, 1),
		ScrollBarImageTransparency = 0.8,
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(),
		Visible = false,
		Parent = self._pages,
	}, { layout, padding(14, 16, 18, 16) })

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 32)
	end)

	button.MouseEnter:Connect(function()
		if self.ActiveTab ~= tab then
			tween(button, 0.2, { BackgroundTransparency = theme.HoverTransparency })
		end
	end)
	button.MouseLeave:Connect(function()
		if self.ActiveTab ~= tab then
			tween(button, 0.2, { BackgroundTransparency = 1 })
		end
	end)
	button.Activated:Connect(function()
		tab:Select()
	end)

	tab._button = button
	tab._label = label
	tab._icon = iconObject
	tab._indicator = indicator
	tab._page = page

	table.insert(self.Tabs, tab)
	if not self.ActiveTab then
		tab:Select()
	end
	return tab
end

function Tab:Select()
	local window = self.Window
	if window.ActiveTab == self then
		return
	end
	if window.ActiveTab then
		window.ActiveTab:_setActive(false)
	end
	window.ActiveTab = self
	self:_setActive(true)
end

function Tab:_setActive(active)
	local theme = self.Window.Theme

	tween(self._button, 0.25, { BackgroundTransparency = active and theme.SelectedTransparency or 1 })
	tween(self._label, 0.25, { TextColor3 = active and theme.Text or theme.SubText })
	tween(self._indicator, 0.35, { Size = UDim2.fromOffset(3, active and 16 or 0) })
	if self._icon then
		tween(self._icon, 0.25, iconGoal(self._icon, active and theme.Accent or theme.SubText, active and 0 or 0.15))
	end

	self._page.Visible = active
	if active then
		self._page.Position = UDim2.fromOffset(0, 16)
		tween(self._page, 0.45, { Position = UDim2.new() })
	end
end

--------------------------------------------------------------------------------
-- Sections
--------------------------------------------------------------------------------

function Tab:CreateSection(name)
	if type(name) == "table" then
		name = name.Name
	end
	local theme = self.Window.Theme
	self._sections = self._sections + 1

	local holder = create("Frame", {
		Name = name or "Section",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = self._sections,
		Parent = self._page,
	}, { list(7) })

	if name and name ~= "" then
		create("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Font = FONT_BOLD,
			TextSize = 11,
			Text = string.upper(name),
			TextColor3 = theme.MutedText,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
			Parent = holder,
		}, { padding(0, 0, 0, 6) })
	end

	-- Elements sit together in one rounded card, split by thin dividers.
	local card = create("Frame", {
		Name = "Card",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Card,
		BackgroundTransparency = theme.CardTransparency,
		LayoutOrder = 2,
		Parent = holder,
	}, { corner(10), stroke(theme.Stroke, 0.94), list(0), padding(3, 0, 3, 0) })

	return setmetatable({
		Tab = self,
		Window = self.Window,
		_card = card,
		_count = 0,
	}, Section)
end

-- Shared row used by every element: divider, hover highlight, title, description.
-- `extraHeight` adds room under the text (the slider bar goes there).
function Section:_row(config, defaultName, extraHeight)
	local theme = self.Window.Theme
	self._count = self._count + 1
	extraHeight = extraHeight or 0
	local hasDescription = type(config.Description) == "string" and config.Description ~= ""
	local stacked = hasDescription or extraHeight > 0

	local row = create("TextButton", {
		Name = config.Name or defaultName,
		Size = UDim2.new(1, 0, 0, (hasDescription and 52 or 40) + extraHeight),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = self._count,
		Parent = self._card,
	})

	if self._count > 1 then
		create("Frame", {
			Name = "Divider",
			Position = UDim2.fromOffset(14, 0),
			Size = UDim2.new(1, -28, 0, 1),
			BackgroundColor3 = theme.Divider,
			BackgroundTransparency = theme.DividerTransparency,
			Parent = row,
		})
	end

	local hover = create("Frame", {
		Name = "Hover",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -8, 1, -6),
		BackgroundColor3 = theme.Hover,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = row,
	}, { corner(8) })

	local title = create("TextLabel", {
		Name = "Title",
		Position = UDim2.fromOffset(16, stacked and 10 or 0),
		Size = stacked and UDim2.new(1, -90, 0, 16) or UDim2.new(1, -90, 1, 0),
		BackgroundTransparency = 1,
		Font = FONT_MEDIUM,
		TextSize = 13,
		Text = config.Name or defaultName,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	if hasDescription then
		create("TextLabel", {
			Name = "Description",
			Position = UDim2.fromOffset(16, 28),
			Size = UDim2.new(1, -90, 0, 14),
			BackgroundTransparency = 1,
			Font = FONT,
			TextSize = 11,
			Text = config.Description,
			TextColor3 = theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
	end

	row.MouseEnter:Connect(function()
		tween(hover, 0.2, { BackgroundTransparency = theme.HoverTransparency })
	end)
	row.MouseLeave:Connect(function()
		tween(hover, 0.3, { BackgroundTransparency = 1 })
	end)

	return row, hover, title
end

--------------------------------------------------------------------------------
-- Elements
--------------------------------------------------------------------------------

function Section:CreateButton(config)
	config = config or {}
	local theme = self.Window.Theme
	local callback = config.Callback or function() end
	local row, hover, title = self:_row(config, "Button")

	local arrow = create("TextLabel", {
		Name = "Arrow",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(16, 20),
		BackgroundTransparency = 1,
		Font = FONT_BOLD,
		TextSize = 20,
		Text = "›",
		TextColor3 = theme.MutedText,
		Parent = row,
	})

	local function release()
		tween(arrow, 0.3, { Position = UDim2.new(1, -16, 0.5, 0), TextColor3 = theme.MutedText })
	end
	row.InputBegan:Connect(function(input)
		if isPress(input) then
			ripple(hover, input.Position)
			tween(arrow, 0.2, { Position = UDim2.new(1, -11, 0.5, 0), TextColor3 = theme.Accent })
		end
	end)
	row.InputEnded:Connect(function(input)
		if isPress(input) then
			release()
		end
	end)
	row.MouseLeave:Connect(release)
	row.Activated:Connect(function()
		task.spawn(callback)
	end)

	local button = { Instance = row }
	function button:SetText(text)
		title.Text = text
	end
	function button:SetCallback(fn)
		callback = fn
	end
	return button
end

function Section:CreateToggle(config)
	config = config or {}
	local theme = self.Window.Theme
	local callback = config.Callback or function() end
	local row = self:_row(config, "Toggle")

	local track = create("Frame", {
		Name = "Switch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(38, 22),
		BackgroundColor3 = theme.ToggleOff,
		Parent = row,
	}, { corner(ROUND) })

	local knob = create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track,
	}, { corner(ROUND) })

	local toggle = { Value = false, Instance = row }

	local function render(duration)
		local on = toggle.Value
		tween(track, duration, { BackgroundColor3 = on and theme.Accent or theme.ToggleOff }, Enum.EasingStyle.Quad)
		tween(knob, duration, {
			-- sliding the anchor too keeps the knob 2px from whichever edge it rests on
			AnchorPoint = Vector2.new(on and 1 or 0, 0.5),
			Position = UDim2.new(on and 1 or 0, on and -2 or 2, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
		})
	end

	function toggle:Set(value, silent)
		toggle.Value = value == true
		render(0.35)
		if not silent then
			task.spawn(callback, toggle.Value)
		end
	end

	function toggle:Get()
		return toggle.Value
	end

	-- the knob stretches while pressed, like a macOS / iOS switch
	local function unpress()
		tween(knob, 0.25, { Size = UDim2.fromOffset(18, 18) })
	end
	row.InputBegan:Connect(function(input)
		if isPress(input) then
			tween(knob, 0.2, { Size = UDim2.fromOffset(23, 18) })
		end
	end)
	row.InputEnded:Connect(function(input)
		if isPress(input) then
			unpress()
		end
	end)
	row.MouseLeave:Connect(unpress)
	row.Activated:Connect(function()
		toggle:Set(not toggle.Value)
	end)

	if config.Default then
		toggle.Value = true
		render(0)
	end

	return toggle
end

function Section:CreateSlider(config)
	config = config or {}
	local theme = self.Window.Theme
	local page = self.Tab._page
	local callback = config.Callback or function() end
	local min = config.Min or 0
	local max = config.Max or 100
	local increment = config.Increment or 1
	local suffix = config.Suffix or ""
	local range = math.max(max - min, 1e-9)
	local decimals = #(tostring(increment):match("%.(%d+)$") or "")
	local row = self:_row(config, "Slider", 18)

	local function format(value)
		return string.format("%." .. decimals .. "f", value)
	end

	-- rounds to the nearest step and strips float noise like 0.30000000000000004
	local function snap(value)
		value = math.clamp(value, min, max)
		value = min + math.floor((value - min) / increment + 0.5) * increment
		return tonumber(format(math.clamp(value, min, max)))
	end

	local valueBox = create("TextBox", {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 9),
		Size = UDim2.fromOffset(64, 18),
		BackgroundColor3 = theme.Hover,
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Font = FONT_MEDIUM,
		TextSize = 12,
		Text = "",
		TextColor3 = theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = row,
	}, { corner(5), padding(0, 6, 0, 6) })

	-- taller than the visible track so it's easy to grab
	local hitArea = create("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -8),
		Size = UDim2.new(1, -32, 0, 18),
		BackgroundTransparency = 1,
		Parent = row,
	})

	local track = create("Frame", {
		Name = "Track",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.new(1, 0, 0, 4),
		BackgroundColor3 = theme.ToggleOff,
		Parent = hitArea,
	}, { corner(ROUND) })

	local fill = create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = theme.Accent,
		Parent = track,
	}, { corner(ROUND) })

	local knob = create("Frame", {
		Name = "Knob",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, SLIDER_KNOB / 2, 0.5, 0),
		Size = UDim2.fromOffset(SLIDER_KNOB, SLIDER_KNOB),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track,
	}, { corner(ROUND), stroke(Color3.new(0, 0, 0), 0.75) })

	local slider = { Value = min, Instance = row }

	-- The knob stays inside the track: at 0% its left edge sits on the start,
	-- at 100% its right edge sits on the end.
	local function render(duration)
		local ratio = (slider.Value - min) / range
		local offset = SLIDER_KNOB * (0.5 - ratio)
		tween(fill, duration, { Size = UDim2.new(ratio, offset, 1, 0) })
		tween(knob, duration, { Position = UDim2.new(ratio, offset, 0.5, 0) })
		if not valueBox:IsFocused() then
			valueBox.Text = format(slider.Value) .. suffix
		end
	end

	function slider:Set(value, silent)
		value = snap(tonumber(value) or slider.Value)
		local changed = value ~= slider.Value
		slider.Value = value
		render(0.18)
		if changed and not silent then
			task.spawn(callback, value)
		end
	end

	function slider:Get()
		return slider.Value
	end

	local function slideTo(input)
		local width = math.max(track.AbsoluteSize.X - SLIDER_KNOB, 1)
		local ratio = math.clamp((input.Position.X - track.AbsolutePosition.X - SLIDER_KNOB / 2) / width, 0, 1)
		slider:Set(min + ratio * range)
	end

	table.insert(self.Window._connections, onDrag(hitArea, function(input)
		page.ScrollingEnabled = false -- keeps the page still while sliding on touch
		tween(knob, 0.2, { Size = UDim2.fromOffset(SLIDER_KNOB + 4, SLIDER_KNOB + 4) })
		slideTo(input)
	end, slideTo, function()
		page.ScrollingEnabled = true
		tween(knob, 0.25, { Size = UDim2.fromOffset(SLIDER_KNOB, SLIDER_KNOB) })
	end))

	valueBox.Focused:Connect(function()
		tween(valueBox, 0.2, { BackgroundTransparency = theme.SelectedTransparency, TextColor3 = theme.Text })
	end)
	valueBox.FocusLost:Connect(function()
		tween(valueBox, 0.2, { BackgroundTransparency = 1, TextColor3 = theme.SubText })
		-- "75" and "75%" both work; anything else just puts the old value back
		local typed = tonumber((valueBox.Text:gsub("[^%d%.%-]", "")))
		slider:Set(typed or slider.Value)
	end)

	slider.Value = snap(config.Default or min)
	render(0)

	return slider
end

-- Aliases for people used to other hub libraries.
Window.AddTab = Window.CreateTab
Tab.AddSection = Tab.CreateSection
Section.AddButton = Section.CreateButton
Section.AddToggle = Section.CreateToggle
Section.AddSlider = Section.CreateSlider

return Library
