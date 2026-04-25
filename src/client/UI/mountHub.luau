--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local React = require(Packages:WaitForChild("React"))
local ReactRoblox = require(Packages:WaitForChild("ReactRoblox"))

local App = require(script.Parent:WaitForChild("App"))

local rootHandle = nil

local function renderFallbackErrorUi(playerGui, message)
	local mountPoint = Instance.new("ScreenGui")
	mountPoint.Name = "HubUI"
	mountPoint.IgnoreGuiInset = true
	mountPoint.ResetOnSpawn = false
	mountPoint.DisplayOrder = 10
	mountPoint.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(660, 220)
	frame.BackgroundColor3 = Color3.fromRGB(20, 24, 31)
	frame.BorderSizePixel = 0
	frame.Parent = mountPoint

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(20, 20)
	title.Size = UDim2.new(1, -40, 0, 30)
	title.FontFace = Font.fromEnum(Enum.Font.GothamBold)
	title.Text = "Hub Failed To Mount"
	title.TextColor3 = Color3.fromRGB(246, 216, 216)
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(20, 62)
	body.Size = UDim2.new(1, -40, 1, -82)
	body.FontFace = Font.fromEnum(Enum.Font.Code)
	body.Text = message
	body.TextColor3 = Color3.fromRGB(230, 235, 245)
	body.TextSize = 16
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Parent = frame
end

return function()
	local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	local playerGui = player:WaitForChild("PlayerGui")

	local existingMount = playerGui:FindFirstChild("HubUI")
	if existingMount then
		if rootHandle then
			rootHandle:unmount()
			rootHandle = nil
		end
		existingMount:Destroy()
	end

	local mountPoint = Instance.new("ScreenGui")
	mountPoint.Name = "HubUI"
	mountPoint.IgnoreGuiInset = true
	mountPoint.ResetOnSpawn = false
	mountPoint.DisplayOrder = 10
	mountPoint.Parent = playerGui

	local ok, err = xpcall(function()
		rootHandle = ReactRoblox.createRoot(mountPoint)
		rootHandle:render(React.createElement(App))
	end, debug.traceback)

	if not ok then
		warn(string.format("[mountHub] Failed to render App: %s", tostring(err)))
		if rootHandle then
			rootHandle:unmount()
			rootHandle = nil
		end
		mountPoint:Destroy()
		renderFallbackErrorUi(playerGui, tostring(err))
	end
end
