--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local function ModuleButton(props)
	return React.createElement("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(24, 26, 31),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Size = UDim2.fromScale(1, 0.28),
		FontFace = Font.fromEnum(Enum.Font.GothamMedium),
		Text = props.text,
		TextColor3 = Color3.fromRGB(235, 238, 242),
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		[React.Event.Activated] = props.onActivated,
	}, {
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 18),
			PaddingRight = UDim.new(0, 18),
		}),
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		Stroke = React.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.fromRGB(53, 57, 66),
			Thickness = 1,
		}),
	})
end

return ModuleButton