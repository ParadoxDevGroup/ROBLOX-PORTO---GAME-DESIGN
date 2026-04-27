--!strict

local SocialPropVariants = {
	{
		name = "Classic Wicker",
		description = "Standard prop for every player.",
		accentColor = Color3.fromRGB(160, 118, 72),
		baseColor = Color3.fromRGB(106, 78, 48),
		lidColor = Color3.fromRGB(134, 100, 63),
		buffLabel = "shared comfort",
		buffBonus = 6,
		buffDuration = 12,
	},
	{
		name = "Sunset Citrus",
		description = "Warm visual variant for premium feel.",
		accentColor = Color3.fromRGB(222, 146, 68),
		baseColor = Color3.fromRGB(170, 94, 42),
		lidColor = Color3.fromRGB(245, 181, 89),
		buffLabel = "sunset sprint",
		buffBonus = 7,
		buffDuration = 12,
	},
	{
		name = "Neon Cyber Basket",
		description = "High-contrast cosmetic variant with glow effects.",
		accentColor = Color3.fromRGB(84, 232, 204),
		baseColor = Color3.fromRGB(27, 41, 55),
		lidColor = Color3.fromRGB(66, 176, 165),
		buffLabel = "neon flow",
		buffBonus = 8,
		buffDuration = 14,
	},
	{
		name = "Golden Hour",
		description = "Luxe variant with warm ambient glow.",
		accentColor = Color3.fromRGB(255, 204, 0),
		baseColor = Color3.fromRGB(139, 109, 55),
		lidColor = Color3.fromRGB(255, 223, 102),
		buffLabel = "golden blessing",
		buffBonus = 9,
		buffDuration = 15,
	},
}

return table.freeze(SocialPropVariants)
