--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")

local React = require(Packages:WaitForChild("React"))
local ReactRoblox = require(Packages:WaitForChild("ReactRoblox"))

local App = require(script.Parent:WaitForChild("App"))

local rootHandle = nil

return function()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local existingMount = playerGui:FindFirstChild("HubUI")
	if existingMount then
		existingMount:Destroy()
	end

	local mountPoint = Instance.new("Folder")
	mountPoint.Name = "HubUI"
	mountPoint.Parent = playerGui

	rootHandle = ReactRoblox.createRoot(mountPoint)
	rootHandle:render(React.createElement(App))
end