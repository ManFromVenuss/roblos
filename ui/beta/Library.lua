local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local DEBUG = false

local _rawget = rawget
local _type = type
local _typeof = typeof
local _pcall = pcall
local _tostring = tostring
local _setmetatable = setmetatable

local Color3_new = Color3.new
local Color3_fromRGB = Color3.fromRGB
local Color3_fromHSV = Color3.fromHSV
local Color3_toHSV = Color3.toHSV
local UDim_new = UDim.new
local UDim2_new = UDim2.new
local UDim2_fromOff = UDim2.fromOffset
local UDim2_fromScale = UDim2.fromScale
local Vector2_new = Vector2.new
local math_clamp = math.clamp
local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local math_huge = math.huge
local table_insert = table.insert
local table_remove = table.remove
local table_find = table.find
local table_concat = table.concat
local table_create = table.create
local table_clone = (table).clone
local table_freeze = (table).freeze
local string_char = string.char
local string_format = string.format
local task_delay = task.delay
local task_defer = task.defer
local Instance_new = Instance.new

local function DBG_warn(...)
	if not DEBUG then return end
	warn(...)
end

local writefile_fn
local readfile_fn
local isfile_fn
local isfolder_fn
local makefolder_fn
local listfiles_fn
local delfile_fn
local gethui_fn
local protect_resolved

do
	local _getfenv = getfenv
	local _env = _G
	_pcall(function() _env = _getfenv(0) end)
	if _env == _G then
		_pcall(function() _env = _getfenv(1) end)
	end

	local function fetch(name)
		local v
		_pcall(function() v = _rawget(_env, name) end)
		if _type(v) == "function" then return v end
		v = nil
		_pcall(function() v = _rawget(_G, name) end)
		if _type(v) == "function" then return v end
		v = nil
		_pcall(function() v = (_env)[name] end)
		if _type(v) == "function" then return v end
		v = nil
		_pcall(function() v = (_G)[name] end)
		if _type(v) == "function" then return v end
		return nil
	end
	local function fetchTable(name)
		local v
		_pcall(function() v = _rawget(_env, name) end)
		if _type(v) == "table" then return v end
		v = nil
		_pcall(function() v = _rawget(_G, name) end)
		if _type(v) == "table" then return v end
		v = nil
		_pcall(function() v = (_env)[name] end)
		if _type(v) == "table" then return v end
		v = nil
		_pcall(function() v = (_G)[name] end)
		if _type(v) == "table" then return v end
		return nil
	end
	local function fetchField(tbl, field)
		if _type(tbl) ~= "table" then return nil end
		local v
		_pcall(function() v = _rawget(tbl, field) end)
		if _type(v) == "function" then return v end
		v = nil
		_pcall(function() v = (tbl)[field] end)
		if _type(v) == "function" then return v end
		return nil
	end

	local N_writefile = string_char(119,114,105,116,101,102,105,108,101)
	local N_readfile = string_char(114,101,97,100,102,105,108,101)
	local N_isfile = string_char(105,115,102,105,108,101)
	local N_isfolder = string_char(105,115,102,111,108,100,101,114)
	local N_makefolder = string_char(109,97,107,101,102,111,108,100,101,114)
	local N_listfiles = string_char(108,105,115,116,102,105,108,101,115)
	local N_delfile = string_char(100,101,108,102,105,108,101)
	local N_gethui = string_char(103,101,116,104,117,105)
	local N_protectgui1 = string_char(112,114,111,116,101,99,116,95,103,117,105)
	local N_protectgui2 = string_char(112,114,111,116,101,99,116,103,117,105)
	local N_syn = string_char(115,121,110)
	local N_fluxus = string_char(102,108,117,120,117,115)
	local N_fstbl = string_char(102,105,108,101,115,121,115,116,101,109)

	writefile_fn = fetch(N_writefile)
	readfile_fn = fetch(N_readfile)
	isfile_fn = fetch(N_isfile)
	isfolder_fn = fetch(N_isfolder)
	makefolder_fn = fetch(N_makefolder)
	listfiles_fn = fetch(N_listfiles)
	delfile_fn = fetch(N_delfile)
	gethui_fn = fetch(N_gethui)
	local fsTbl = fetchTable(N_fstbl)
	if fsTbl then
		if not writefile_fn then writefile_fn = fetchField(fsTbl, N_writefile) end
		if not readfile_fn then readfile_fn = fetchField(fsTbl, N_readfile) end
		if not isfile_fn then isfile_fn = fetchField(fsTbl, N_isfile) end
		if not isfolder_fn then isfolder_fn = fetchField(fsTbl, N_isfolder) end
		if not makefolder_fn then makefolder_fn = fetchField(fsTbl, N_makefolder) end
		if not listfiles_fn then listfiles_fn = fetchField(fsTbl, N_listfiles) end
		if not delfile_fn then delfile_fn = fetchField(fsTbl, N_delfile) end
	end

	local protectCandidates = {}
	local pgGlobal = fetch(N_protectgui1) or fetch(N_protectgui2)
	if pgGlobal then table_insert(protectCandidates, pgGlobal) end
	local synTbl = fetchTable(N_syn)
	if synTbl then
		local f = fetchField(synTbl, N_protectgui1)
		if f then table_insert(protectCandidates, f) end
	end
	local fluxTbl = fetchTable(N_fluxus)
	if fluxTbl then
		local f = fetchField(fluxTbl, N_protectgui1)
		if f then table_insert(protectCandidates, f) end
	end

	if #protectCandidates > 0 then
		protect_resolved = function(gui)
			for i = 1, #protectCandidates do
				local ok = _pcall(protectCandidates[i], gui)
				if ok then
					if not gui.Parent then return false end
					local visible = false
					local probed = false
					_pcall(function()
						probed = true
						for _, c in CoreGui:GetChildren() do
							if c == gui then visible = true; break end
						end
					end)
					if probed and not visible then return true end
				end
			end
			return false
		end
	end
end

local hasFS = writefile_fn ~= nil and readfile_fn ~= nil

local function getGuiParent()
	if gethui_fn then
		local ok, hui = _pcall(gethui_fn)
		if ok and _typeof(hui) == "Instance" then return hui, true end
	end
	if RunService:IsRunning() and not RunService:IsStudio() then
		local pg = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if pg then return pg, false end
	end
	return CoreGui, false
end

local function protectGui(gui)
	if protect_resolved then return protect_resolved(gui) end
	return false
end

