--[[
	ScaleData.lua
	ModuleScript: ReplicatedStorage.ScaleData

	Each entry describes one "guess the scale" round. Heights are in meters
	(real-world), used purely for computing ratios -- the client never sees
	targetHeight until after it submits a guess.
]]

local ScaleData = {}

ScaleData.Rounds = {
	{
		referenceName = "African Elephant",
		referenceHeight = 3.2,
		targetName = "Giraffe",
		targetHeight = 5.5,
		category = "Animals",
		fact = "A giraffe can be over 5.5 meters tall, roughly 40% taller than an African elephant.",
	},
	{
		referenceName = "House Cat",
		referenceHeight = 0.25,
		targetName = "Grizzly Bear",
		targetHeight = 2.5,
		category = "Animals",
		fact = "A standing grizzly bear can reach about 2.5 meters -- 10 times the height of a house cat.",
	},
	{
		referenceName = "Human (Average Adult)",
		referenceHeight = 1.7,
		targetName = "Blue Whale",
		targetHeight = 25,
		category = "Animals",
		fact = "Blue whales can grow to around 25-30 meters, the largest animals ever known to have existed.",
	},
	{
		referenceName = "Emperor Penguin",
		referenceHeight = 1.1,
		targetName = "Ostrich",
		targetHeight = 2.7,
		category = "Animals",
		fact = "Ostriches, the tallest living birds, can reach about 2.7 meters -- more than double an emperor penguin.",
	},
	{
		referenceName = "Statue of Liberty",
		referenceHeight = 46,
		targetName = "Great Pyramid of Giza",
		targetHeight = 138,
		category = "Landmarks",
		fact = "The Great Pyramid of Giza originally stood about 146 meters tall -- roughly 3x the Statue of Liberty.",
	},
	{
		referenceName = "Statue of Liberty",
		referenceHeight = 46,
		targetName = "Eiffel Tower",
		targetHeight = 330,
		category = "Landmarks",
		fact = "The Eiffel Tower is about 330 meters tall, over 7 times the height of the Statue of Liberty.",
	},
	{
		referenceName = "London Double-Decker Bus",
		referenceHeight = 4.4,
		targetName = "Big Ben Clock Tower",
		targetHeight = 96,
		category = "Landmarks",
		fact = "The Elizabeth Tower (Big Ben) stands about 96 meters tall -- roughly 22 double-decker buses stacked up.",
	},
	{
		referenceName = "Burj Khalifa",
		referenceHeight = 828,
		targetName = "Mount Everest",
		targetHeight = 8849,
		category = "Landmarks",
		fact = "Mount Everest rises about 8,849 meters -- more than 10 times the height of the Burj Khalifa.",
	},
	{
		referenceName = "Soda Can",
		referenceHeight = 0.123,
		targetName = "Basketball Hoop",
		targetHeight = 3.05,
		category = "Everyday Objects",
		fact = "A regulation basketball hoop is 3.05 meters (10 feet) high -- about 25 soda cans stacked.",
	},
	{
		referenceName = "A4 Sheet of Paper",
		referenceHeight = 0.297,
		targetName = "Standard Door",
		targetHeight = 2.03,
		category = "Everyday Objects",
		fact = "A standard interior door is about 2.03 meters tall, roughly 7 sheets of A4 paper end to end.",
	},
	{
		referenceName = "Smartphone",
		referenceHeight = 0.15,
		targetName = "Refrigerator",
		targetHeight = 1.8,
		category = "Everyday Objects",
		fact = "A typical fridge stands about 1.8 meters tall -- 12 times the length of a smartphone.",
	},
	{
		referenceName = "Coffee Mug",
		referenceHeight = 0.1,
		targetName = "Upright Piano",
		targetHeight = 1.3,
		category = "Everyday Objects",
		fact = "An upright piano is about 1.3 meters tall -- 13 times the height of a coffee mug.",
	},
	{
		referenceName = "Earth",
		referenceHeight = 12742,
		targetName = "Moon",
		targetHeight = 3474,
		category = "Space",
		fact = "The Moon's diameter is about 3,474 km, roughly 27% of Earth's 12,742 km diameter.",
	},
	{
		referenceName = "Earth",
		referenceHeight = 12742,
		targetName = "Jupiter",
		targetHeight = 139820,
		category = "Space",
		fact = "Jupiter's diameter is about 139,820 km -- around 11 times wider than Earth.",
	},
	{
		referenceName = "Earth",
		referenceHeight = 12742,
		targetName = "The Sun",
		targetHeight = 1391000,
		category = "Space",
		fact = "The Sun's diameter is about 1,391,000 km -- roughly 109 times Earth's diameter.",
	},
}

return ScaleData
