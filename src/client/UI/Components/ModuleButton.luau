--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))

local function ModuleButton(props)
	local description = props.description
	local accentColor = props.accentColor or Color3.fromRGB(92, 104, 122)

	return React.createElement("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(24, 26, 31),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		FontFace = Font.fromEnum(Enum.Font.GothamMedium),
		Text = "",
		TextColor3 = Color3.fromRGB(235, 238, 242),
		[React.Event.Activated] = props.onActivated,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		Stroke = React.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = accentColor,
			Transparency = 0.55,
			Thickness = 1,
		}),
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
		}),
		Content = React.createElement("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Title = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				Size = UDim2.new(1, 0, 0, 22),
				Text = props.text,
				TextColor3 = Color3.fromRGB(235, 238, 242),
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
			Description = description and React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, 0, 0, 0),
				FontFace = Font.fromEnum(Enum.Font.Gotham),
				Text = description,
				TextColor3 = Color3.fromRGB(136, 145, 158),
				TextSize = 13,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
		}),
	})
end

return ModuleButton