local NAME_POOL = {
	"", "", "",
	"Frame", "Container", "Manager", "Panel", "View",
	"GuiContainer", "ContentProvider", "RenderTarget",
	"InputContainer", "ScrollHost", "TextureService",
	"ContentManager", "ViewModel", "OverlayHost",
}
local _nameRng = Random.new()
local function pickRandomGuiName()
	return NAME_POOL[_nameRng:NextInteger(1, #NAME_POOL)]
end

local Maid = {}
Maid.__index = Maid
Maid.__metatable = "locked"

local function disposeTask(t)
	if _type(t) == "function" then
		local ok, err = _pcall(t)
		if not ok then DBG_warn("[Shenanigans] Maid fn:", err) end
	elseif _typeof(t) == "RBXScriptConnection" then
		(t):Disconnect()
	elseif _typeof(t) == "Instance" then
		(t):Destroy()
	elseif _type(t) == "table" then
		if t.Destroy then
			local ok, err = _pcall(t.Destroy, t)
			if not ok then DBG_warn("[Shenanigans] Maid Destroy:", err) end
		elseif t.Disconnect then
			local ok, err = _pcall(t.Disconnect, t)
			if not ok then DBG_warn("[Shenanigans] Maid Disconnect:", err) end
		end
	end
end

local function newMaid()
	return _setmetatable({ _tasks = {}, _destroyed = false }, Maid)
end

function Maid:Add(task)
	if self._destroyed then
		disposeTask(task)
		return task
	end
	table_insert(self._tasks, task)
	return task
end

function Maid:Remove(task)
	local idx = table_find(self._tasks, task)
	if idx then table_remove(self._tasks, idx) end
end

function Maid:Clean()
	local tasks = self._tasks
	self._tasks = {}
	for i = #tasks, 1, -1 do
		disposeTask(tasks[i])
	end
end

function Maid:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	self:Clean()
end

local function make(class, props)
	local inst = Instance_new(class)
	local parent = props.Parent
	props.Parent = nil
	for k, v in props do
		inst[k] = v
	end
	if parent then inst.Parent = parent end
	return inst
end

local function corner(radius, parent)
	local c = Instance_new("UICorner")
	c.CornerRadius = UDim_new(0, radius)
	c.Parent = parent
	return c
end

local function stroke(color, thickness, parent)
	local s = Instance_new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function padding(t, b, l, r, parent)
	local p = Instance_new("UIPadding")
	p.PaddingTop = UDim_new(0, t)
	p.PaddingBottom = UDim_new(0, b)
	p.PaddingLeft = UDim_new(0, l)
	p.PaddingRight = UDim_new(0, r)
	p.Parent = parent
	return p
end

local function safeCall(fn, ...)
	if _type(fn) ~= "function" then return end
	local args = table.pack(...)
	local res = table.pack(_pcall(fn, table.unpack(args, 1, args.n)))
	if not res[1] then
		DBG_warn("[Shenanigans] user callback error:", res[2])
		return
	end
	return table.unpack(res, 2, res.n)
end

local function isFiniteNumber(x)
	return _type(x) == "number" and x == x and x ~= math_huge and x ~= -math_huge
end

local function rbxAsset(id)
	return "rbxassetid://" .. _tostring(id)
end

local function rbxThumb(userId)
	return "rbxthumb://type=AvatarHeadShot&id=" .. _tostring(userId) .. "&w=48&h=48"
end

local Theme = {
	Background = Color3_fromRGB(18, 18, 20),
	Surface = Color3_fromRGB(24, 24, 27),
	SurfaceAlt = Color3_fromRGB(30, 30, 34),
	SurfaceHover = Color3_fromRGB(38, 38, 42),
	Border = Color3_fromRGB(45, 45, 50),
	Text = Color3_fromRGB(230, 230, 232),
	SubText = Color3_fromRGB(150, 150, 155),
	Muted = Color3_fromRGB(95, 95, 100),
	Accent = Color3_fromRGB(83, 145, 255),
	AccentDim = Color3_fromRGB(58, 102, 179),
	Danger = Color3_fromRGB(220, 90, 90),
	Success = Color3_fromRGB(120, 200, 130),
}
if table_freeze then _pcall(table_freeze, Theme) end

local function isValidConfigName(n)
	return _type(n) == "string" and #n > 0 and #n <= 64 and not (n):match("[^%w_%-]")
end

local InputRouter
do

	local SLOT_WARN = 256
	local SLOT_HARD_CAP = 4096

	local function newChannel()
		return { list = {}, ver = 0, dispatchedVer = -1, snap = nil, warned = false }
	end

	local began = newChannel()
	local changed = newChannel()
	local ended = newChannel()

	local function dispatch(ch, label, input, gp)
		local list = ch.list
		local n = #list
		if n == 0 then
			ch.snap = nil
			ch.dispatchedVer = ch.ver
			return
		end
		local snap = ch.snap
		if snap == nil or ch.dispatchedVer ~= ch.ver then
			snap = table_create(n)
			for i = 1, n do snap[i] = list[i] end
			ch.snap = snap
			ch.dispatchedVer = ch.ver
		end
		local sn = #snap
		for i = 1, sn do
			local s = snap[i]
			if s then
				local ok, err = _pcall(s.fn, input, gp)
				if not ok then DBG_warn("[Shenanigans] InputRouter cb:", err) end
			end
		end
	end

	local conn1 = UserInputService.InputBegan:Connect(function(input, gp)
		dispatch(began, "began", input, gp)
	end)
	local conn2 = UserInputService.InputChanged:Connect(function(input, gp)
		dispatch(changed, "changed", input, gp)
	end)
	local conn3 = UserInputService.InputEnded:Connect(function(input, gp)
		dispatch(ended, "ended", input, gp)
	end)

	local function connect(ch, label, fn)
		if #ch.list >= SLOT_HARD_CAP then
			DBG_warn("[Shenanigans] InputRouter '" .. label .. "' hit hard cap; refusing")
			return function() end
		end
		local slot = { fn = fn }
		table_insert(ch.list, slot)
		ch.ver += 1
		if #ch.list > SLOT_WARN and not ch.warned then
			ch.warned = true
			DBG_warn(string_format("[Shenanigans] InputRouter '%s' has %d slots; potential leak", label, #ch.list))
		end
		return function()
			local idx = table_find(ch.list, slot)
			if idx then
				table_remove(ch.list, idx)
				ch.ver += 1
			end
		end
	end

	InputRouter = {
		OnBegan = function(fn) return connect(began, "began", fn) end,
		OnChanged = function(fn) return connect(changed, "changed", fn) end,
		OnEnded = function(fn) return connect(ended, "ended", fn) end,
		_destroy = function()
			conn1:Disconnect(); conn2:Disconnect(); conn3:Disconnect()
			began.list = {}; began.snap = nil
			changed.list = {}; changed.snap = nil
			ended.list = {}; ended.snap = nil
		end,
	}
end

local function makeDraggable(target, handle, maid)
	local dragMaid = nil
	local startPos = nil
	local dragStart = nil

	local function endDrag()
		if dragMaid then
			dragMaid:Destroy()
			dragMaid = nil
		end
	end

	maid:Add(handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if dragMaid then return end
		dragStart = input.Position
		startPos = target.Position
		local dm = newMaid()
		dragMaid = dm
		dm:Add(InputRouter.OnChanged(function(input2)
			if input2.UserInputType ~= Enum.UserInputType.MouseMovement and input2.UserInputType ~= Enum.UserInputType.Touch then return end
			local ds = dragStart
			local sp = startPos
			local d = input2.Position - ds
			target.Position = UDim2_new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end))
		dm:Add(InputRouter.OnEnded(function(input2)
			if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
				endDrag()
			end
		end))
	end))
	maid:Add(function() endDrag() end)
end

local function createTooltipSystem(parent)
	local tipFrame = make("Frame", {
		Parent = parent,
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Visible = false,
		Size = UDim2_fromOff(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		ZIndex = 999,
	})
	corner(4, tipFrame)
	stroke(Theme.Border, 1, tipFrame)
	padding(4, 4, 8, 8, tipFrame)
	local tipLabel = make("TextLabel", {
		Parent = tipFrame,
		BackgroundTransparency = 1,
		Size = UDim2_fromOff(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text,
		Text = "", ZIndex = 1000,
	})

	local current = nil
	local moveUnbind = InputRouter.OnChanged(function(input)
		if not tipFrame.Visible then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		tipFrame.Position = UDim2_fromOff(input.Position.X + 14, input.Position.Y + 18)
	end)

	local function attach(host, text, maid)
		if not text or text == "" then return end
		maid:Add(host.MouseEnter:Connect(function()
			current = host
			tipLabel.Text = text
			tipFrame.Visible = true
		end))
		maid:Add(host.MouseLeave:Connect(function()
			if current == host then
				current = nil
				tipFrame.Visible = false
			end
		end))
	end

	local destroyed = false
	local function destroy()
		if destroyed then return end
		destroyed = true
		moveUnbind()
		if tipFrame.Parent then tipFrame:Destroy() end
	end
	return { Attach = attach, Destroy = destroy }
end

local MAX_VISIBLE_NOTIFICATIONS = 6

local function createNotificationSystem(parent)
	local container = make("Frame", {
		Parent = parent,
		AnchorPoint = Vector2_new(1, 1),
		Position = UDim2_new(1, -16, 1, -16),
		Size = UDim2_fromOff(280, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 800,
	})
	make("UIListLayout", {
		Parent = container,
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim_new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local cards = {}
	local generation = 0
	local destroyed = false

	local function variantColor(variant)
		if variant == "Success" then return Theme.Success
		elseif variant == "Danger" then return Theme.Danger
		elseif variant == "Warning" then return Theme.Danger
		end
		return Theme.AccentDim
	end

	local function push(opts)
		if destroyed then return end
		while #cards >= MAX_VISIBLE_NOTIFICATIONS do
			local oldest = cards[1]
			table_remove(cards, 1)
			if oldest and oldest.Parent then oldest:Destroy() end
		end
		local duration = opts.Duration or 3
		if not isFiniteNumber(duration) or duration <= 0 then duration = 3 end
		local title = opts.Title or "Notification"
		local content = opts.Content or ""
		local card = make("Frame", {
			Parent = container,
			BackgroundColor3 = Theme.Surface,
			Size = UDim2_new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BorderSizePixel = 0,
			ZIndex = 800,
		})
		corner(6, card)
		local cardStroke = stroke(variantColor(opts.Variant), 1, card)
		cardStroke.Transparency = 0.55
		make("TextLabel", {
			Parent = card,
			BackgroundTransparency = 1,
			Position = UDim2_new(0, 12, 0, 8),
			Size = UDim2_new(1, -24, 0, 16),
			Font = Enum.Font.GothamMedium, TextSize = 13,
			TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			Text = title, ZIndex = 801,
		})
		make("TextLabel", {
			Parent = card,
			BackgroundTransparency = 1,
			Position = UDim2_new(0, 12, 0, 28),
			Size = UDim2_new(1, -24, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham, TextSize = 12,
			TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
			Text = content, TextWrapped = true, ZIndex = 801,
		})
		make("UIPadding", { Parent = card, PaddingBottom = UDim_new(0, 10) })
		table_insert(cards, card)

		local myGen = generation
		task_delay(duration, function()
			if destroyed or myGen ~= generation then return end
			if not card.Parent then
				local idx = table_find(cards, card)
				if idx then table_remove(cards, idx) end
				return
			end
			local idx = table_find(cards, card)
			if idx then table_remove(cards, idx) end
			card:Destroy()
		end)
	end

	local function destroy()
		if destroyed then return end
		destroyed = true
		generation += 1
		for _, c in cards do
			if c.Parent then c:Destroy() end
		end
		cards = {}
		if container.Parent then container:Destroy() end
	end
	return { Push = push, Destroy = destroy }
end

local Components = {}

local Section = {} ; Section.__index = Section ; Section.__metatable = "locked"
local Tab = {} ; Tab.__index = Tab ; Tab.__metatable = "locked"
local Window = {} ; Window.__index = Window ; Window.__metatable = "locked"
local UILibrary = {} ; UILibrary.__index = UILibrary ; UILibrary.__metatable = "locked"
local Component = {} ; Component.__index = Component ; Component.__metatable = "locked"

function Component:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	if self._flag then
		local w = self._section and self._section._window
		if w and w._fs then w._fs.unregister(self._flag) end
	end
	if self._maid then self._maid:Destroy() end
end

function Component:SetVisible(v)
	if self.instance then self.instance.Visible = v end
end

function Section.new(tab, opts)
	local self = _setmetatable({}, Section)
	self._tab = tab
	self._window = tab._window
	self._maid = newMaid()
	self._visible = true
	self._destroyed = false

	local collapsible = opts.Collapsible ~= false
	local open = opts.DefaultOpen ~= false
	self._collapsible = collapsible
	self._open = open

	local frame = make("Frame", {
		BackgroundColor3 = Theme.Surface,
		Size = UDim2_new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
	})
	self._frame = frame
	frame.Parent = tab:_acquireSectionParent(self)
	corner(6, frame)
	local sStroke = stroke(Theme.AccentDim, 1, frame)
	sStroke.Transparency = 0.55
	self._maid:Add(frame)

	local titleClass = collapsible and "TextButton" or "TextLabel"
	local titleProps = {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 12, 0, 10),
		Size = UDim2_new(1, -24, 0, 16),
		Font = Enum.Font.GothamMedium, TextSize = 13,
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "Section",
	}
	if collapsible then titleProps.AutoButtonColor = false end
	local title = make(titleClass, titleProps)

	local chevron = nil
	if collapsible then
		chevron = make("TextLabel", {
			Parent = frame,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2_new(1, 0.5),
			Position = UDim2_new(1, -12, 0, 18),
			Size = UDim2_new(0, 16, 0, 16),
			Font = Enum.Font.GothamBold, TextSize = 16,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Text = open and "-" or "+",
		})
	end

	local content = make("Frame", {
		Parent = frame,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 8, 0, 32),
		Size = UDim2_new(1, -16, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = open,
	})
	make("UIPadding", { Parent = frame, PaddingBottom = UDim_new(0, 10) })
	make("UIListLayout", {
		Parent = content,
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim_new(0, 6),
	})
	self._content = content
	self._chevron = chevron
	self._components = {}

	if collapsible then
		self._maid:Add(title.MouseButton1Click:Connect(function()
			self:SetOpen(not self._open)
		end))
	end
	return self
end

function Section:SetOpen(v)
	if not self._collapsible then return end
	if self._open == v then return end
	self._open = v
	self._content.Visible = v
	if self._chevron then self._chevron.Text = v and "-" or "+" end

	local f = self._frame
	if f then
		f.AutomaticSize = Enum.AutomaticSize.None
		f.AutomaticSize = Enum.AutomaticSize.Y
	end
	local list = self._content and self._content:FindFirstChildOfClass("UIListLayout")
	if list then local _ = list.AbsoluteContentSize end
end
function Section:IsOpen() return self._open == true end
function Section:_addComponent(c) table_insert(self._components, c) end
function Section:SetVisible(v)
	self._visible = v
	if self._frame then self._frame.Visible = v end
end

function Section:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	for _, c in self._components do
		if _type(c) == "table" and (c).Destroy then
			local ok, err = _pcall((c).Destroy, c)
			if not ok then DBG_warn("[Shenanigans] component destroy:", err) end
		end
	end
	self._components = {}
	if self._tab and not self._tab._destroyed and self._tab._unregisterSection then
		self._tab:_unregisterSection(self)
	end
	self._maid:Destroy()
end

local HOVER_NORMAL = Theme.SurfaceAlt
local HOVER_BRIGHT = Theme.SurfaceHover

local function makeRow(parent, height)
	local row = make("Frame", {
		Parent = parent,
		BackgroundColor3 = HOVER_NORMAL,
		Size = UDim2_new(1, 0, 0, height or 32),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	corner(6, row)
	local s = stroke(Theme.Accent, 1, row)
	s.Transparency = 1
	return row, s
end

local function hoverRow(row, host, maid)
	maid:Add(host.MouseEnter:Connect(function()
		row.BackgroundColor3 = HOVER_BRIGHT
	end))
	maid:Add(host.MouseLeave:Connect(function()
		row.BackgroundColor3 = HOVER_NORMAL
	end))
end

local function rowLabel(parent, text)
	return make("TextLabel", {
		Parent = parent,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 10, 0, 0),
		Size = UDim2_new(1, -20, 1, 0),
		Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = text,
	})
end

function Components.Label(section, opts)
	local maid = newMaid()
	local lbl = make("TextLabel", {
		Parent = section._content,
		BackgroundTransparency = 1,
		Size = UDim2_new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Text = _tostring(opts.Text or ""),
	})
	maid:Add(lbl)
	local api = _setmetatable({
		instance = lbl, _maid = maid, _section = section, _destroyed = false,
		Set = function(_, t) lbl.Text = _tostring(t or "") end,
		Get = function() return lbl.Text end,
	}, Component)
	section:_addComponent(api)
	return api
end

function Components.Button(section, opts)
	local maid = newMaid()
	local row = makeRow(section._content, 32)
	row.Parent = section._content
	maid:Add(row)
	local btn = make("TextButton", {
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2_new(1, 0, 1, 0),
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = Theme.Text,
		Text = opts.Name or "Button",
	})
	hoverRow(row, btn, maid)
	maid:Add(btn.MouseButton1Click:Connect(function()
		safeCall(opts.Callback)
	end))
	if section._window._tooltips then
		section._window._tooltips.Attach(row, opts.Tooltip, maid)
	end
	local api = _setmetatable({
		instance = row, _maid = maid, _section = section, _destroyed = false,
		Set = function() end, Get = function() return nil end,
	}, Component)
	section:_addComponent(api)
	return api
end

function Components.Separator(section, opts)
	opts = opts or {}
	local thickness = (opts and opts.Thickness) or 1
	local maid = newMaid()
	local total = thickness + 8
	local container = make("Frame", {
		Parent = section._content,
		BackgroundTransparency = 1,
		Size = UDim2_new(1, 0, 0, total),
		BorderSizePixel = 0,
	})
	maid:Add(container)
	local line = make("Frame", {
		Parent = container,
		AnchorPoint = Vector2_new(0.5, 0.5),
		Position = UDim2_new(0.5, 0, 0.5, 0),
		Size = UDim2_new(1, -8, 0, thickness),
		BackgroundColor3 = Theme.Border,
		BorderSizePixel = 0,
	})
	if opts and opts.Label then
		line.Visible = false
		make("TextLabel", {
			Parent = container,
			BackgroundTransparency = 1,
			Size = UDim2_new(1, 0, 1, 0),
			Font = Enum.Font.Gotham, TextSize = 11,
			TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = " " .. _tostring(opts.Label),
		})
	end
	local api = _setmetatable({
		instance = container, _maid = maid, _section = section, _destroyed = false,
		Set = function() end, Get = function() return nil end,
	}, Component)
	section:_addComponent(api)
	return api
end

local function isMouseButtonInput(v)
	if _typeof(v) ~= "EnumItem" then return false end
	local uv = v
	return uv.EnumType == Enum.UserInputType and (uv == Enum.UserInputType.MouseButton1 or uv == Enum.UserInputType.MouseButton2 or uv == Enum.UserInputType.MouseButton3)
end

local function isValidKeybindValue(v)
	if _typeof(v) ~= "EnumItem" then return false end
	return (v).EnumType == Enum.KeyCode or isMouseButtonInput(v)
end

local function isKeybindUnset(v)
	return _typeof(v) == "EnumItem" and (v).EnumType == Enum.KeyCode and (v) == Enum.KeyCode.Unknown
end

local function keybindDisplayText(v)
	return isKeybindUnset(v) and "..." or (v).Name
end

local function matchesKeybind(input, v)
	if not isValidKeybindValue(v) or isKeybindUnset(v) then return false end
	if isMouseButtonInput(v) then
		return input.UserInputType == (v)
	end
	return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == (v)
end

function Components.Toggle(
	section,
	opts
)
	local maid = newMaid()
	local fs = section._window._fs
	local state = opts.Default == true
	local hasKb = opts.Keybind == true

	local row = makeRow(section._content, 32)
	row.Parent = section._content
	maid:Add(row)

	local btn = make("TextButton", {
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2_new(1, 0, 1, 0),
		Text = "", AutoButtonColor = false,
	})

	local lbl = rowLabel(row, opts.Name or "Toggle")
	if hasKb then lbl.Size = UDim2_new(1, -108, 1, 0) end

	local kbBtn = nil
	local kbKey = isValidKeybindValue(opts.DefaultKey) and opts.DefaultKey or Enum.KeyCode.Unknown
	local kbListening = false
	local kbLastSetTime = 0

	if hasKb then
		kbBtn = make("TextButton", {
			Parent = row,
			AnchorPoint = Vector2_new(1, 0.5),
			Position = UDim2_new(1, -54, 0.5, 0),
			Size = UDim2_fromOff(36, 20),
			BackgroundColor3 = Theme.Surface,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = Enum.Font.Gotham, TextSize = 10,
			TextColor3 = Theme.Text,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Text = "...",
		})
		corner(4, kbBtn)
	end

	local track = make("Frame", {
		Parent = row,
		AnchorPoint = Vector2_new(1, 0.5),
		Position = UDim2_new(1, -10, 0.5, 0),
		Size = UDim2_fromOff(34, 18),
		BackgroundColor3 = Theme.Border, BorderSizePixel = 0,
	})
	corner(9, track)
	local knob = make("Frame", {
		Parent = track,
		AnchorPoint = Vector2_new(0, 0.5),
		Position = UDim2_new(0, 2, 0.5, 0),
		Size = UDim2_fromOff(14, 14),
		BackgroundColor3 = Theme.Text, BorderSizePixel = 0,
	})
	corner(7, knob)

	local api = _setmetatable({
		instance = row, _maid = maid, _section = section,
		_flag = opts.Flag, _destroyed = false,
	}, Component)

	local function render(fire)
		if state then
			track.BackgroundColor3 = Theme.Accent
			knob.Position = UDim2_new(1, -16, 0.5, 0)
		else
			track.BackgroundColor3 = Theme.Border
			knob.Position = UDim2_new(0, 2, 0.5, 0)
		end
		if opts.Flag and fs then fs.write(opts.Flag, state) end
		if fire ~= false then safeCall(opts.Callback, state) end
	end

	function api:Set(v) state = v == true; render() end
	function api:Get() return state end

	maid:Add(btn.MouseButton1Click:Connect(function()
		state = not state
		render()
	end))
	hoverRow(row, row, maid)

	local function updateKbText()
		if kbBtn then
			kbBtn.Text = keybindDisplayText(kbKey)
		end
	end

	local keyFlag = (hasKb and opts.Flag) and (opts.Flag .. "Key") or nil

	if hasKb and kbBtn then
		maid:Add(kbBtn.MouseButton1Click:Connect(function()
			if (os.clock() - kbLastSetTime) < 0.15 then return end
			kbListening = true
			kbBtn.Text = "..."
		end))
		maid:Add(InputRouter.OnBegan(function(input, gp)
			if gp then return end
			if kbListening then
				local newKey
				if input.UserInputType == Enum.UserInputType.Keyboard then
					newKey = input.KeyCode
				elseif isMouseButtonInput(input.UserInputType) then
					newKey = input.UserInputType
				end
				if newKey then
					kbKey = newKey
					kbListening = false
					kbLastSetTime = os.clock()
					updateKbText()
					if keyFlag and fs then fs.write(keyFlag, kbKey) end
				end
				return
			end
			if matchesKeybind(input, kbKey) then
				state = not state
				render()
				local w = section and section._window
				if w and w.Notify then
					_pcall(w.Notify, w, {
						Title = opts.Name or "Toggle",
						Content = (state and "ON" or "OFF") .. " ["..kbKey.Name.."]" ,
						Duration = 1.5,
					})
				end
			end
		end))
	end

	function api:GetKey() return kbKey end
	function api:SetKey(v)
		if isValidKeybindValue(v) then
			kbKey = v
			updateKbText()
			if keyFlag and fs then fs.write(keyFlag, kbKey) end
		end
	end

	if opts.Flag and fs then
		fs.register(opts.Flag, state, function(v) api:Set(v) end)
	end
	if keyFlag and fs then
		fs.register(keyFlag, kbKey, function(v) api:SetKey(v) end)
	end
	render(false)
	updateKbText()

	if section._window._tooltips then
		section._window._tooltips.Attach(row, opts.Tooltip, maid)
	end

	section:_addComponent(api)
	return api
end

function Components.Slider(
	section,
	opts
)
	local maid = newMaid()
	local fs = section._window._fs
	local minV = (isFiniteNumber(opts.Min) and (opts.Min)) or 0
	local maxV = (isFiniteNumber(opts.Max) and (opts.Max)) or 100
	if maxV <= minV then maxV = minV + 1 end
	local span = maxV - minV
	local inc = (isFiniteNumber(opts.Increment) and (opts.Increment)) or 1
	if inc < 0 then inc = 0 end
	local val = (isFiniteNumber(opts.Default) and (opts.Default)) or minV
	local suffix = opts.Suffix or ""

	local row = makeRow(section._content, 44)
	row.Parent = section._content
	maid:Add(row)
	hoverRow(row, row, maid)

	make("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 10, 0, 6),
		Size = UDim2_new(1, -20, 0, 16),
		Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "Slider",
	})

	local valueLbl = make("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 10, 0, 6),
		Size = UDim2_new(1, -20, 0, 16),
		Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
	})

	local bar = make("Frame", {
		Parent = row,
		Position = UDim2_new(0, 10, 1, -14),
		Size = UDim2_new(1, -20, 0, 6),
		BackgroundColor3 = Theme.Border, BorderSizePixel = 0,
	})
	corner(3, bar)
	local fill = make("Frame", {
		Parent = bar,
		BackgroundColor3 = Theme.Accent,
		Size = UDim2_new(0, 0, 1, 0),
		BorderSizePixel = 0,
	})
	corner(3, fill)

	local function snap(x)
		if not isFiniteNumber(x) then return minV end
		local raw = x
		if inc > 0 then
			raw = math_floor((raw - minV) / inc + 0.5) * inc + minV
		end
		return math_clamp(raw, minV, maxV)
	end

	local api = _setmetatable({
		instance = row, _maid = maid, _section = section,
		_flag = opts.Flag, _destroyed = false,
	}, Component)

	local function render(fire)
		val = snap(val)
		local t = (val - minV) / span
		fill.Size = UDim2_new(t, 0, 1, 0)
		local text = (inc < 1) and string_format("%.2f", val) or _tostring(math_floor(val + 0.5))
		valueLbl.Text = text .. suffix
		if opts.Flag and fs then fs.write(opts.Flag, val) end
		if fire ~= false then safeCall(opts.Callback, val) end
	end

	function api:Set(v)
		if isFiniteNumber(v) then val = v; render() end
	end
	function api:Get() return val end

	local dragMaid = nil
	local barX, barW = 0, 1
	local function setFromX(x)
		local t = math_clamp((x - barX) / barW, 0, 1)
		val = minV + t * span
		render()
	end
	local function endDrag()
		if dragMaid then
			dragMaid:Destroy()
			dragMaid = nil
		end
	end
	maid:Add(bar.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if dragMaid then return end
		barX = bar.AbsolutePosition.X
		barW = math_max(1, bar.AbsoluteSize.X)
		setFromX(input.Position.X)
		local dm = newMaid()
		dragMaid = dm
		dm:Add(InputRouter.OnChanged(function(input2)
			if input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch then
				setFromX(input2.Position.X)
			end
		end))
		dm:Add(InputRouter.OnEnded(function(input2)
			if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
				endDrag()
			end
		end))
	end))
	maid:Add(function() endDrag() end)

	if opts.Flag and fs then
		fs.register(opts.Flag, val, function(v) api:Set(v) end)
	end
	render(false)

	if section._window._tooltips then
		section._window._tooltips.Attach(row, opts.Tooltip, maid)
	end

	section:_addComponent(api)
	return api
end

function Components.Keybind(
	section,
	opts
)
	local maid = newMaid()
	local fs = section._window._fs
	local key = isValidKeybindValue(opts.Default) and opts.Default or Enum.KeyCode.Unknown
	local listening = false
	local lastSetTime = 0

	local row = makeRow(section._content, 32)
	row.Parent = section._content
	maid:Add(row)
	hoverRow(row, row, maid)
	rowLabel(row, opts.Name or "Keybind")

	local btn = make("TextButton", {
		Parent = row,
		AnchorPoint = Vector2_new(1, 0.5),
		Position = UDim2_new(1, -10, 0.5, 0),
		Size = UDim2_fromOff(54, 22),
		BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = Theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
	})
	corner(4, btn)

	local api = _setmetatable({
		instance = row, _maid = maid, _section = section,
		_flag = opts.Flag, _destroyed = false,
	}, Component)

	local function render()
		btn.Text = keybindDisplayText(key)
		if opts.Flag and fs then fs.write(opts.Flag, key) end
	end
	function api:Set(v)
		if isValidKeybindValue(v) then key = v; render() end
	end
	function api:Get() return key end

	maid:Add(btn.MouseButton1Click:Connect(function()
		if (os.clock() - lastSetTime) < 0.15 then return end
		listening = true
		btn.Text = "..."
	end))
	maid:Add(InputRouter.OnBegan(function(input, gp)
		if gp then return end
		if listening then
			local newKey
			if input.UserInputType == Enum.UserInputType.Keyboard then
				newKey = input.KeyCode
			elseif isMouseButtonInput(input.UserInputType) then
				newKey = input.UserInputType
			end
			if newKey then
				key = newKey
				listening = false
				lastSetTime = os.clock()
				render()
				safeCall(opts.Callback, key, "set")
			end
			return
		end
		if matchesKeybind(input, key) then
			safeCall(opts.Callback, key, "pressed")
		end
	end))

	if opts.Flag and fs then
		fs.register(opts.Flag, key, function(v) api:Set(v) end)
	end
	render()

	if section._window._tooltips then
		section._window._tooltips.Attach(row, opts.Tooltip, maid)
	end

	section:_addComponent(api)
	return api
end

function Components.Textbox(
	section,
	opts
)
	local maid = newMaid()
	local fs = section._window._fs
	local row = makeRow(section._content, 56)
	row.Parent = section._content
	maid:Add(row)
	hoverRow(row, row, maid)

	make("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 10, 0, 6),
		Size = UDim2_new(1, -20, 0, 16),
		Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "Textbox",
	})

	local input = make("TextBox", {
		Parent = row,
		Position = UDim2_new(0, 10, 0, 26),
		Size = UDim2_new(1, -20, 0, 22),
		BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Theme.Text,
		PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false, Text = opts.Default or "",
	})
	corner(4, input)
	padding(0, 0, 8, 8, input)

	local api = _setmetatable({
		instance = row, _maid = maid, _section = section,
		_flag = opts.Flag, _destroyed = false,
	}, Component)
	function api:Set(v)
		local text = _tostring(v or "")
		input.Text = text
		if opts.Flag and fs then fs.write(opts.Flag, text) end
		safeCall(opts.Callback, text, false)
	end
	function api:Get() return input.Text end

	if opts.Numeric then
		maid:Add(input:GetPropertyChangedSignal("Text"):Connect(function()
			local s = input.Text
			local filtered = (s):gsub("[^%-0-9%.]", "")
			if filtered ~= s then input.Text = filtered end
		end))
	end

	maid:Add(input.FocusLost:Connect(function(enter)
		local text = input.Text
		if opts.Flag and fs then fs.write(opts.Flag, text) end
		safeCall(opts.Callback, text, enter)
	end))

	if opts.Flag and fs then
		fs.register(opts.Flag, input.Text, function(v) api:Set(v) end)
	end

	if section._window._tooltips then
		section._window._tooltips.Attach(row, opts.Tooltip, maid)
	end

	section:_addComponent(api)
	return api
end

local function buildDropdown(section, opts, multi)
	local maid = newMaid()
	local fs = section._window._fs
	local options = {}
	if _type(opts.Options) == "table" then
		for _, v in opts.Options do
			if _type(v) == "string" then table_insert(options, v) end
		end
	end

	local selected
	if multi then
		selected = {}
		if _type(opts.Default) == "table" then
			for _, val in opts.Default do
				if _type(val) == "string" then selected[val] = true end
			end
		end
	else
		selected = (_type(opts.Default) == "string") and opts.Default or nil
		if selected ~= nil and not table_find(options, selected) then
			selected = nil
		end
	end

	local row = makeRow(section._content, 32)
	row.Parent = section._content
	maid:Add(row)

	local lbl = make("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 10, 0, 0),
		Size = UDim2_new(0.5, -10, 0, 32),
		Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "Dropdown",
	})

	local valueLbl = make("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2_new(1, 0),
		Position = UDim2_new(1, -28, 0, 0),
		Size = UDim2_new(0.5, -20, 0, 32),
		Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
	})

	local arrow = make("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2_new(1, 0.5),
		Position = UDim2_new(1, -10, 0, 16),
		Size = UDim2_fromOff(14, 14),
		Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Theme.SubText, Text = "+",
	})

	local listHolder = make("Frame", {
		Parent = row,
		BackgroundColor3 = Theme.Background,
		Position = UDim2_new(0, 6, 0, 32),
		Size = UDim2_new(1, -12, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	corner(6, listHolder)
	stroke(Theme.Border, 1, listHolder)

	local list = make("ScrollingFrame", {
		Parent = listHolder,
		BackgroundTransparency = 1,
		Position = UDim2_fromOff(0, 0),
		Size = UDim2_new(1, 0, 1, 0),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Border,
		BorderSizePixel = 0,
		CanvasSize = UDim2_new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})
	make("UIListLayout", {
		Parent = list,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim_new(0, 2),
	})

	local clickArea = make("TextButton", {
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2_new(1, 0, 0, 32),
		Text = "", AutoButtonColor = false,
	})

	if section._window._tooltips then
		section._window._tooltips.Attach(row, opts.Tooltip, maid)
	end

	local open = false
	local rendered = {}

	local function selectedArray()
		local arr = {}
		for _, v in options do
			if (selected)[v] then table_insert(arr, v) end
		end
		return arr
	end

	local function updateValueLabel()
		if multi then
			local arr = selectedArray()
			if #arr == 0 then
				valueLbl.Text = "None"
			elseif #arr <= 2 then
				valueLbl.Text = table_concat(arr, ", ")
			else
				valueLbl.Text = arr[1] .. ", +" .. (#arr - 1)
			end
		else
			valueLbl.Text = selected and _tostring(selected) or "None"
		end
	end

	local function isSelected(optName)
		if multi then return (selected)[optName] == true end
		return selected == optName
	end

	local function applyDotStyle(optName)
		local r = rendered[optName]
		if not r then return end
		r.dot.BackgroundColor3 = isSelected(optName) and Theme.Accent or Theme.Border
	end

	local function listHeight()
		if #options == 0 then return 0 end
		return math_min(#options * 26 - 2, 160)
	end

	local function closeList()
		open = false
		row.Size = UDim2_new(1, 0, 0, 32)
		arrow.Text = "+"
		listHolder.Size = UDim2_new(1, -12, 0, 0)
	end

	local function createItem(optName, order)
		local imaid = newMaid()
		local item = make("TextButton", {
			Parent = list,
			LayoutOrder = order,
			Size = UDim2_new(1, 0, 0, 24),
			BackgroundColor3 = HOVER_BRIGHT,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = Enum.Font.Gotham, TextSize = 12,
			TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			Text = " " .. _tostring(optName),
			AutoButtonColor = false,
		})
		imaid:Add(item)

		local dot = make("Frame", {
			Parent = item,
			AnchorPoint = Vector2_new(1, 0.5),
			Position = UDim2_new(1, -8, 0.5, 0),
			Size = UDim2_fromOff(6, 6),
			BackgroundColor3 = Theme.Border, BorderSizePixel = 0,
		})
		corner(3, dot)

		imaid:Add(item.MouseEnter:Connect(function()
			item.BackgroundTransparency = 0
		end))
		imaid:Add(item.MouseLeave:Connect(function()
			item.BackgroundTransparency = 1
		end))

		imaid:Add(item.MouseButton1Click:Connect(function()
			if multi then
				local sel = selected
				sel[optName] = (not sel[optName]) or nil
				if opts.Flag and fs then fs.write(opts.Flag, selectedArray()) end
				updateValueLabel()
				applyDotStyle(optName)
				safeCall(opts.Callback, selectedArray())
			else
				selected = optName
				if opts.Flag and fs then fs.write(opts.Flag, selected) end
				updateValueLabel()
				for n in rendered do applyDotStyle(n) end
				safeCall(opts.Callback, selected)
				closeList()
			end
		end))

		rendered[optName] = { item = item, dot = dot, maid = imaid }
	end

	local function rebuild()
		local newSet = {}
		for i, opt in options do newSet[opt] = i end

		for name, entry in rendered do
			if not newSet[name] then
				entry.maid:Destroy()
				rendered[name] = nil
			end
		end

		for i, optName in options do
			local entry = rendered[optName]
			if entry then
				if entry.item.LayoutOrder ~= i then
					entry.item.LayoutOrder = i
				end
			else
				local ok, err = _pcall(createItem, optName, i)
				if not ok then
					DBG_warn("[Shenanigans] dropdown item create failed:", err)
					local stray = rendered[optName]
					if stray then stray.maid:Destroy(); rendered[optName] = nil end
				end
			end
		end

		for n in rendered do applyDotStyle(n) end
	end

	local function setOptions(newOpts)
		options = {}
		if _type(newOpts) == "table" then
			for _, v in newOpts do
				if _type(v) == "string" then table_insert(options, v) end
			end
		end
		if multi then
			for k in selected do
				if not table_find(options, k) then (selected)[k] = nil end
			end
		else
			if selected and not table_find(options, selected) then
				selected = nil
			end
		end
		rebuild()
		updateValueLabel()
		if opts.Flag and fs then
			fs.write(opts.Flag, multi and selectedArray() or selected)
		end
		if open then
			local h = listHeight()
			row.Size = UDim2_new(1, 0, 0, 32 + h + 6)
			listHolder.Size = UDim2_new(1, -12, 0, h)
		end
	end

	setOptions(options)
	hoverRow(row, clickArea, maid)

	maid:Add(clickArea.MouseButton1Click:Connect(function()
		open = not open
		if open then
			local h = listHeight()
			row.Size = UDim2_new(1, 0, 0, 32 + h + 6)
			listHolder.Size = UDim2_new(1, -12, 0, h)
			arrow.Text = "-"
		else
			closeList()
		end
	end))

	local api = _setmetatable({
		instance = row, _maid = maid, _section = section,
		_flag = opts.Flag, _destroyed = false,
	}, Component)
	function api:Set(v)
		if multi then
			selected = {}
			if _type(v) == "table" then
				for _, val in v do
					if _type(val) == "string" then (selected)[val] = true end
				end
			end
		else
			selected = (_type(v) == "string") and v or nil
			if selected ~= nil and not table_find(options, selected) then
				selected = nil
			end
		end
		for n in rendered do applyDotStyle(n) end
		updateValueLabel()
		if opts.Flag and fs then
			fs.write(opts.Flag, multi and selectedArray() or selected)
		end
		safeCall(opts.Callback, multi and selectedArray() or selected)
	end
	function api:Get()
		if multi then return selectedArray() end
		return selected
	end
	api.SetOptions = function(_, newOpts) setOptions(newOpts) end

	if opts.Flag and fs then
		local initial = multi and selectedArray() or selected
		fs.register(opts.Flag, initial, function(v) api:Set(v) end)
	end

	maid:Add(function()
		for _, r in rendered do r.maid:Destroy() end
		rendered = {}
	end)

	section:_addComponent(api)
	return api
end

function Components.Dropdown(section, opts) return buildDropdown(section, opts, false) end
function Components.MultiDropdown(section, opts) return buildDropdown(section, opts, true) end

function Components.ColorPicker(
	section,
	opts
)
	local maid = newMaid()
	local fs = section._window._fs
	local dual = opts.Dual == true

	local colorA
	local colorB
	if dual then
		if _type(opts.Default) == "table" then
			local arr = opts.Default
			colorA = (_typeof(arr[1]) == "Color3") and arr[1] or Color3_fromRGB(255, 255, 255)
			colorB = (_typeof(arr[2]) == "Color3") and arr[2] or Color3_fromRGB(255, 255, 255)
		else
			local c = (_typeof(opts.Default) == "Color3") and (opts.Default) or Color3_fromRGB(255, 255, 255)
			colorA = c; colorB = c
		end
	else
		colorA = (_typeof(opts.Default) == "Color3") and (opts.Default) or Color3_fromRGB(255, 255, 255)
		colorB = colorA
	end

	local activeSwatch = "A"
	local h, s, v = Color3_toHSV(colorA)

	local row = makeRow(section._content, 32)
	row.Parent = section._content
	maid:Add(row)
	hoverRow(row, row, maid)

	make("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 10, 0, 0),
		Size = dual and UDim2_new(1, -90, 0, 32) or UDim2_new(1, -50, 0, 32),
		Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "Color",
	})

	local swatchA = make("TextButton", {
		Parent = row,
		AnchorPoint = Vector2_new(1, 0),
		Position = dual and UDim2_new(1, -42, 0, 7) or UDim2_new(1, -10, 0, 7),
		Size = UDim2_fromOff(28, 18),
		BackgroundColor3 = colorA, Text = "",
		AutoButtonColor = false, BorderSizePixel = 0,
	})
	corner(4, swatchA)

	local swatchB = nil
	if dual then
		swatchB = make("TextButton", {
			Parent = row,
			AnchorPoint = Vector2_new(1, 0),
			Position = UDim2_new(1, -10, 0, 7),
			Size = UDim2_fromOff(28, 18),
			BackgroundColor3 = colorB, Text = "",
			AutoButtonColor = false, BorderSizePixel = 0,
		})
		corner(4, swatchB)
	end

	local function pickSwatch(which)
		activeSwatch = which
		local target = (which == "A") and colorA or colorB
		h, s, v = Color3_toHSV(target)
	end
	pickSwatch("A")

	if section._window._tooltips then
		section._window._tooltips.Attach(row, opts.Tooltip, maid)
	end

	local panel = make("Frame", {
		Parent = row,
		Position = UDim2_new(0, 8, 0, 36),
		Size = UDim2_new(1, -16, 0, 110),
		BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
		Visible = false,
	})
	corner(6, panel)
	stroke(Theme.Border, 1, panel)

	local sv = make("Frame", {
		Parent = panel,
		Position = UDim2_new(0, 6, 0, 6),
		Size = UDim2_new(1, -12, 1, -28),
		BackgroundColor3 = Color3_fromRGB(255, 0, 0), BorderSizePixel = 0,
	})
	corner(4, sv)
	local satFrame = make("Frame", {
		Parent = sv,
		BackgroundColor3 = Color3_fromRGB(255, 255, 255),
		Size = UDim2_new(1, 0, 1, 0), BorderSizePixel = 0,
	})
	make("UIGradient", {
		Parent = satFrame,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})
	local valFrame = make("Frame", {
		Parent = sv,
		BackgroundColor3 = Color3_fromRGB(0, 0, 0),
		Size = UDim2_new(1, 0, 1, 0), BorderSizePixel = 0,
	})
	make("UIGradient", {
		Parent = valFrame, Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
	})
	corner(4, valFrame)

	local svDot = make("Frame", {
		Parent = sv,
		Size = UDim2_fromOff(8, 8),
		AnchorPoint = Vector2_new(0.5, 0.5),
		Position = UDim2_new(1, 0, 0, 0),
		BackgroundColor3 = Color3_fromRGB(255, 255, 255),
		BorderSizePixel = 0, ZIndex = 5,
	})
	corner(4, svDot)
	stroke(Color3_fromRGB(0, 0, 0), 1, svDot)

	local hue = make("Frame", {
		Parent = panel,
		AnchorPoint = Vector2_new(0, 1),
		Position = UDim2_new(0, 6, 1, -6),
		Size = UDim2_new(1, -12, 0, 12),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3_fromRGB(255, 255, 255),
	})
	corner(4, hue)
	make("UIGradient", {
		Parent = hue,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3_fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3_fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3_fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.50, Color3_fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3_fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3_fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1.00, Color3_fromRGB(255, 0, 0)),
		}),
	})
	local hueDot = make("Frame", {
		Parent = hue,
		Size = UDim2_new(0, 3, 1, 4),
		AnchorPoint = Vector2_new(0.5, 0.5),
		Position = UDim2_new(0, 0, 0.5, 0),
		BackgroundColor3 = Color3_fromRGB(255, 255, 255),
		BorderSizePixel = 0, ZIndex = 5,
	})
	corner(2, hueDot)
	stroke(Color3_fromRGB(0, 0, 0), 1, hueDot)

	local api = _setmetatable({
		instance = row, _maid = maid, _section = section,
		_flag = opts.Flag, _destroyed = false,
	}, Component)

	local function writeFlag()
		if not (opts.Flag and fs) then return end
		if dual then
			fs.write(opts.Flag, { colorA, colorB })
		else
			fs.write(opts.Flag, colorA)
		end
	end

	local function apply(fire)
		local c = Color3_fromHSV(h, s, v)
		if activeSwatch == "A" then
			colorA = c
			swatchA.BackgroundColor3 = colorA
		else
			colorB = c
			if swatchB then swatchB.BackgroundColor3 = colorB end
		end
		sv.BackgroundColor3 = Color3_fromHSV(h, 1, 1)
		svDot.Position = UDim2_new(s, 0, 1 - v, 0)
		hueDot.Position = UDim2_new(h, 0, 0.5, 0)
		writeFlag()
		if fire ~= false then
			if dual then safeCall(opts.Callback, colorA, colorB)
			else safeCall(opts.Callback, colorA) end
		end
	end

	function api:Set(c)
		if dual and _type(c) == "table" then
			local arr = c
			if _typeof(arr[1]) == "Color3" then
				colorA = arr[1]
				swatchA.BackgroundColor3 = colorA
			end
			if _typeof(arr[2]) == "Color3" and swatchB then
				colorB = arr[2]
				swatchB.BackgroundColor3 = colorB
			end
			pickSwatch(activeSwatch)
			writeFlag()
		elseif _typeof(c) == "Color3" then
			h, s, v = Color3_toHSV(c)
			apply()
		end
	end
	function api:Get()
		if dual then return { colorA, colorB } end
		return colorA
	end

	apply(false)
	row.Size = UDim2_new(1, 0, 0, 32)
	panel.Visible = false

	local function openPanel()
		panel.Visible = true
		row.Size = UDim2_new(1, 0, 0, 152)
	end
	local function closePanel()
		panel.Visible = false
		row.Size = UDim2_new(1, 0, 0, 32)
	end

	maid:Add(swatchA.MouseButton1Click:Connect(function()
		if activeSwatch == "A" then
			if panel.Visible then closePanel() else openPanel() end
		else
			pickSwatch("A")
			openPanel()
			apply(false)
		end
	end))
	if swatchB then
		maid:Add(swatchB.MouseButton1Click:Connect(function()
			if activeSwatch == "B" then
				if panel.Visible then closePanel() else openPanel() end
			else
				pickSwatch("B")
				openPanel()
				apply(false)
			end
		end))
	end

	local svDragMaid = nil
	local hueDragMaid = nil
	local svX, svY, svW, svH = 0, 0, 1, 1
	local hueX, hueW = 0, 1

	local function updateSV(px)
		s = math_clamp((px.X - svX) / svW, 0, 1)
		v = 1 - math_clamp((px.Y - svY) / svH, 0, 1)
		apply()
	end
	local function updateHue(x)
		h = math_clamp((x - hueX) / hueW, 0, 1)
		apply()
	end
	local function endSv()
		if svDragMaid then svDragMaid:Destroy(); svDragMaid = nil end
	end
	local function endHue()
		if hueDragMaid then hueDragMaid:Destroy(); hueDragMaid = nil end
	end

	maid:Add(sv.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if svDragMaid then return end
		svX, svY = sv.AbsolutePosition.X, sv.AbsolutePosition.Y
		svW = math_max(1, sv.AbsoluteSize.X)
		svH = math_max(1, sv.AbsoluteSize.Y)
		updateSV(Vector2_new(input.Position.X, input.Position.Y))
		local dm = newMaid()
		svDragMaid = dm
		dm:Add(InputRouter.OnChanged(function(input2)
			if input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch then
				updateSV(Vector2_new(input2.Position.X, input2.Position.Y))
			end
		end))
		dm:Add(InputRouter.OnEnded(function(input2)
			if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
				endSv()
			end
		end))
	end))
	maid:Add(function() endSv() end)

	maid:Add(hue.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if hueDragMaid then return end
		hueX = hue.AbsolutePosition.X
		hueW = math_max(1, hue.AbsoluteSize.X)
		updateHue(input.Position.X)
		local dm = newMaid()
		hueDragMaid = dm
		dm:Add(InputRouter.OnChanged(function(input2)
			if input2.UserInputType == Enum.UserInputType.MouseMovement or input2.UserInputType == Enum.UserInputType.Touch then
				updateHue(input2.Position.X)
			end
		end))
		dm:Add(InputRouter.OnEnded(function(input2)
			if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
				endHue()
			end
		end))
	end))
	maid:Add(function() endHue() end)

	if opts.Flag and fs then
		local initial = dual and { colorA, colorB } or colorA
		fs.register(opts.Flag, initial, function(v2) api:Set(v2) end)
	end

	section:_addComponent(api)
	return api
end




local function withCommon(section, comp, opts)
	if comp and opts and opts.Depends ~= nil then
		local win = section._window
		if win and win._registerDep then
			win._registerDep(comp, opts.Depends, opts.DependsMode)
		end
	end
	return comp
end

function Section:AddLabel(opts) opts = opts or {}; return withCommon(self, Components.Label(self, opts), opts) end
function Section:AddButton(opts) opts = opts or {}; return withCommon(self, Components.Button(self, opts), opts) end
function Section:AddToggle(opts) opts = opts or {}; return withCommon(self, Components.Toggle(self, opts), opts) end
function Section:AddSlider(opts) opts = opts or {}; return withCommon(self, Components.Slider(self, opts), opts) end
function Section:AddDropdown(opts) opts = opts or {}; return withCommon(self, Components.Dropdown(self, opts), opts) end
function Section:AddMultiDropdown(opts) opts = opts or {}; return withCommon(self, Components.MultiDropdown(self, opts), opts) end
function Section:AddKeybind(opts) opts = opts or {}; return withCommon(self, Components.Keybind(self, opts), opts) end
function Section:AddTextbox(opts) opts = opts or {}; return withCommon(self, Components.Textbox(self, opts), opts) end
function Section:AddColorPicker(opts) opts = opts or {}; return withCommon(self, Components.ColorPicker(self, opts), opts) end
function Section:AddSeparator(opts) opts = opts or {}; return withCommon(self, Components.Separator(self, opts), opts) end

local SECTION_COLUMN_GAP = 8
local TAB_TWO_COLUMN_MIN_WIDTH = 480
local TAB_THREE_COLUMN_MIN_WIDTH = 720

local function columnOffsetPx(numCols)
	return math_floor((numCols - 1) * SECTION_COLUMN_GAP / numCols)
end

function Tab.new(window, opts)
	local self = _setmetatable({}, Tab)
	self._window = window
	self._name = opts.Name or "Tab"
	self._icon = opts.Icon
	self._hidden = opts.Hidden == true
	self._maid = newMaid()
	self._sections = {}
	self._layoutMode = "wide"
	self._content = nil
	self._active = false
	self._destroyed = false
	self._rebalanceScheduled = false

	if not self._hidden then
		local btn = make("TextButton", {
			Parent = window._tabList,
			BackgroundColor3 = Theme.Surface,
			BackgroundTransparency = 1,
			Size = UDim2_new(1, 0, 0, 32),
			AutoButtonColor = false, Text = "",
		})
		corner(6, btn)
		self._maid:Add(btn)

		local indicator = make("Frame", {
			Parent = btn,
			BackgroundColor3 = Theme.Accent,
			Size = UDim2_fromOff(3, 16),
			Position = UDim2_new(0, 0, 0.5, -8),
			BorderSizePixel = 0, BackgroundTransparency = 1,
		})
		corner(2, indicator)

		local lbl = make("TextLabel", {
			Parent = btn,
			BackgroundTransparency = 1,
			Position = UDim2_new(0, self._icon and 32 or 12, 0, 0),
			Size = UDim2_new(1, self._icon and -36 or -16, 1, 0),
			Font = Enum.Font.GothamMedium, TextSize = 12,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = self._name,
		})

		if self._icon then
			make("ImageLabel", {
				Parent = btn,
				BackgroundTransparency = 1,
				Position = UDim2_new(0, 10, 0.5, -8),
				Size = UDim2_fromOff(16, 16),
				Image = self._icon,
				ImageColor3 = Theme.SubText,
			})
		end

		self._maid:Add(btn.MouseButton1Click:Connect(function()
			window:SelectTab(self)
		end))

		self._btn = btn
		self._lbl = lbl
		self._indicator = indicator
	end
	return self
end

function Tab:_getContent()
	if self._content then return self._content end
	local content = make("ScrollingFrame", {
		Parent = self._window._pageHolder,
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2_new(1, 0, 1, 0),
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Border,
		CanvasSize = UDim2_new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	})

	local columns = make("Frame", {
		Parent = content,
		BackgroundTransparency = 1,
		Size = UDim2_new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	})
	padding(8, 8, 8, 8 + 3, columns)
	make("UIListLayout", {
		Parent = columns,
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim_new(0, SECTION_COLUMN_GAP),
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	})

	local initialOffset = columnOffsetPx(2)
	local function makeColumn(order)
		local col = make("Frame", {
			Parent = columns,
			BackgroundTransparency = 1,
			Size = UDim2_new(0.5, -initialOffset, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
		})
		make("UIListLayout", {
			Parent = col,
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim_new(0, 8),
		})
		return col
	end
	local colA = makeColumn(1)
	local colB = makeColumn(2)
	local colC = makeColumn(3)

	self._content = content
	self._columns = columns
	self._colA = colA
	self._colB = colB
	self._colC = colC
	self._maid:Add(content)

	self._maid:Add(columns:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:_evaluateLayoutMode()
	end))
	self:_evaluateLayoutMode()
	return content
end

local function columnsForMode(mode)
	if mode == "wide" then return 3
	elseif mode == "mid" then return 2 end
	return 1
end

function Tab:_columnByIndex(idx)
	if idx == 2 then return self._colB end
	if idx == 3 then return self._colC end
	return self._colA
end

function Tab:_measuredHeight(sec)
	local fr = sec and (sec)._frame
	if fr then
		local h = fr.AbsoluteSize.Y
		if h and h > 1 then return h end
	end
	local comps = sec and (sec)._components
	local count = comps and #comps or 0
	return 44 + count * 34
end

function Tab:_distributeSections()
	local n = columnsForMode(self._layoutMode)
	if n <= 1 then
		for i, sec in self._sections do
			local fr = sec and (sec)._frame
			if fr and fr.Parent ~= nil then
				if fr.Parent ~= self._colA then fr.Parent = self._colA end
				fr.LayoutOrder = i
			end
		end
		return
	end

	local heights = {}
	for c = 1, n do heights[c] = 0 end
	for i, sec in self._sections do
		local fr = sec and (sec)._frame
		if fr and fr.Parent ~= nil then
			local best = 1
			for c = 2, n do
				if heights[c] < heights[best] then best = c end
			end
			local col = self:_columnByIndex(best)
			if fr.Parent ~= col then fr.Parent = col end
			fr.LayoutOrder = i
			heights[best] = heights[best] + self:_measuredHeight(sec) + SECTION_COLUMN_GAP
		end
	end
end

function Tab:_scheduleRebalance()
	if self._rebalanceScheduled then return end
	self._rebalanceScheduled = true
	task_defer(function()
		_pcall(function() RunService.Heartbeat:Wait() end)
		self._rebalanceScheduled = false
		if self._destroyed then return end
		self:_distributeSections()
	end)
end

function Tab:_applyLayoutMode(mode)
	self._layoutMode = mode
	local n = columnsForMode(mode)
	if n == 3 then
		local off = columnOffsetPx(3)
		self._colA.Size = UDim2_new(1/3, -off, 0, 0)
		self._colB.Size = UDim2_new(1/3, -off, 0, 0)
		self._colC.Size = UDim2_new(1/3, -off, 0, 0)
		self._colB.Visible = true
		self._colC.Visible = true
	elseif n == 2 then
		local off = columnOffsetPx(2)
		self._colA.Size = UDim2_new(0.5, -off, 0, 0)
		self._colB.Size = UDim2_new(0.5, -off, 0, 0)
		self._colB.Visible = true
		self._colC.Visible = false
	else
		self._colA.Size = UDim2_new(1, 0, 0, 0)
		self._colB.Visible = false
		self._colC.Visible = false
	end
	self:_distributeSections()
	self:_scheduleRebalance()
end

function Tab:_evaluateLayoutMode()
	if not self._columns or not self._colA or not self._colB or not self._colC then return end
	local w = self._columns.AbsoluteSize.X
	local newMode
	if w >= TAB_THREE_COLUMN_MIN_WIDTH then newMode = "wide"
	elseif w >= TAB_TWO_COLUMN_MIN_WIDTH then newMode = "mid"
	else newMode = "narrow" end
	if newMode ~= self._layoutMode then
		self:_applyLayoutMode(newMode)
	end
end

function Tab:_acquireSectionParent(section)
	self:_getContent()
	local i = #self._sections + 1
	if section and (section)._frame then
		(section)._frame.LayoutOrder = i
	end
	local n = columnsForMode(self._layoutMode)
	local target = ((i - 1) % n) + 1
	return self:_columnByIndex(target)
end

function Tab:_unregisterSection(section)
	local idx = table_find(self._sections, section)
	if idx then
		table_remove(self._sections, idx)
		self:_distributeSections()
	end
end

function Tab:Activate()
	self:_getContent().Visible = true
	self._active = true
	if self._lbl then
		self._lbl.TextColor3 = Theme.Text
		self._btn.BackgroundColor3 = Theme.SurfaceHover
		self._btn.BackgroundTransparency = 0
		self._indicator.BackgroundTransparency = 0
	end
	self:_scheduleRebalance()
end

function Tab:Deactivate()
	if self._content then self._content.Visible = false end
	self._active = false
	if self._lbl then
		self._lbl.TextColor3 = Theme.SubText
		self._btn.BackgroundTransparency = 1
		self._indicator.BackgroundTransparency = 1
	end
end

function Tab:CreateSection(opts)
	if _type(opts) == "string" then opts = { Name = opts } end
	local sec = Section.new(self, opts or {})
	table_insert(self._sections, sec)
	self:_scheduleRebalance()
	return sec
end

function Tab:SetVisible(v)
	if self._btn then self._btn.Visible = v end
end

function Tab:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	local sections = self._sections
	self._sections = {}
	for _, s in sections do
		local ok, err = _pcall(s.Destroy, s)
		if not ok then DBG_warn("[Shenanigans] section destroy:", err) end
	end
	self._maid:Destroy()
	if self._window and not self._window._destroyed and self._window._activeTab == self then
		self._window._activeTab = nil
	end
end

local CONFIG_ROOT = "Shenanigans"
local AUTOLOAD_FILE = "_autoload.txt"

local function configFolderPath(_configName)
	local placeId = _tostring((game).PlaceId or 0)
	return CONFIG_ROOT .. "/" .. placeId
end

local function autoloadPath()
	local placeId = _tostring((game).PlaceId or 0)
	return CONFIG_ROOT .. "/" .. placeId .. "/" .. AUTOLOAD_FILE
end

local function ensureFolder(path)
	if not hasFS then return end
	local parts = {}
	for s in (path):gmatch("[^/]+") do
		table_insert(parts, s)
	end
	local acc = ""
	for _, p in parts do
		acc = (acc == "") and p or (acc .. "/" .. p)
		if isfolder_fn and not (isfolder_fn)(acc) then
			if makefolder_fn then
				_pcall(makefolder_fn, acc)
			end
		end
	end
end

local serializeFlag, deserializeFlag

function serializeFlag(v)
	local tv = _typeof(v)
	if tv == "Color3" then
		return { __type = "Color3", r = (v).R, g = (v).G, b = (v).B }
	elseif tv == "EnumItem" then
		local ei = v
		local enumName = (_tostring(ei.EnumType)):gsub("^Enum%.", "")
		return { __type = "EnumItem", value = enumName .. "." .. ei.Name }
	elseif tv == "table" then
		local arr = v
		local n = #arr
		local primOnly = true
		for i = 1, n do
			local t = _type(arr[i])
			if t ~= "string" and t ~= "number" and t ~= "boolean" then
				primOnly = false
				break
			end
		end
		if primOnly then
			local items = table_create(n)
			for i = 1, n do items[i] = arr[i] end
			return { __type = "List", items = items }
		else
			local items = table_create(n)
			for i = 1, n do
				items[i] = serializeFlag(arr[i])
			end
			return { __type = "Array", items = items, n = n }
		end
	elseif tv == "number" then
		if not isFiniteNumber(v) then return nil end
		return v
	elseif tv == "boolean" or tv == "string" then
		return v
	end
	return nil
end

local function deserializeColor3(rv, gv, bv)
	if not (isFiniteNumber(rv) and isFiniteNumber(gv) and isFiniteNumber(bv)) then
		return nil
	end
	return Color3_new(
		math_clamp(rv, 0, 1),
		math_clamp(gv, 0, 1),
		math_clamp(bv, 0, 1)
	)
end

function deserializeFlag(v)
	local t = _type(v)
	if t == "number" then
		if not isFiniteNumber(v) then return nil end
		return v
	end
	if t == "boolean" or t == "string" then return v end
	if t == "table" then
		local tag = (v).__type
		if tag == "Color3" then
			return deserializeColor3((v).r, (v).g, (v).b)
		elseif tag == "EnumItem" and _type((v).value) == "string" then
			local parts = {}
			for s in ((v).value):gmatch("[^%.]+") do
				table_insert(parts, s)
			end
			if #parts == 2 then
				local ok, ec = _pcall(function()
					return (Enum)[parts[1]][parts[2]]
				end)
				if ok then return ec end
			end
			return nil
		elseif tag == "List" and _type((v).items) == "table" then
			local out = {}
			for _, item in (v).items do
				local ti = _type(item)
				local keep =
					ti == "string" or ti == "boolean" or (ti == "number" and isFiniteNumber(item))
				if keep then table_insert(out, item) end
			end
			return out
		elseif tag == "Array" and _type((v).items) == "table" then
			local items = (v).items
			local n = (v).n or #items
			local out = table_create(n)
			for i = 1, n do
				out[i] = deserializeFlag(items[i])
			end
			return out
		end
	end
	return nil
end










local DEFAULT_SIZE = Vector2_new(900, 620)
local MIN_SIZE = Vector2_new(480, 320)
local MAX_SIZE = Vector2_new(1280, 800)





local function resolveWindowSize(v)
	local x, y
	if _typeof(v) == "Vector2" then
		x, y = v.X, v.Y
	elseif _type(v) == "table" then
		x = tonumber(v.X or v.Width or v[1])
		y = tonumber(v.Y or v.Height or v[2])
	end
	if not (x and y) then return DEFAULT_SIZE end
	return Vector2_new(
		math_clamp(x, MIN_SIZE.X, MAX_SIZE.X),
		math_clamp(y, MIN_SIZE.Y, MAX_SIZE.Y)
	)
end

function Window.new(
	library,
	opts
)
	local self = _setmetatable({}, Window)
	self._library = library
	self._maid = newMaid()
	self._tabs = {}
	self._activeTab = nil
	self._destroyed = false

	local fs_values = {}
	local fs_setters = {}
	local fs_defaults = {}

	self._fs = {
		register = function(key, default, setter)
			if _type(key) ~= "string" then return end
			fs_setters[key] = setter
			if fs_defaults[key] == nil then fs_defaults[key] = default end
			if fs_values[key] == nil then fs_values[key] = default end
		end,
		unregister = function(key)
			if _type(key) ~= "string" then return end
			fs_setters[key] = nil
		end,
		write = function(key, value)
			if _type(key) == "string" then
				fs_values[key] = value




				if self._refreshDeps then self._refreshDeps(key) end
			end
		end,
	}

	


























	local dep_entries = {}
	local dep_byFlag = {}

	local function normDepends(spec)
		if spec == nil then return nil end
		local out = {}
		local function walk(v, sink)
			if _type(v) == "string" then
				sink[#sink + 1] = { flag = v }
			elseif _type(v) == "table" then
				if _type(v.Any) == "table" then




					local sub = {}
					walk(v.Any, sub)
					if #sub > 0 then sink[#sink + 1] = { any = sub } end
				elseif _type(v.Flag) == "string" then
					sink[#sink + 1] = { flag = v.Flag, want = v.Value }
				else
					for _, inner in v do walk(inner, sink) end
				end
			end
		end
		walk(spec, out)
		return (#out > 0) and out or nil
	end



	local function depFlags(list, acc)
		for _, e in list do
			if e.any then
				depFlags(e.any, acc)
			elseif e.flag then
				acc[#acc + 1] = e.flag
			end
		end
		return acc
	end

	local function depSatisfied(e, read)
		if e.any then
			for _, sub in e.any do
				if depSatisfied(sub, read) then return true end
			end
			return false
		end
		local val = read(e.flag)
		if e.want == nil then
			return val ~= nil and val ~= false
		end
		if _type(e.want) == "table" then
			for _, w in e.want do
				if val == w then return true end
			end
			return false
		end
		return val == e.want
	end





	local function setDimmed(entry, on)
		local inst = entry.comp and entry.comp.instance
		if not inst then return end
		if on then
			if not entry.scrim then
				entry.scrim = make("TextButton", {
					Parent = inst,
					BackgroundColor3 = Theme.Surface,
					BackgroundTransparency = 0.45,
					BorderSizePixel = 0,
					Size = UDim2_new(1, 0, 1, 0),
					ZIndex = 50,
					Text = "", AutoButtonColor = false,
					Active = true,
				})
				corner(6, entry.scrim)
			end
			entry.scrim.Visible = true
		elseif entry.scrim then
			entry.scrim.Visible = false
		end
	end

	local function depRead(flag) return fs_values[flag] end

	local function applyDep(entry)

		local ok = true
		for _, e in entry.list do
			if not depSatisfied(e, depRead) then ok = false; break end
		end
		if entry.state == ok then return end
		entry.state = ok
		if entry.dim then
			setDimmed(entry, not ok)
			return
		end
		local comp = entry.comp
		if comp.SetVisible then _pcall(comp.SetVisible, comp, ok) end





		local sec = comp._section
		local tab = sec and sec._tab
		if tab and tab._scheduleRebalance then _pcall(tab._scheduleRebalance, tab) end
	end

	self._registerDep = function(comp, spec, mode)
		local list = normDepends(spec)
		if not (comp and list) then return end
		local entry = { comp = comp, list = list, dim = (mode == "dim"), state = nil }
		dep_entries[#dep_entries + 1] = entry


		for _, flag in depFlags(list, {}) do
			local bucket = dep_byFlag[flag]
			if not bucket then bucket = {}; dep_byFlag[flag] = bucket end
			bucket[#bucket + 1] = entry
		end
		applyDep(entry)
	end

	self._refreshDeps = function(flag)
		local bucket = dep_byFlag[flag]
		if not bucket then return end
		for _, entry in bucket do applyDep(entry) end
	end




	self._refreshAllDeps = function()
		for _, entry in dep_entries do applyDep(entry) end
	end

	self.Flags = _setmetatable({}, {
		__index = function(_, k) return fs_values[k] end,
		__newindex = function(_, k, v)
			local setter = fs_setters[k]
			if setter then
				local ok, err = _pcall(setter, v)
				if not ok then DBG_warn("[Shenanigans] Flags setter for", k, ":", err) end
			else
				DBG_warn("[Shenanigans] Flags: no flag named", _tostring(k))
			end
		end,
		__metatable = "locked",
	})

	if opts.ConfigName ~= nil and not isValidConfigName(opts.ConfigName) then
		DBG_warn("[Shenanigans] ConfigName rejected (must be 1-64 of letters/digits/_/-); using 'default'")
		self._configName = "default"
	else
		self._configName = opts.ConfigName or "default"
	end
	self._autoloadOnInit = opts.Autoload == true
	self.SettingsCallback = opts.SettingsCallback

	local winSize = resolveWindowSize(opts.Size)

	local screenGui = make("ScreenGui", {
		Name = pickRandomGuiName(),
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	local guiParent, alreadyHidden = getGuiParent()
	screenGui.Parent = guiParent
	if not alreadyHidden then
		if not protectGui(screenGui) and RunService:IsRunning() and not RunService:IsStudio() then
			DBG_warn("[Shenanigans] GUI is not hidden from CoreGui enumeration (no protect_gui available)")
		end
	end
	self._screenGui = screenGui
	self._maid:Add(screenGui)

	self._tooltips = createTooltipSystem(screenGui)
	self._notify = createNotificationSystem(screenGui)
	self._maid:Add(function() self._tooltips.Destroy() end)
	self._maid:Add(function() self._notify.Destroy() end)

	local main = make("Frame", {
		Parent = screenGui,
		AnchorPoint = Vector2_new(0.5, 0.5),
		Position = UDim2_fromScale(0.5, 0.5),
		Size = UDim2_fromOff(winSize.X, winSize.Y),
		BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
		ClipsDescendants = true, Visible = false,
	})
	corner(10, main)
	stroke(Theme.Border, 1, main)
	self._main = main

	local titleBar = make("Frame", {
		Parent = main,
		BackgroundColor3 = Theme.Surface,
		Size = UDim2_new(1, 0, 0, 36),
		BorderSizePixel = 0,
	})
	corner(10, titleBar)
	make("Frame", {
		Parent = titleBar,
		BackgroundColor3 = Theme.Surface,
		Position = UDim2_new(0, 0, 1, -10),
		Size = UDim2_new(1, 0, 0, 10),
		BorderSizePixel = 0,
	})

	local ICON_OVERHANG = 16
	local ICON_TEXT_GAP = 28
	local iconOffset = 0
	if opts.Icon then
		make("ImageLabel", {
			Parent = titleBar,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2_new(0, 0.5),
			Position = UDim2_new(0, -ICON_OVERHANG, 0.5, 0),
			Size = UDim2_fromOff(70, 70),
			Image = _tostring(opts.Icon),
			ScaleType = Enum.ScaleType.Fit,
		})
		iconOffset = ICON_TEXT_GAP
	end

	make("TextLabel", {
		Parent = titleBar,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 14 + iconOffset, 0, 0),
		Size = UDim2_new(1, -100 - iconOffset, 1, 0),
		Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = opts.Name or "UI Library",
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	if opts.Version then
		make("TextLabel", {
			Parent = titleBar,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2_new(1, 0.5),
			Position = UDim2_new(1, -36, 0.5, 0),
			Size = UDim2_fromOff(80, 18),
			Font = Enum.Font.Gotham, TextSize = 11,
			TextColor3 = Theme.Muted,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = _tostring(opts.Version),
		})
	end

	local minBtn = make("TextButton", {
		Parent = titleBar,
		AnchorPoint = Vector2_new(1, 0.5),
		Position = UDim2_new(1, -10, 0.5, 0),
		Size = UDim2_fromOff(20, 20),
		BackgroundColor3 = Theme.SurfaceAlt,
		Font = Enum.Font.GothamBold, TextSize = 14,
		TextColor3 = Theme.Text, Text = "-",
		AutoButtonColor = false, BorderSizePixel = 0,
	})
	corner(4, minBtn)
	self._maid:Add(minBtn.MouseButton1Click:Connect(function()
		self:Toggle(false)
	end))

	local sidebar = make("Frame", {
		Parent = main,
		BackgroundColor3 = Theme.Surface,
		Position = UDim2_new(0, 0, 0, 36),
		Size = UDim2_new(0, 160, 1, -36),
		BorderSizePixel = 0,
	})
	corner(10, sidebar)
	make("Frame", {
		Parent = sidebar,
		BackgroundColor3 = Theme.Surface,
		Position = UDim2_new(0, 0, 0, 0),
		Size = UDim2_new(1, 0, 0, 10),
		BorderSizePixel = 0,
	})
	make("Frame", {
		Parent = sidebar,
		BackgroundColor3 = Theme.Surface,
		Position = UDim2_new(1, -10, 0, 0),
		Size = UDim2_new(0, 10, 1, 0),
		BorderSizePixel = 0,
	})

	local tabList = make("ScrollingFrame", {
		Parent = sidebar,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 8, 0, 8),
		Size = UDim2_new(1, -16, 1, -64),
		CanvasSize = UDim2_new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Border,
		BorderSizePixel = 0,
	})
	make("UIListLayout", {
		Parent = tabList,
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim_new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	self._tabList = tabList

	local userPanel = make("Frame", {
		Parent = sidebar,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 8, 1, -54),
		Size = UDim2_new(1, -16, 0, 46),
		BorderSizePixel = 0,
	})

	local avatar = make("ImageLabel", {
		Parent = userPanel,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2_new(0, 0.5),
		Position = UDim2_new(0, 0, 0.5, 0),
		Size = UDim2_fromOff(32, 32),
		Image = rbxThumb((LocalPlayer and LocalPlayer.UserId) or 0),
	})
	corner(16, avatar)

	make("TextLabel", {
		Parent = userPanel,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 38, 0, 8),
		Size = UDim2_new(1, -64, 0, 18),
		Font = Enum.Font.GothamMedium, TextSize = 11,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = (LocalPlayer and LocalPlayer.DisplayName) or "Player",
	})
	make("TextLabel", {
		Parent = userPanel,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 38, 0, 22),
		Size = UDim2_new(1, -64, 0, 16),
		Font = Enum.Font.Gotham, TextSize = 9,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "@" .. ((LocalPlayer and LocalPlayer.Name) or "username"),
	})

	local settingsBtn = make("ImageButton", {
		Parent = userPanel,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2_new(1, 0.5),
		Position = UDim2_new(1, 0, 0.5, 0),
		Size = UDim2_fromOff(18, 18),
		Image = rbxAsset(80428653135733),
		AutoButtonColor = false,
	})
	self._maid:Add(settingsBtn.MouseButton1Click:Connect(function()
		safeCall(self.SettingsCallback)
	end))

	local pageHolder = make("Frame", {
		Parent = main,
		BackgroundTransparency = 1,
		Position = UDim2_new(0, 160, 0, 36),
		Size = UDim2_new(1, -160, 1, -36),
		BorderSizePixel = 0,
	})
	self._pageHolder = pageHolder

	local grip = make("ImageButton", {
		Parent = main,
		AnchorPoint = Vector2_new(1, 1),
		Position = UDim2_new(1, -4, 1, -4),
		Size = UDim2_fromOff(12, 12),
		BackgroundTransparency = 1,
		Image = rbxAsset(6031091004),
		ImageColor3 = Theme.Muted,
		ImageTransparency = 0.4,
		AutoButtonColor = false,
	})

	local resizeMaid = nil
	local function endResize()
		if resizeMaid then resizeMaid:Destroy(); resizeMaid = nil end
	end
	self._maid:Add(grip.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if resizeMaid then return end
		local startMouse = input.Position
		local startSize = main.AbsoluteSize
		local rm = newMaid()
		resizeMaid = rm
		rm:Add(InputRouter.OnChanged(function(input2)
			if input2.UserInputType ~= Enum.UserInputType.MouseMovement and input2.UserInputType ~= Enum.UserInputType.Touch then return end
			local d = input2.Position - startMouse
			local nw = math_clamp(startSize.X + d.X, MIN_SIZE.X, MAX_SIZE.X)
			local nh = math_clamp(startSize.Y + d.Y, MIN_SIZE.Y, MAX_SIZE.Y)
			main.Size = UDim2_fromOff(nw, nh)
		end))
		rm:Add(InputRouter.OnEnded(function(input2)
			if input2.UserInputType == Enum.UserInputType.MouseButton1 or input2.UserInputType == Enum.UserInputType.Touch then
				endResize()
			end
		end))
	end))
	self._maid:Add(function() endResize() end)

	makeDraggable(main, titleBar, self._maid)

	self._toggleKey = nil
	self._toggleKeyConn = nil

	if opts.ToggleKey then
		self:SetToggleKey(opts.ToggleKey)
	end

	main.Size = UDim2_fromOff(winSize.X, winSize.Y)
	main.BackgroundTransparency = 0
	main.Visible = true

	function self:SaveConfig(name)
		if not hasFS then
			self:Notify({ Title = "Config", Content = "No filesystem available", Duration = 3 })
			return false
		end
		local n = name or "default"
		if not isValidConfigName(n) then
			self:Notify({ Title = "Config", Content = "Invalid name (use letters, digits, _ or -)", Duration = 3 })
			return false
		end
		local folder = configFolderPath(self._configName)
		ensureFolder(folder)
		local data = {}
		for k, v in fs_values do
			local s = serializeFlag(v)
			if s ~= nil then data[k] = s end
		end
		local ok, json = _pcall(HttpService.JSONEncode, HttpService, data)
		if not ok then
			DBG_warn("[Shenanigans] config encode failed:", json)
			self:Notify({ Title = "Config", Content = "Encode failed", Duration = 3 })
			return false
		end
		local path = folder .. "/" .. n .. ".json"
		local ok2, err = _pcall(writefile_fn, path, json)
		if not ok2 then
			DBG_warn("[Shenanigans] config write failed:", err)
			self:Notify({ Title = "Config", Content = "Write failed", Duration = 3 })
			return false
		end
		self:Notify({ Title = "Config saved", Content = n, Duration = 2 })
		return true
	end

	function self:LoadConfig(name)
		if not hasFS then return false end
		local n = name or "default"
		if not isValidConfigName(n) then
			self:Notify({ Title = "Config", Content = "Invalid name", Duration = 3 })
			return false
		end
		local folder = configFolderPath(self._configName)
		local path = folder .. "/" .. n .. ".json"
		if isfile_fn and not (isfile_fn)(path) then
			self:Notify({ Title = "Config", Content = "Not found: " .. n, Duration = 3 })
			return false
		end
		local ok, raw = _pcall(readfile_fn, path)
		if not ok then
			DBG_warn("[Shenanigans] config read failed:", raw)
			return false
		end
		local ok2, data = _pcall(HttpService.JSONDecode, HttpService, raw)
		if not ok2 or _type(data) ~= "table" then
			DBG_warn("[Shenanigans] config decode failed:", data)
			self:Notify({ Title = "Config", Content = "Corrupt file", Duration = 3 })
			return false
		end
		local applied, skipped, failed = 0, 0, 0
		local noSetter, badValue, errored = {}, {}, {}
		for k, v in data do
			local setter = fs_setters[k]
			local val = deserializeFlag(v)
			if setter and val ~= nil then
				local s_ok, s_err = _pcall(setter, val)
				if s_ok then
					applied += 1
				else
					failed += 1
					table_insert(errored, _tostring(k) .. " (" .. _tostring(s_err) .. ")")
				end
			else
				skipped += 1
				if not setter then
					table_insert(noSetter, _tostring(k))
				else
					table_insert(badValue, _tostring(k))
				end
			end
		end
		if #noSetter > 0 then
			warn("[Shenanigans] load: NO SETTER for " .. #noSetter .. " flag(s): " .. table.concat(noSetter, ", "))
		end
		if #badValue > 0 then
			warn("[Shenanigans] load: UNREADABLE VALUE for " .. #badValue .. " flag(s): " .. table.concat(badValue, ", "))
		end
		if #errored > 0 then
			warn("[Shenanigans] load: SETTER ERROR on " .. #errored .. " flag(s): " .. table.concat(errored, " | "))
		end
		warn("[Shenanigans] load summary: applied " .. applied .. ", skipped " .. skipped .. ", failed " .. failed)
		local content = n
		if failed > 0 or skipped > 0 then
			content = string_format("%s (applied %d, skipped %d, failed %d)", n, applied, skipped, failed)
		end
		self:Notify({
			Title = (failed > 0) and "Config loaded with errors" or "Config loaded",
			Content = content, Duration = 3,
		})



		if self._refreshAllDeps then self._refreshAllDeps() end
		return failed == 0
	end

	function self:ListConfigs()
		if not hasFS or not listfiles_fn then return {} end
		local folder = configFolderPath(self._configName)
		if isfolder_fn and not (isfolder_fn)(folder) then return {} end
		local out = {}
		local ok, list = _pcall(listfiles_fn, folder)
		if not ok or _type(list) ~= "table" then return {} end
		for _, f in list do
			local nm = (_tostring(f)):match("([^/\\]+)%.json$")
			if nm then table_insert(out, nm) end
		end
		table.sort(out)
		return out
	end

	function self:DeleteConfig(name)
		if not hasFS or not delfile_fn then return false end
		if not isValidConfigName(name) then return false end
		local folder = configFolderPath(self._configName)
		local path = folder .. "/" .. name .. ".json"
		if isfile_fn and not (isfile_fn)(path) then return false end
		local ok = _pcall(delfile_fn, path)
		if ok then
			local cur = self:GetAutoload()
			if cur == name then self:SetAutoload(nil) end
			self:Notify({ Title = "Config deleted", Content = name, Duration = 2 })
		end
		return ok
	end

	function self:ResetToDefaults()
		for k, def in fs_defaults do
			local setter = fs_setters[k]
			if setter then
				local ok, err = _pcall(setter, def)
				if not ok then DBG_warn("[Shenanigans] reset setter for", k, ":", err) end
			end
		end
		self:Notify({ Title = "Defaults restored", Duration = 2 })
	end

	function self:GetAutoload()
		if not hasFS then return nil end
		local path = autoloadPath()
		if isfile_fn and not (isfile_fn)(path) then return nil end
		local ok, raw = _pcall(readfile_fn, path)
		if not ok or _type(raw) ~= "string" then return nil end
		raw = (raw):gsub("%s+$", "")
		if not isValidConfigName(raw) then return nil end
		return raw
	end

	function self:SetAutoload(name)
		if not hasFS then return false end
		local placeId = _tostring((game).PlaceId or 0)
		ensureFolder(CONFIG_ROOT .. "/" .. placeId)
		local path = autoloadPath()
		if name == nil then
			if isfile_fn and (isfile_fn)(path) and delfile_fn then
				_pcall(delfile_fn, path)
			end
			return true
		end
		if not isValidConfigName(name) then return false end
		local ok = _pcall(writefile_fn, path, name)
		return ok == true
	end

	function self:LoadAutoload()
		local n = self:GetAutoload()
		if n and self:LoadConfig(n) then return n end
		return nil
	end

	function self:Init()
		if self._autoloadOnInit then self:LoadAutoload() end



		if self._refreshAllDeps then self._refreshAllDeps() end
	end

	function self:Destroy()
		if self._destroyed then return end
		self._destroyed = true
		local tabs = self._tabs
		self._tabs = {}
		for _, t in tabs do
			local ok, err = _pcall(t.Destroy, t)
			if not ok then DBG_warn("[Shenanigans] tab destroy:", err) end
		end
		if self._toggleKeyConn then
			local ok, err = _pcall(self._toggleKeyConn)
			if not ok then DBG_warn("[Shenanigans] toggleKey disconnect:", err) end
			self._toggleKeyConn = nil
		end
		fs_values = {}
		fs_setters = {}
		fs_defaults = {}
		self._maid:Destroy()
		if self._library and not self._library._destroyed then
			local idx = table_find(self._library._windows, self)
			if idx then table_remove(self._library._windows, idx) end
		end
	end

	return self
end

function Window:CreateTab(opts)
	if _type(opts) == "string" then opts = { Name = opts } end
	local t = Tab.new(self, opts or {})
	table_insert(self._tabs, t)
	if not t._hidden and not self._activeTab then
		self:SelectTab(t)
	end
	return t
end

function Window:SelectTab(t)
	if self._activeTab == t then return end
	if self._activeTab then self._activeTab:Deactivate() end
	self._activeTab = t
	t:Activate()
end

function Window:Toggle(state)
	if state == nil then
		state = not self._main.Visible
	end
	self._main.Visible = state
end

function Window:Show() self:Toggle(true) end
function Window:Hide() self:Toggle(false) end
function Window:IsVisible()
	return self._main and self._main.Visible == true
end

function Window:SetToggleKey(key)
	if self._toggleKeyConn then
		self._toggleKeyConn()
		self._toggleKeyConn = nil
	end
	self._toggleKey = key
	if key then
		self._toggleKeyConn = InputRouter.OnBegan(function(input, gp)
			if gp then return end
			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key then
				self:Toggle()
			end
		end)
	end
end

function Window:GetToggleKey()
	return self._toggleKey
end

function Window:SetSettingsCallback(fn)
	self.SettingsCallback = fn
end

function Window:Notify(opts)
	self._notify.Push(opts)
end

function UILibrary.new()
	local self = _setmetatable({}, UILibrary)
	self._windows = {}
	self._maid = newMaid()
	self._destroyed = false
	return self
end

function UILibrary:CreateWindow(opts)
	if self._destroyed then
		error("[Shenanigans] cannot create window on destroyed library", 2)
	end
	local w = Window.new(self, opts or {})
	table_insert(self._windows, w)
	return w
end

function UILibrary:Init()
	for _, w in self._windows do
		local ok, err = _pcall(w.Init, w)
		if not ok then DBG_warn("[Shenanigans] window init:", err) end
	end
end

function UILibrary:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	local windows = self._windows
	self._windows = {}
	for _, w in windows do
		local ok, err = _pcall(w.Destroy, w)
		if not ok then DBG_warn("[Shenanigans] window destroy:", err) end
	end
	self._maid:Destroy()
end

local exports = _setmetatable({
	new = UILibrary.new,
	Theme = Theme,
	Version = "4.0.0",
}, {
	__metatable = "locked",
	__newindex = function() error("[Shenanigans] exports table is read-only", 2) end,
})

if table_freeze then _pcall(table_freeze, exports) end

return exports