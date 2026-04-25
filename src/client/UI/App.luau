--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local State = script.Parent.Parent:WaitForChild("State")
local HubContext = require(State:WaitForChild("HubContext"))

local HubMenu = require(script.Parent:WaitForChild("HubMenu"))

local function App()
	return React.createElement(HubContext.HubProvider, {
		children = React.createElement("ScreenGui", {
			DisplayOrder = 10,
			IgnoreGuiInset = true,
			ResetOnSpawn = false,
			SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		}, {
			Backdrop = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(8, 10, 13),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
			}, {
				Gradient = React.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(9, 11, 15)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 7, 10)),
					}),
					Rotation = 25,
				}),
			}),
			Hub = React.createElement(HubMenu),
		}),
	})
end

return App