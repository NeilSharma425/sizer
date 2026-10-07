--[[
	Pets.lua
	ModuleScript: ReplicatedStorage.Pets

	Every pet in the game: earned ones (rank, category, 60s score, login
	streak), crate-only ones dropped by airdrops (rule kind "crate") and egg
	pets hatched with Sense (rule kind "egg"). The equipped pet gives a Sense
	bonus (perkFor). build(id) returns a small
	anchored Model made of Parts, plus an animate(t) function for the parts
	that move or change colour. Used by the world pets (PetClient) and by the
	streak window previews.
]]

local Pets = {}

-- rule kinds: start (everyone), streak (login streak day, granted by
-- Progress.updateStreak), rank (rank number from Ranks), category (every
-- object in the category earned a Sizedex star), timed (60s challenge best).
Pets.List = {
	{ id = "mouse", perk = 0.02, name = "Pocket Mouse", color = Color3.fromRGB(190, 190, 205), rule = { kind = "start" }, how = "Everyone starts with this one", blurb = "Small, but it knows its sizes." },
	{ id = "robot", perk = 0.05, name = "Ruler Bot", color = Color3.fromRGB(120, 190, 255), rule = { kind = "rank", rank = 4 }, how = "Reach the Estimator rank", blurb = "Measures everything it sees." },
	{ id = "duck", perk = 0.08, name = "Rubber Duck", color = Color3.fromRGB(255, 220, 60), rule = { kind = "category", name = "Everyday Objects" }, how = "Earn a star on every Everyday Objects item", blurb = "Everyday hero." },
	{ id = "owl", perk = 0.08, name = "Wise Owl", color = Color3.fromRGB(170, 120, 80), rule = { kind = "category", name = "Animals" }, how = "Earn a star on every Animals item", blurb = "Has seen every animal there is." },
	{ id = "pyramid", perk = 0.08, name = "Pocket Pyramid", color = Color3.fromRGB(235, 200, 120), rule = { kind = "category", name = "Landmarks" }, how = "Earn a star on every Landmarks item", blurb = "A landmark you can carry." },
	{ id = "moon", perk = 0.08, name = "Moon Buddy", color = Color3.fromRGB(215, 220, 235), rule = { kind = "category", name = "Space" }, how = "Earn a star on every Space item", blurb = "Orbits you, politely." },
	{ id = "verity", perk = 0.1, name = "Mini Verity", color = Color3.fromRGB(255, 225, 70), rule = { kind = "category", name = "Brainrot" }, how = "Earn a star on every Brainrot item", blurb = "Giant energy, tiny size." },
	{ id = "bee", perk = 0.1, name = "Speed Bee", color = Color3.fromRGB(255, 205, 40), rule = { kind = "timed", score = 400 }, how = "Score 400 in the 60s challenge", blurb = "Buzzes through the clock." },
	{ id = "emberfox", perk = 0.1, name = "Ember Fox", color = Color3.fromRGB(255, 140, 50), rule = { kind = "streak", day = 3 }, how = "Reach a 3 day login streak", blurb = "Warm, quick, and a little bit magic." },
	{ id = "ghost", perk = 0.15, name = "Halo Ghost", color = Color3.fromRGB(235, 240, 255), rule = { kind = "rank", rank = 8 }, how = "Reach the Master rank", blurb = "Friendly, and a little holy." },
	{ id = "cosmiccube", perk = 0.15, name = "Cosmic Cube", color = Color3.fromRGB(130, 110, 255), rule = { kind = "streak", day = 7 }, how = "Reach a 7 day login streak", blurb = "A tiny galaxy that orbits you." },
	{ id = "rainbowslime", perk = 0.25, name = "Rainbow Slime", color = Color3.fromRGB(255, 120, 200), rule = { kind = "streak", day = 14 }, how = "Reach a 14 day login streak", blurb = "The rarest pet. Shifts through every colour." },
	-- Crate-only pets: dropped from airdrop crates, never earned any other way.
	{ id = "neonmouse", name = "Neon Mouse", color = Color3.fromRGB(80, 240, 150), rule = { kind = "crate" }, rarity = "Rare", variantOf = "mouse", hue = 0.38, shift = 0.38, minSat = 0.7, how = "Airdrop crates only", blurb = "Glows in the dark. Squeaks in color." },
	{ id = "skyduck", name = "Sky Duck", color = Color3.fromRGB(90, 170, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "duck", hue = 0.6, shift = 0.5, minSat = 0.5, how = "Airdrop crates only", blurb = "Fell from the clouds. Landed fine." },
	{ id = "rubybot", name = "Ruby Bot", color = Color3.fromRGB(255, 80, 90), rule = { kind = "crate" }, rarity = "Rare", variantOf = "robot", hue = 0.98, shift = 0.4, minSat = 0.5, how = "Airdrop crates only", blurb = "Overclocked and a little dramatic." },
	{ id = "crystalowl", name = "Crystal Owl", color = Color3.fromRGB(110, 230, 240), rule = { kind = "crate" }, rarity = "Epic", variantOf = "owl", hue = 0.5, shift = 0.5, minSat = 0.6, how = "Airdrop crates only", blurb = "Sees through every guess." },
	{ id = "stormbee", name = "Storm Bee", color = Color3.fromRGB(120, 140, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "bee", hue = 0.6, shift = 0.5, minSat = 0.6, how = "Airdrop crates only", blurb = "Brings its own weather." },
	{ id = "voidghost", name = "Void Ghost", color = Color3.fromRGB(180, 110, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "ghost", hue = 0.75, minSat = 0.55, how = "Airdrop crates only", blurb = "Haunts the spaces between sizes." },
	{ id = "babydragon", name = "Baby Dragon", color = Color3.fromRGB(255, 120, 70), rule = { kind = "crate" }, rarity = "Legendary", how = "Airdrop crates only", blurb = "Tiny, fierce, and very fond of you." },
	{ id = "solarverity", name = "Solar Verity", color = Color3.fromRGB(255, 210, 40), rule = { kind = "crate" }, rarity = "Legendary", variantOf = "verity", hue = 0.12, shift = 0, neon = true, how = "Airdrop crates only", blurb = "A star-powered smile." },
	{ id = "galaxymoon", name = "Galaxy Moon", color = Color3.fromRGB(150, 90, 255), rule = { kind = "crate" }, rarity = "Legendary", variantOf = "moon", hue = 0.72, shift = 0.72, minSat = 0.7, neon = true, how = "Airdrop crates only", blurb = "Carries a whole night sky." },
	{ id = "mintmouse", name = "Mint Mouse", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "mouse", hue = 0.42, shift = 0.42, minSat = 0.45, how = "Airdrop crates only", blurb = "Cool and quick." },
	{ id = "berrymouse", name = "Berry Mouse", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "mouse", hue = 0.92, shift = 0.92, minSat = 0.5, accessory = 'bow', how = "Airdrop crates only", blurb = "Sweet, with a bow." },
	{ id = "grapeduck", name = "Grape Duck", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "duck", hue = 0.78, shift = 0.64, minSat = 0.45, how = "Airdrop crates only", blurb = "Purple and proud." },
	{ id = "limeduck", name = "Lime Duck", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "duck", hue = 0.3, shift = 0.2, minSat = 0.5, how = "Airdrop crates only", blurb = "Zesty." },
	{ id = "roserobot", name = "Rose Bot", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "robot", hue = 0.93, shift = 0.35, minSat = 0.35, how = "Airdrop crates only", blurb = "Soft circuits." },
	{ id = "copperbot", name = "Copper Bot", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "robot", hue = 0.07, shift = 0.5, minSat = 0.55, how = "Airdrop crates only", blurb = "Old school and shiny." },
	{ id = "snowyowl", name = "Snowy Owl", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "owl", hue = 0.58, shift = 0, satMul = 0.1, valMul = 1.5, how = "Airdrop crates only", blurb = "Quiet and wise." },
	{ id = "berryowl", name = "Berry Owl", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "owl", hue = 0.82, shift = 0.78, minSat = 0.4, how = "Airdrop crates only", blurb = "Purple feathers." },
	{ id = "rosebee", name = "Rose Bee", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "bee", hue = 0.92, shift = 0.8, minSat = 0.4, how = "Airdrop crates only", blurb = "Pink and busy." },
	{ id = "marmaladecat", name = "Marmalade Cat", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "cat", accessory = 'bow', how = "Airdrop crates only", blurb = "Orange and unbothered." },
	{ id = "snowcat", name = "Snow Cat", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "cat", hue = 0.55, shift = 0, satMul = 0.08, valMul = 1.4, how = "Airdrop crates only", blurb = "Fluffy as a cloud." },
	{ id = "midnightcat", name = "Midnight Cat", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "cat", hue = 0.7, shift = 0.6, minSat = 0.4, valMul = 0.45, how = "Airdrop crates only", blurb = "Sneaks around at night." },
	{ id = "pocketpenguin", name = "Pocket Penguin", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "penguin", how = "Airdrop crates only", blurb = "Waddles in style." },
	{ id = "icepenguin", name = "Ice Penguin", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "penguin", hue = 0.55, shift = 0.55, minSat = 0.4, how = "Airdrop crates only", blurb = "Always chilly." },
	{ id = "snowbunny", name = "Snow Bunny", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "bunny", hue = 0.55, shift = 0, satMul = 0.1, valMul = 1.1, how = "Airdrop crates only", blurb = "Hops silently." },
	{ id = "carrotbunny", name = "Carrot Bunny", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "bunny", hue = 0.07, shift = 0.07, minSat = 0.55, how = "Airdrop crates only", blurb = "Loves its carrots." },
	{ id = "leaffrog", name = "Leaf Frog", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "frog", how = "Airdrop crates only", blurb = "Green all over." },
	{ id = "bluefrog", name = "Blue Frog", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "frog", hue = 0.6, shift = 0.5, minSat = 0.5, how = "Airdrop crates only", blurb = "Rare for a frog." },
	{ id = "pinkjelly", name = "Pink Jelly", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "jelly", how = "Airdrop crates only", blurb = "Wobbly and soft." },
	{ id = "bluejelly", name = "Blue Jelly", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "jelly", hue = 0.58, shift = 0.65, minSat = 0.45, how = "Airdrop crates only", blurb = "Floats along." },
	{ id = "redcap", name = "Red Cap", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "mushroom", how = "Airdrop crates only", blurb = "Spotted and friendly." },
	{ id = "bluecap", name = "Blue Cap", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "mushroom", hue = 0.6, shift = 0.6, minSat = 0.5, how = "Airdrop crates only", blurb = "A cool mushroom." },
	{ id = "peachghost", name = "Peach Ghost", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "ghost", hue = 0.05, minSat = 0.3, how = "Airdrop crates only", blurb = "Sweet and spooky." },
	{ id = "tealbee", name = "Teal Bee", color = Color3.fromRGB(80, 160, 255), rule = { kind = "crate" }, rarity = "Rare", variantOf = "bee", hue = 0.48, shift = 0.35, minSat = 0.4, how = "Airdrop crates only", blurb = "Fresh buzz." },
	{ id = "partyfox", name = "Party Fox", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "emberfox", accessory = 'partyhat', how = "Airdrop crates only", blurb = "Every day is a party." },
	{ id = "arcticfox", name = "Arctic Fox", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "emberfox", hue = 0.55, shift = 0.1, satMul = 0.15, valMul = 1.2, how = "Airdrop crates only", blurb = "Blends into the snow." },
	{ id = "royalcat", name = "Royal Cat", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "cat", hue = 0.75, shift = 0.62, minSat = 0.5, accessory = 'crown', how = "Airdrop crates only", blurb = "Demands snacks." },
	{ id = "wizardowl", name = "Wizard Owl", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "owl", hue = 0.7, shift = 0.65, minSat = 0.4, accessory = 'tophat', how = "Airdrop crates only", blurb = "Knows a spell or two." },
	{ id = "topperpenguin", name = "Top Hat Penguin", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "penguin", accessory = 'tophat', how = "Airdrop crates only", blurb = "Very dapper." },
	{ id = "sailorduck", name = "Sailor Duck", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "duck", hue = 0.6, shift = 0.5, minSat = 0.5, accessory = 'partyhat', how = "Airdrop crates only", blurb = "Ahoy!" },
	{ id = "neonbee", name = "Neon Bee", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "bee", hue = 0.5, shift = 0.4, minSat = 0.7, neon = true, how = "Airdrop crates only", blurb = "Glows while it buzzes." },
	{ id = "cybermouse", name = "Cyber Mouse", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "mouse", hue = 0.5, shift = 0.5, minSat = 0.8, neon = true, how = "Airdrop crates only", blurb = "Fresh from the future." },
	{ id = "glowjelly", name = "Glow Jelly", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "jelly", hue = 0.5, shift = 0.5, minSat = 0.7, neon = true, how = "Airdrop crates only", blurb = "Lights up the dark." },
	{ id = "sporecap", name = "Spore Cap", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "mushroom", hue = 0.78, shift = 0.72, minSat = 0.7, neon = true, how = "Airdrop crates only", blurb = "Magic spores." },
	{ id = "frostdragon", name = "Frost Dragon", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "babydragon", hue = 0.55, shift = 0.55, minSat = 0.5, how = "Airdrop crates only", blurb = "Breathes snowflakes." },
	{ id = "toxicfrog", name = "Toxic Frog", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "frog", hue = 0.28, shift = 0.1, minSat = 0.85, neon = true, how = "Airdrop crates only", blurb = "Do not lick." },
	{ id = "thunderbot", name = "Thunder Bot", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "robot", hue = 0.14, shift = 0.55, minSat = 0.7, neon = true, how = "Airdrop crates only", blurb = "Fully charged." },
	{ id = "auroraghost", name = "Aurora Ghost", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "ghost", hue = 0.45, minSat = 0.5, neon = true, accessory = 'halo', how = "Airdrop crates only", blurb = "Dances like northern lights." },
	{ id = "lavacube", name = "Lava Cube", color = Color3.fromRGB(190, 100, 255), rule = { kind = "crate" }, rarity = "Epic", variantOf = "cosmiccube", hue = 0.02, shift = 0.7, minSat = 0.8, neon = true, how = "Airdrop crates only", blurb = "Hot to the touch." },
	{ id = "golddragon", name = "Golden Dragon", color = Color3.fromRGB(255, 200, 50), rule = { kind = "crate" }, rarity = "Legendary", variantOf = "babydragon", hue = 0.13, shift = 0.09, minSat = 0.85, neon = true, accessory = 'crown', how = "Airdrop crates only", blurb = "Hoards your Sense." },
	{ id = "emeralddragon", name = "Emerald Dragon", color = Color3.fromRGB(255, 200, 50), rule = { kind = "crate" }, rarity = "Legendary", variantOf = "babydragon", hue = 0.38, shift = 0.33, minSat = 0.7, neon = true, how = "Airdrop crates only", blurb = "Scales like jewels." },
	{ id = "kingpenguin", name = "King Penguin", color = Color3.fromRGB(255, 200, 50), rule = { kind = "crate" }, rarity = "Legendary", variantOf = "penguin", hue = 0.13, shift = 0.13, minSat = 0.7, neon = true, accessory = 'crown', how = "Airdrop crates only", blurb = "Rules the ice." },
	{ id = "pharaohcat", name = "Pharaoh Cat", color = Color3.fromRGB(255, 200, 50), rule = { kind = "crate" }, rarity = "Legendary", variantOf = "cat", hue = 0.13, shift = 0.05, minSat = 0.8, neon = true, accessory = 'crown', how = "Airdrop crates only", blurb = "Worshipped by many." },
	{ id = "starbunny", name = "Star Bunny", color = Color3.fromRGB(255, 200, 50), rule = { kind = "crate" }, rarity = "Legendary", variantOf = "bunny", hue = 0.15, shift = 0.15, minSat = 0.75, neon = true, accessory = 'halo', how = "Airdrop crates only", blurb = "Hops between stars." },
	{ id = "phoenixfox", name = "Phoenix Fox", color = Color3.fromRGB(255, 200, 50), rule = { kind = "crate" }, rarity = "Legendary", variantOf = "emberfox", hue = 0.02, shift = 0.0, minSat = 0.9, neon = true, accessory = 'halo', how = "Airdrop crates only", blurb = "Reborn from the flames." },
	{ id = "diamondowl", name = "Diamond Owl", color = Color3.fromRGB(255, 200, 50), rule = { kind = "crate" }, rarity = "Legendary", variantOf = "owl", hue = 0.5, shift = 0.5, minSat = 0.35, neon = true, accessory = 'crown', how = "Airdrop crates only", blurb = "Sparkles when it blinks." },
	{ id = "eclipsemoon", name = "Eclipse Moon", color = Color3.fromRGB(255, 200, 50), rule = { kind = "crate" }, rarity = "Legendary", variantOf = "moon", hue = 0.08, shift = 0.05, minSat = 0.8, valMul = 0.8, neon = true, how = "Airdrop crates only", blurb = "The sun hides behind it." },
	{ id = "celestialdragon", name = "Celestial Dragon", color = Color3.fromRGB(255, 90, 200), rule = { kind = "crate" }, rarity = "Mythic", variantOf = "babydragon", hue = 0.12, shift = 0.0, minSat = 0.2, neon = true, accessory = 'halo', rainbow = true, how = "Airdrop crates only", blurb = "A dragon made of the whole sky." },
	{ id = "prismfox", name = "Prism Fox", color = Color3.fromRGB(255, 90, 200), rule = { kind = "crate" }, rarity = "Mythic", variantOf = "emberfox", neon = true, rainbow = true, accessory = 'crown', how = "Airdrop crates only", blurb = "Every color at once." },
	{ id = "prismghost", name = "Prism Ghost", color = Color3.fromRGB(255, 90, 200), rule = { kind = "crate" }, rarity = "Mythic", variantOf = "ghost", hue = 0.5, minSat = 0.5, neon = true, rainbow = true, accessory = 'halo', how = "Airdrop crates only", blurb = "A rainbow you can't catch." },
	-- Egg pets: hatched from eggs bought with Sense in the PETS window.
	{ id = "pebblemouse", name = "Pebble Mouse", color = Color3.fromRGB(190, 195, 210), rule = { kind = "egg" }, rarity = "Common", variantOf = "mouse", hue = 0.08, satMul = 0.3, valMul = 0.8, how = "Hatch from eggs", blurb = "Fits in a pocket." },
	{ id = "puddleduck", name = "Puddle Duck", color = Color3.fromRGB(190, 195, 210), rule = { kind = "egg" }, rarity = "Common", variantOf = "duck", hue = 0.55, shift = 0.42, satMul = 0.45, how = "Hatch from eggs", blurb = "Loves rainy days." },
	{ id = "tabbycat", name = "Tabby Cat", color = Color3.fromRGB(190, 195, 210), rule = { kind = "egg" }, rarity = "Common", variantOf = "cat", valMul = 0.85, how = "Hatch from eggs", blurb = "A classic." },
	{ id = "cocoabunny", name = "Cocoa Bunny", color = Color3.fromRGB(190, 195, 210), rule = { kind = "egg" }, rarity = "Common", variantOf = "bunny", hue = 0.07, minSat = 0.45, valMul = 0.6, how = "Hatch from eggs", blurb = "Sweet as chocolate." },
	{ id = "gardenfrog", name = "Garden Frog", color = Color3.fromRGB(190, 195, 210), rule = { kind = "egg" }, rarity = "Common", variantOf = "frog", shift = -0.05, satMul = 0.7, how = "Hatch from eggs", blurb = "Lives under a leaf." },
	{ id = "buttoncap", name = "Button Cap", color = Color3.fromRGB(190, 195, 210), rule = { kind = "egg" }, rarity = "Common", variantOf = "mushroom", hue = 0.08, shift = 0.07, satMul = 0.6, how = "Hatch from eggs", blurb = "Small but mighty." },
	{ id = "bubblejelly", name = "Bubble Jelly", color = Color3.fromRGB(190, 195, 210), rule = { kind = "egg" }, rarity = "Common", variantOf = "jelly", hue = 0.55, shift = 0.6, satMul = 0.5, how = "Hatch from eggs", blurb = "Pop!" },
	{ id = "mossyfrog", name = "Mossy Frog", color = Color3.fromRGB(110, 210, 110), rule = { kind = "egg" }, rarity = "Uncommon", variantOf = "frog", shift = 0.1, minSat = 0.5, valMul = 0.75, how = "Hatch from eggs", blurb = "Covered in moss." },
	{ id = "rustybot", name = "Rusty Bot", color = Color3.fromRGB(110, 210, 110), rule = { kind = "egg" }, rarity = "Uncommon", variantOf = "robot", hue = 0.07, shift = 0.47, minSat = 0.5, valMul = 0.7, how = "Hatch from eggs", blurb = "Still works. Mostly." },
	{ id = "lilacjelly", name = "Lilac Jelly", color = Color3.fromRGB(110, 210, 110), rule = { kind = "egg" }, rarity = "Uncommon", variantOf = "jelly", hue = 0.78, shift = 0.85, minSat = 0.4, how = "Hatch from eggs", blurb = "Smells like flowers." },
	{ id = "cherrypenguin", name = "Cherry Penguin", color = Color3.fromRGB(110, 210, 110), rule = { kind = "egg" }, rarity = "Uncommon", variantOf = "penguin", hue = 0.97, shift = 0.97, minSat = 0.55, how = "Hatch from eggs", blurb = "Bright red waddler." },
	{ id = "sunnyowl", name = "Sunny Owl", color = Color3.fromRGB(110, 210, 110), rule = { kind = "egg" }, rarity = "Uncommon", variantOf = "owl", shift = 0.06, minSat = 0.65, how = "Hatch from eggs", blurb = "A morning owl, somehow." },
	{ id = "sproutcap", name = "Sprout Cap", color = Color3.fromRGB(110, 210, 110), rule = { kind = "egg" }, rarity = "Uncommon", variantOf = "mushroom", hue = 0.3, shift = 0.3, minSat = 0.5, how = "Hatch from eggs", blurb = "Fresh from the forest floor." },
	{ id = "cloudowl", name = "Cloud Owl", color = Color3.fromRGB(80, 160, 255), rule = { kind = "egg" }, rarity = "Rare", variantOf = "owl", hue = 0.6, satMul = 0.15, valMul = 1.5, accessory = 'halo', how = "Hatch from eggs", blurb = "Soft as a cloud." },
	{ id = "oceanpenguin", name = "Ocean Penguin", color = Color3.fromRGB(80, 160, 255), rule = { kind = "egg" }, rarity = "Rare", variantOf = "penguin", hue = 0.55, shift = 0.55, minSat = 0.6, how = "Hatch from eggs", blurb = "Born in the deep blue." },
	{ id = "sapphirecat", name = "Sapphire Cat", color = Color3.fromRGB(80, 160, 255), rule = { kind = "egg" }, rarity = "Rare", variantOf = "cat", hue = 0.62, shift = 0.55, minSat = 0.6, how = "Hatch from eggs", blurb = "Sparkly blue fur." },
	{ id = "seadragon", name = "Sea Dragon", color = Color3.fromRGB(190, 100, 255), rule = { kind = "egg" }, rarity = "Epic", variantOf = "babydragon", hue = 0.5, shift = 0.48, minSat = 0.5, how = "Hatch from eggs", blurb = "Swims through the sky." },
	{ id = "sugarfox", name = "Sugar Fox", color = Color3.fromRGB(190, 100, 255), rule = { kind = "egg" }, rarity = "Epic", variantOf = "emberfox", hue = 0.9, shift = 0.85, minSat = 0.4, accessory = 'bow', how = "Hatch from eggs", blurb = "Made of candy floss." },
}

-- Rarities: the color shown in the UI, the Sense perk a pet of that rarity
-- gives while equipped, and (for crates) the chance a drop is that rarity.
Pets.Rarities = {
	Common = { color = Color3.fromRGB(190, 195, 210), perk = 0.03 },
	Uncommon = { color = Color3.fromRGB(110, 210, 110), perk = 0.06 },
	Rare = { color = Color3.fromRGB(80, 160, 255), weight = 59, perk = 0.10 },
	Epic = { color = Color3.fromRGB(190, 100, 255), weight = 30, perk = 0.15 },
	Legendary = { color = Color3.fromRGB(255, 200, 50), weight = 10, perk = 0.22 },
	Mythic = { color = Color3.fromRGB(255, 90, 200), weight = 1, perk = 0.35 }, -- 1% of drops
}
Pets.RarityOrder = { "Rare", "Epic", "Legendary", "Mythic" } -- crate rarities, rarest last
Pets.AllRarities = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

-- Eggs sold for Sense. odds are rarity weights out of 100.
Pets.Eggs = {
	{ id = "basic", name = "Basic Egg", price = 250, color = Color3.fromRGB(235, 225, 200), odds = { Common = 60, Uncommon = 30, Rare = 10 } },
	{ id = "golden", name = "Golden Egg", price = 1500, color = Color3.fromRGB(255, 205, 60), odds = { Uncommon = 50, Rare = 40, Epic = 10 } },
}
Pets.DUPLICATE_REFUND = 0.3 -- share of the price given back for a pet you already have

function Pets.getEgg(id)
	for _, egg in ipairs(Pets.Eggs) do
		if egg.id == id then
			return egg
		end
	end
	return nil
end

-- Sense bonus (0.1 = +10%) the pet gives while equipped.
function Pets.perkFor(id)
	local pet = Pets.get(id)
	if not pet then
		return 0
	end
	if pet.perk then
		return pet.perk
	end
	local rarity = pet.rarity and Pets.Rarities[pet.rarity]
	return rarity and rarity.perk or 0
end

-- Picks the pet an egg hatches: a rarity by the egg's odds, then a random
-- egg pet of that rarity.
function Pets.rollEgg(egg, rng)
	local order, total = {}, 0
	for _, name in ipairs(Pets.AllRarities) do
		if egg.odds[name] then
			table.insert(order, name)
			total += egg.odds[name]
		end
	end
	local roll = rng:NextNumber(0, total)
	local rarity = order[#order]
	for _, name in ipairs(order) do
		roll -= egg.odds[name]
		if roll <= 0 then
			rarity = name
			break
		end
	end
	local pool = {}
	for _, pet in ipairs(Pets.List) do
		if pet.rule.kind == "egg" and pet.rarity == rarity then
			table.insert(pool, pet)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- All crate pets (in list order).
function Pets.cratePets()
	local out = {}
	for _, pet in ipairs(Pets.List) do
		if pet.rule.kind == "crate" then
			table.insert(out, pet)
		end
	end
	return out
end

-- Picks a crate pet for a drop: a rarity by weight, then a random pet of
-- that rarity. `rng` needs NextNumber(min, max) and NextInteger(min, max).
function Pets.rollCratePet(rng)
	local total = 0
	for _, name in ipairs(Pets.RarityOrder) do
		total += Pets.Rarities[name].weight
	end
	local roll = rng:NextNumber(0, total)
	local rarity = Pets.RarityOrder[#Pets.RarityOrder]
	for _, name in ipairs(Pets.RarityOrder) do
		roll -= Pets.Rarities[name].weight
		if roll <= 0 then
			rarity = name
			break
		end
	end
	local pool = {}
	for _, pet in ipairs(Pets.cratePets()) do
		if pet.rarity == rarity then
			table.insert(pool, pet)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- True when a non-streak rule is met. state = { rank (number), cats (table),
-- timedBest (number) }. Streak pets are granted by the login streak.
function Pets.qualifies(rule, state)
	if rule.kind == "start" then
		return true
	elseif rule.kind == "rank" then
		return (state.rank or 1) >= rule.rank
	elseif rule.kind == "category" then
		return state.cats ~= nil and state.cats[rule.name] == true
	elseif rule.kind == "timed" then
		return (state.timedBest or 0) >= rule.score
	end
	return false
end

function Pets.get(id)
	for _, pet in ipairs(Pets.List) do
		if pet.id == id then
			return pet
		end
	end
	return nil
end

local function part(model, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		p[key] = value
	end
	p.Parent = model
	return p
end

local function ball(model, size, color, offset)
	return part(model, {
		Shape = Enum.PartType.Ball,
		Size = size,
		Color = color,
		CFrame = CFrame.new(offset),
	})
end

-- Each builder fills `model` around the origin (about 2.4 studs tall) and
-- returns an animate(t) function, or nil.
local builders = {}

function builders.emberfox(model)
	local orange = Color3.fromRGB(255, 140, 50)
	local cream = Color3.fromRGB(255, 235, 205)
	local dark = Color3.fromRGB(60, 35, 30)
	ball(model, Vector3.new(1.7, 1.4, 2.2), orange, Vector3.new(0, 0, 0)) -- body
	ball(model, Vector3.new(1.5, 1.4, 1.4), orange, Vector3.new(0, 0.7, -1.1)) -- head
	ball(model, Vector3.new(0.9, 0.6, 0.6), cream, Vector3.new(0, 0.5, -1.7)) -- snout
	ball(model, Vector3.new(0.28, 0.28, 0.28), dark, Vector3.new(0, 0.6, -2.0)) -- nose
	ball(model, Vector3.new(0.25, 0.3, 0.2), dark, Vector3.new(-0.38, 0.95, -1.75))
	ball(model, Vector3.new(0.25, 0.3, 0.2), dark, Vector3.new(0.38, 0.95, -1.75))
	for _, x in ipairs({ -0.5, 0.5 }) do -- ears
		part(model, {
			Size = Vector3.new(0.45, 0.9, 0.3),
			Color = orange,
			CFrame = CFrame.new(x, 1.7, -1.0) * CFrame.Angles(0, 0, x * 0.5),
		})
		part(model, {
			Size = Vector3.new(0.22, 0.5, 0.32),
			Color = dark,
			CFrame = CFrame.new(x, 1.65, -1.05) * CFrame.Angles(0, 0, x * 0.5),
		})
	end
	for _, x in ipairs({ -0.5, 0.5 }) do -- paws
		part(model, { Size = Vector3.new(0.45, 0.5, 0.6), Color = dark, CFrame = CFrame.new(x, -0.85, -0.5) })
		part(model, { Size = Vector3.new(0.45, 0.5, 0.6), Color = dark, CFrame = CFrame.new(x, -0.85, 0.6) })
	end
	local tail = ball(model, Vector3.new(0.9, 0.9, 2.0), orange, Vector3.new(0, 0.4, 1.7))
	local tip = part(model, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.8, 0.8, 0.9),
		Color = Color3.fromRGB(255, 220, 90),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(0, 0.4, 2.7),
	})
	local tailBase, tipBase = tail.CFrame, tip.CFrame
	return function(t, o)
		local sway = CFrame.Angles(0, math.sin(t * 3) * 0.35, 0)
		local pivot = CFrame.new(0, 0.4, 0.9)
		tail.CFrame = o * pivot * sway * (pivot:Inverse() * tailBase)
		tip.CFrame = o * pivot * sway * (pivot:Inverse() * tipBase)
	end
end

function builders.cosmiccube(model)
	local core = part(model, {
		Size = Vector3.new(1.3, 1.3, 1.3),
		Color = Color3.fromRGB(110, 90, 240),
		Material = Enum.Material.Neon,
		CFrame = CFrame.new(0, 0, 0),
	})
	local shell = part(model, {
		Size = Vector3.new(1.9, 1.9, 1.9),
		Color = Color3.fromRGB(190, 170, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.45,
		CFrame = CFrame.new(0, 0, 0),
	})
	local moons = {}
	for i = 1, 3 do
		moons[i] = ball(model, Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(255, 240, 160), Vector3.new(0, 0, 0))
		moons[i].Material = Enum.Material.Neon
	end
	return function(t, o)
		local spin = o * CFrame.Angles(t * 0.8, t * 1.1, t * 0.5)
		core.CFrame = spin
		shell.CFrame = spin
		for i, moon in ipairs(moons) do
			local a = t * 1.8 + i * (math.pi * 2 / 3)
			moon.CFrame = o * CFrame.new(math.cos(a) * 1.7, math.sin(a * 0.7 + i) * 0.7, math.sin(a) * 1.7)
		end
	end
end

function builders.rainbowslime(model)
	local body = part(model, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 1.8, 2.2),
		Color = Color3.fromRGB(255, 120, 200),
		Material = Enum.Material.Glass,
		Transparency = 0.15,
		CFrame = CFrame.new(0, 0, 0),
	})
	local core = ball(model, Vector3.new(0.9, 0.9, 0.9), Color3.new(1, 1, 1), Vector3.new(0, -0.1, 0))
	core.Material = Enum.Material.Neon
	local eyes = {}
	for _, x in ipairs({ -0.45, 0.45 }) do
		eyes[#eyes + 1] = ball(model, Vector3.new(0.3, 0.42, 0.2), Color3.fromRGB(30, 25, 45), Vector3.new(x, 0.25, -1.0))
	end
	local sparks = {}
	for i = 1, 4 do
		sparks[i] = ball(model, Vector3.new(0.25, 0.25, 0.25), Color3.new(1, 1, 1), Vector3.new(0, 0, 0))
		sparks[i].Material = Enum.Material.Neon
	end
	return function(t, o)
		local squish = 1 + 0.08 * math.sin(t * 4)
		body.Size = Vector3.new(2.2 / squish, 1.8 * squish, 2.2 / squish)
		body.CFrame = o
		core.CFrame = o * CFrame.new(0, -0.1, 0)
		body.Color = Color3.fromHSV((t * 0.25) % 1, 0.6, 1)
		core.Color = Color3.fromHSV((t * 0.25 + 0.5) % 1, 0.5, 1)
		for i, spark in ipairs(sparks) do
			local a = t * 2 + i * (math.pi / 2)
			spark.CFrame = o * CFrame.new(math.cos(a) * 1.5, 1.2 + math.sin(a * 2) * 0.3, math.sin(a) * 1.5)
			spark.Color = Color3.fromHSV((t * 0.5 + i / 4) % 1, 0.7, 1)
		end
	end
end

function builders.mouse(model)
	local gray = Color3.fromRGB(190, 190, 205)
	local pink = Color3.fromRGB(255, 170, 190)
	ball(model, Vector3.new(1.4, 1.2, 1.9), gray, Vector3.new(0, 0, 0))
	ball(model, Vector3.new(1.0, 0.9, 1.0), gray, Vector3.new(0, 0.2, -1.1))
	ball(model, Vector3.new(0.25, 0.25, 0.25), pink, Vector3.new(0, 0.2, -1.65))
	ball(model, Vector3.new(0.2, 0.25, 0.15), Color3.fromRGB(30, 25, 40), Vector3.new(-0.28, 0.5, -1.45))
	ball(model, Vector3.new(0.2, 0.25, 0.15), Color3.fromRGB(30, 25, 40), Vector3.new(0.28, 0.5, -1.45))
	for _, x in ipairs({ -0.5, 0.5 }) do
		part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 0.8, 0.8), Color = pink, CFrame = CFrame.new(x, 0.95, -0.95) * CFrame.Angles(0, math.pi / 2, 0) })
	end
	local tail = part(model, { Size = Vector3.new(0.15, 0.15, 1.6), Color = pink, CFrame = CFrame.new(0, -0.2, 1.7) })
	local base = tail.CFrame
	return function(t, o)
		tail.CFrame = o * CFrame.Angles(0, math.sin(t * 5) * 0.4, 0) * base
	end
end

function builders.robot(model)
	local blue = Color3.fromRGB(120, 190, 255)
	part(model, { Size = Vector3.new(1.6, 1.4, 1.4), Color = blue, Material = Enum.Material.Metal, CFrame = CFrame.new(0, -0.3, 0) })
	part(model, { Size = Vector3.new(1.3, 1.0, 1.2), Color = Color3.fromRGB(220, 230, 245), Material = Enum.Material.Metal, CFrame = CFrame.new(0, 0.9, 0) })
	for _, x in ipairs({ -0.3, 0.3 }) do
		part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.fromRGB(80, 255, 200), Material = Enum.Material.Neon, CFrame = CFrame.new(x, 0.95, -0.62) })
	end
	part(model, { Size = Vector3.new(0.08, 0.5, 0.08), Color = Color3.fromRGB(60, 60, 80), CFrame = CFrame.new(0, 1.65, 0) })
	local bulb = part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.fromRGB(255, 90, 90), Material = Enum.Material.Neon, CFrame = CFrame.new(0, 1.95, 0) })
	-- ruler marks on the belly
	for i = -2, 2 do
		part(model, { Size = Vector3.new(i % 2 == 0 and 0.5 or 0.3, 0.06, 0.05), Color = Color3.fromRGB(40, 50, 90), CFrame = CFrame.new(0, -0.3 + i * 0.2, -0.71) })
	end
	return function(t, o)
		bulb.CFrame = o * CFrame.new(0, 1.95 + math.sin(t * 6) * 0.05, 0)
		bulb.Transparency = 0.5 + 0.5 * math.sin(t * 6) * 0.5
	end
end

function builders.duck(model)
	local yellow = Color3.fromRGB(255, 220, 60)
	ball(model, Vector3.new(1.9, 1.4, 2.2), yellow, Vector3.new(0, -0.1, 0))
	ball(model, Vector3.new(1.2, 1.2, 1.2), yellow, Vector3.new(0, 0.9, -0.8))
	part(model, { Size = Vector3.new(0.7, 0.2, 0.6), Color = Color3.fromRGB(255, 140, 40), CFrame = CFrame.new(0, 0.75, -1.5) })
	ball(model, Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(30, 25, 40), Vector3.new(-0.3, 1.1, -1.25))
	ball(model, Vector3.new(0.2, 0.2, 0.2), Color3.fromRGB(30, 25, 40), Vector3.new(0.3, 1.1, -1.25))
	ball(model, Vector3.new(0.5, 0.8, 1.2), Color3.fromRGB(255, 200, 40), Vector3.new(-0.95, 0, 0.1))
	ball(model, Vector3.new(0.5, 0.8, 1.2), Color3.fromRGB(255, 200, 40), Vector3.new(0.95, 0, 0.1))
	return nil
end

function builders.owl(model)
	local brown = Color3.fromRGB(150, 105, 70)
	local cream = Color3.fromRGB(240, 225, 195)
	ball(model, Vector3.new(1.9, 2.1, 1.7), brown, Vector3.new(0, 0, 0))
	ball(model, Vector3.new(1.2, 1.3, 0.5), cream, Vector3.new(0, -0.2, -0.6))
	for _, x in ipairs({ -0.45, 0.45 }) do
		ball(model, Vector3.new(0.75, 0.75, 0.3), Color3.new(1, 1, 1), Vector3.new(x, 0.55, -0.75))
		ball(model, Vector3.new(0.35, 0.35, 0.2), Color3.fromRGB(30, 25, 40), Vector3.new(x, 0.55, -0.9))
		part(model, { Size = Vector3.new(0.3, 0.55, 0.3), Color = brown, CFrame = CFrame.new(x * 1.2, 1.2, -0.1) * CFrame.Angles(0, 0, x * 0.6) })
	end
	part(model, { Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.fromRGB(255, 170, 50), CFrame = CFrame.new(0, 0.2, -0.9) * CFrame.Angles(math.pi / 4, 0, math.pi / 4) })
	local wings = {}
	for i, x in ipairs({ -1, 1 }) do
		wings[i] = { part = ball(model, Vector3.new(0.35, 1.5, 1.0), Color3.fromRGB(120, 80, 55), Vector3.new(x * 1.0, -0.1, 0.1)), side = x }
	end
	return function(t, o)
		for _, w in ipairs(wings) do
			w.part.CFrame = o * CFrame.new(w.side * 1.0, -0.1, 0.1) * CFrame.Angles(0, 0, w.side * (0.1 + 0.15 * math.sin(t * 3)))
		end
	end
end

function builders.pyramid(model)
	local sand = Color3.fromRGB(235, 200, 120)
	-- stacked slabs make a stepped pyramid
	for i = 0, 4 do
		local w = 2.4 - i * 0.45
		part(model, { Size = Vector3.new(w, 0.45, w), Color = sand:Lerp(Color3.fromRGB(190, 150, 80), i * 0.12), CFrame = CFrame.new(0, -0.9 + i * 0.45, 0) })
	end
	for _, x in ipairs({ -0.35, 0.35 }) do
		ball(model, Vector3.new(0.4, 0.4, 0.2), Color3.new(1, 1, 1), Vector3.new(x, 0.1, -0.85))
		ball(model, Vector3.new(0.2, 0.2, 0.15), Color3.fromRGB(30, 25, 40), Vector3.new(x, 0.1, -0.95))
	end
	return nil
end

function builders.moon(model)
	local gray = Color3.fromRGB(215, 220, 235)
	local moon = ball(model, Vector3.new(2.2, 2.2, 2.2), gray, Vector3.new(0, 0, 0))
	for _, c in ipairs({ { -0.6, 0.5, -0.85, 0.6 }, { 0.5, -0.4, -0.95, 0.5 }, { 0.2, 0.8, -0.8, 0.35 } }) do
		ball(model, Vector3.new(c[4], c[4], 0.15), Color3.fromRGB(175, 180, 200), Vector3.new(c[1], c[2], c[3]))
	end
	ball(model, Vector3.new(0.2, 0.28, 0.15), Color3.fromRGB(30, 25, 40), Vector3.new(-0.35, 0.1, -1.05))
	ball(model, Vector3.new(0.2, 0.28, 0.15), Color3.fromRGB(30, 25, 40), Vector3.new(0.35, 0.1, -1.05))
	local star = part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.fromRGB(255, 240, 150), Material = Enum.Material.Neon, CFrame = CFrame.new(1.8, 0, 0) })
	return function(t, o)
		moon.CFrame = o
		star.CFrame = o * CFrame.new(math.cos(t * 2) * 1.8, math.sin(t * 2) * 0.5, math.sin(t * 2) * 1.8)
	end
end

function builders.verity(model)
	local yellow = Color3.fromRGB(255, 225, 70)
	ball(model, Vector3.new(2.2, 2.2, 2.2), yellow, Vector3.new(0, 0, 0))
	for _, x in ipairs({ -0.5, 0.5 }) do
		ball(model, Vector3.new(0.5, 0.8, 0.25), Color3.fromRGB(30, 25, 40), Vector3.new(x, 0.3, -1.0))
		ball(model, Vector3.new(0.18, 0.28, 0.1), Color3.new(1, 1, 1), Vector3.new(x + 0.06, 0.5, -1.1))
	end
	part(model, { Size = Vector3.new(1.3, 0.45, 0.15), Color = Color3.new(1, 1, 1), CFrame = CFrame.new(0, -0.5, -1.0) })
	part(model, { Size = Vector3.new(1.3, 0.04, 0.17), Color = Color3.fromRGB(30, 25, 40), CFrame = CFrame.new(0, -0.5, -1.0) })
	return nil
end

function builders.bee(model)
	local yellow = Color3.fromRGB(255, 205, 40)
	local black = Color3.fromRGB(35, 30, 40)
	ball(model, Vector3.new(1.6, 1.5, 2.2), yellow, Vector3.new(0, 0, 0))
	for _, z in ipairs({ -0.3, 0.5 }) do
		part(model, { Size = Vector3.new(1.55, 1.2, 0.3), Color = black, CFrame = CFrame.new(0, 0, z) })
	end
	ball(model, Vector3.new(1.1, 1.1, 1.1), yellow, Vector3.new(0, 0.1, -1.4))
	ball(model, Vector3.new(0.22, 0.28, 0.15), black, Vector3.new(-0.3, 0.3, -1.85))
	ball(model, Vector3.new(0.22, 0.28, 0.15), black, Vector3.new(0.3, 0.3, -1.85))
	local wings = {}
	for i, x in ipairs({ -1, 1 }) do
		wings[i] = { part = part(model, { Size = Vector3.new(1.2, 0.08, 0.8), Color = Color3.fromRGB(210, 240, 255), Transparency = 0.4, CFrame = CFrame.new(x * 0.9, 0.9, 0) }), side = x }
	end
	return function(t, o)
		for _, w in ipairs(wings) do
			w.part.CFrame = o * CFrame.new(w.side * 0.9, 0.9, 0) * CFrame.Angles(0, 0, w.side * math.sin(t * 30) * 0.5)
		end
	end
end

function builders.ghost(model)
	local white = Color3.fromRGB(235, 240, 255)
	ball(model, Vector3.new(1.9, 2.0, 1.9), white, Vector3.new(0, 0.3, 0))
	part(model, { Size = Vector3.new(1.9, 1.0, 1.7), Color = white, CFrame = CFrame.new(0, -0.6, 0) })
	for i = -1, 1 do
		ball(model, Vector3.new(0.65, 0.65, 0.65), white, Vector3.new(i * 0.62, -1.1, 0))
	end
	for _, x in ipairs({ -0.4, 0.4 }) do
		ball(model, Vector3.new(0.3, 0.45, 0.2), Color3.fromRGB(40, 40, 70), Vector3.new(x, 0.45, -0.88))
	end
	ball(model, Vector3.new(0.4, 0.25, 0.2), Color3.fromRGB(255, 160, 170), Vector3.new(0, 0.0, -0.9))
	local halo = part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, 1.5, 1.5), Color = Color3.fromRGB(255, 220, 90), Material = Enum.Material.Neon, CFrame = CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.pi / 2) })
	return function(t, o)
		halo.CFrame = o * CFrame.new(0, 1.7 + math.sin(t * 3) * 0.1, 0) * CFrame.Angles(0, 0, math.pi / 2)
	end
end


function builders.babydragon(model)
	local scale, belly, horn = Color3.fromRGB(255, 120, 70), Color3.fromRGB(255, 220, 150), Color3.fromRGB(250, 235, 200)
	ball(model, Vector3.new(1.7, 1.6, 2.4), scale, Vector3.new(0, 0, 0))
	ball(model, Vector3.new(1.3, 1.1, 1.9), belly, Vector3.new(0, -0.25, -0.2))
	ball(model, Vector3.new(1.5, 1.4, 1.5), scale, Vector3.new(0, 0.8, -1.4))
	ball(model, Vector3.new(0.9, 0.6, 0.7), belly, Vector3.new(0, 0.6, -2.05))
	for _, x in ipairs({ -0.3, 0.3 }) do
		ball(model, Vector3.new(0.3, 0.38, 0.2), Color3.fromRGB(30, 25, 40), Vector3.new(x, 1.05, -2.0))
		part(model, { Size = Vector3.new(0.18, 0.7, 0.18), Color = horn, CFrame = CFrame.new(x * 1.4, 1.75, -1.2) * CFrame.Angles(math.rad(-20), 0, x * 0.6) })
	end
	for _, x in ipairs({ -0.5, 0.5 }) do
		part(model, { Size = Vector3.new(0.4, 0.5, 0.5), Color = scale, CFrame = CFrame.new(x, -0.95, -0.6) })
		part(model, { Size = Vector3.new(0.4, 0.5, 0.5), Color = scale, CFrame = CFrame.new(x, -0.95, 0.6) })
	end
	for i = 0, 4 do -- tail
		ball(model, Vector3.new(0.8 - i * 0.13, 0.8 - i * 0.13, 0.8), scale, Vector3.new(0, 0.1 - i * 0.05, 1.3 + i * 0.55))
	end
	local flame = part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), Color = Color3.fromRGB(255, 190, 60), Material = Enum.Material.Neon, CFrame = CFrame.new(0, 0.6, -2.5) })
	local wings = {}
	for i, side in ipairs({ -1, 1 }) do
		wings[i] = { part = part(model, { Size = Vector3.new(1.5, 0.9, 0.12), Color = Color3.fromRGB(255, 160, 110), CFrame = CFrame.new(side * 1.3, 0.9, 0.2) }), side = side }
	end
	return function(t, o)
		for _, w in ipairs(wings) do
			w.part.CFrame = o * CFrame.new(w.side * 0.7, 0.8, 0.5) * CFrame.Angles(0, 0, w.side * (0.2 + 0.4 * math.sin(t * 6))) * CFrame.new(w.side * 0.8, 0.3, 0)
		end
		flame.CFrame = o * CFrame.new(0, 0.6, -2.5 - 0.1 * math.sin(t * 9))
		flame.Transparency = 0.2 + 0.3 * math.sin(t * 9) ^ 2
	end
end


function builders.cat(model)
	local orange, cream, dark = Color3.fromRGB(255, 170, 90), Color3.fromRGB(255, 235, 205), Color3.fromRGB(40, 30, 40)
	ball(model, Vector3.new(1.7, 1.5, 2.2), orange, Vector3.new(0, 0, 0))
	ball(model, Vector3.new(1.6, 1.5, 1.5), orange, Vector3.new(0, 0.85, -1.1))
	ball(model, Vector3.new(0.8, 0.5, 0.5), cream, Vector3.new(0, 0.65, -1.75))
	ball(model, Vector3.new(0.22, 0.18, 0.18), Color3.fromRGB(255, 130, 150), Vector3.new(0, 0.8, -2.0))
	for _, x in ipairs({ -0.45, 0.45 }) do
		part(model, { Size = Vector3.new(0.4, 0.55, 0.25), Color = orange, CFrame = CFrame.new(x, 1.8, -1.0) * CFrame.Angles(0, 0, x * 0.5) })
		ball(model, Vector3.new(0.28, 0.4, 0.18), dark, Vector3.new(x * 0.8, 1.05, -1.82))
		part(model, { Size = Vector3.new(0.6, 0.04, 0.04), Color = WHITE, CFrame = CFrame.new(x * 1.7, 0.65, -1.85) })
		part(model, { Size = Vector3.new(0.45, 0.5, 0.6), Color = orange, CFrame = CFrame.new(x, -0.85, -0.6) })
		part(model, { Size = Vector3.new(0.45, 0.5, 0.6), Color = orange, CFrame = CFrame.new(x, -0.85, 0.6) })
	end
	local tail = part(model, { Size = Vector3.new(0.3, 0.3, 1.8), Color = orange, CFrame = CFrame.new(0, 0.5, 1.9) * CFrame.Angles(math.rad(-30), 0, 0) })
	local base = tail.CFrame
	return function(t, o)
		tail.CFrame = o * CFrame.Angles(0, math.sin(t * 3) * 0.4, 0) * base
	end
end

function builders.penguin(model)
	local black, white, orange = Color3.fromRGB(40, 42, 62), Color3.fromRGB(250, 250, 255), Color3.fromRGB(255, 160, 40)
	ball(model, Vector3.new(1.8, 2.4, 1.6), black, Vector3.new(0, 0, 0))
	ball(model, Vector3.new(1.3, 1.9, 0.5), white, Vector3.new(0, -0.1, -0.65))
	ball(model, Vector3.new(1.4, 1.3, 1.3), black, Vector3.new(0, 1.35, -0.1))
	part(model, { Size = Vector3.new(0.4, 0.2, 0.5), Color = orange, CFrame = CFrame.new(0, 1.3, -0.85) })
	for _, x in ipairs({ -0.3, 0.3 }) do
		ball(model, Vector3.new(0.28, 0.34, 0.2), Color3.new(1, 1, 1), Vector3.new(x, 1.55, -0.7))
		ball(model, Vector3.new(0.14, 0.18, 0.1), Color3.fromRGB(10, 10, 20), Vector3.new(x, 1.55, -0.78))
		part(model, { Size = Vector3.new(0.7, 0.2, 0.9), Color = orange, CFrame = CFrame.new(x * 1.2, -1.2, -0.3) })
	end
	local flippers = {}
	for i, side in ipairs({ -1, 1 }) do
		flippers[i] = { part = ball(model, Vector3.new(0.3, 1.5, 0.7), black, Vector3.new(side * 1.05, 0, 0)), side = side }
	end
	return function(t, o)
		for _, f in ipairs(flippers) do
			f.part.CFrame = o * CFrame.new(f.side * 1.05, 0, 0) * CFrame.Angles(0, 0, f.side * (0.2 + 0.15 * math.sin(t * 5)))
		end
	end
end

function builders.bunny(model)
	local white, pink = Color3.fromRGB(252, 246, 240), Color3.fromRGB(255, 180, 195)
	ball(model, Vector3.new(1.7, 1.6, 2.0), white, Vector3.new(0, 0, 0))
	ball(model, Vector3.new(1.4, 1.3, 1.3), white, Vector3.new(0, 0.95, -1.0))
	ball(model, Vector3.new(0.22, 0.2, 0.18), pink, Vector3.new(0, 0.85, -1.62))
	for _, x in ipairs({ -0.35, 0.35 }) do
		ball(model, Vector3.new(0.5, 1.9, 0.35), white, Vector3.new(x, 2.3, -0.9))
		ball(model, Vector3.new(0.26, 1.4, 0.2), pink, Vector3.new(x, 2.3, -1.05))
		ball(model, Vector3.new(0.2, 0.28, 0.15), Color3.fromRGB(40, 30, 50), Vector3.new(x * 0.9, 1.2, -1.58))
		part(model, { Size = Vector3.new(0.5, 0.5, 0.7), Color = white, CFrame = CFrame.new(x, -0.85, -0.5) })
	end
	local tail = ball(model, Vector3.new(0.7, 0.7, 0.7), white, Vector3.new(0, 0.1, 1.15))
	return function(t, o)
		tail.CFrame = o * CFrame.new(0, 0.1 + math.abs(math.sin(t * 6)) * 0.08, 1.15)
	end
end

function builders.frog(model)
	local green, light = Color3.fromRGB(100, 190, 80), Color3.fromRGB(190, 235, 150)
	ball(model, Vector3.new(2.2, 1.5, 2.2), green, Vector3.new(0, 0, 0))
	ball(model, Vector3.new(1.6, 0.8, 1.6), light, Vector3.new(0, -0.35, -0.2))
	for _, x in ipairs({ -0.6, 0.6 }) do
		ball(model, Vector3.new(0.8, 0.8, 0.8), green, Vector3.new(x, 0.95, -0.9))
		ball(model, Vector3.new(0.45, 0.45, 0.3), Color3.new(1, 1, 1), Vector3.new(x, 1.05, -1.2))
		ball(model, Vector3.new(0.22, 0.22, 0.15), Color3.fromRGB(30, 25, 40), Vector3.new(x, 1.05, -1.35))
		part(model, { Size = Vector3.new(0.7, 0.4, 1.2), Color = green, CFrame = CFrame.new(x * 1.7, -0.5, 0.4) })
		part(model, { Size = Vector3.new(0.6, 0.3, 0.7), Color = green, CFrame = CFrame.new(x * 1.2, -0.65, -1.1) })
	end
	part(model, { Size = Vector3.new(0.9, 0.08, 0.1), Color = Color3.fromRGB(60, 90, 50), CFrame = CFrame.new(0, 0.1, -1.55) })
	local body = model:FindFirstChildWhichIsA("BasePart")
	return function(t, o)
		if body then
			body.CFrame = o * CFrame.new(0, math.abs(math.sin(t * 3)) * 0.1, 0)
		end
	end
end

function builders.jelly(model)
	local pink = Color3.fromRGB(255, 150, 200)
	local dome = part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 1.8, 2.2), Color = pink, Material = Enum.Material.Glass, Transparency = 0.2, CFrame = CFrame.new(0, 0.6, 0) })
	local tentacles = {}
	for i = 0, 4 do
		local a = i / 5 * math.pi * 2
		tentacles[i + 1] = { part = part(model, { Size = Vector3.new(0.18, 1.6, 0.18), Color = Color3.fromRGB(255, 190, 220), CFrame = CFrame.new(math.cos(a) * 0.7, -0.7, math.sin(a) * 0.7) }), a = a }
	end
	for _, x in ipairs({ -0.4, 0.4 }) do
		ball(model, Vector3.new(0.28, 0.36, 0.2), Color3.fromRGB(40, 30, 50), Vector3.new(x, 0.65, -1.05))
	end
	return function(t, o)
		local pulse = 1 + 0.08 * math.sin(t * 3)
		dome.Size = Vector3.new(2.2 * pulse, 1.8 / pulse, 2.2 * pulse)
		dome.CFrame = o * CFrame.new(0, 0.6, 0)
		for _, tn in ipairs(tentacles) do
			tn.part.CFrame = o * CFrame.new(math.cos(tn.a) * 0.7, -0.7, math.sin(tn.a) * 0.7) * CFrame.Angles(math.sin(t * 3 + tn.a) * 0.25, 0, math.cos(t * 3 + tn.a) * 0.25)
		end
	end
end

function builders.mushroom(model)
	local cream, red = Color3.fromRGB(250, 235, 205), Color3.fromRGB(220, 50, 55)
	part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.8, 1.2, 1.2), Color = cream, CFrame = CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2) })
	ball(model, Vector3.new(2.8, 1.8, 2.8), red, Vector3.new(0, 1.9, 0))
	for _, d in ipairs({ { -0.8, 2.4, -0.7 }, { 0.7, 2.5, -0.5 }, { 0, 2.65, 0.4 }, { -0.4, 2.3, 0.9 }, { 1.0, 2.2, 0.5 } }) do
		ball(model, Vector3.new(0.5, 0.5, 0.5), Color3.new(1, 1, 1), Vector3.new(d[1], d[2], d[3]))
	end
	for _, x in ipairs({ -0.3, 0.3 }) do
		ball(model, Vector3.new(0.2, 0.28, 0.15), Color3.fromRGB(40, 30, 50), Vector3.new(x, 0.7, -0.58))
	end
	part(model, { Size = Vector3.new(0.4, 0.08, 0.1), Color = Color3.fromRGB(150, 70, 70), CFrame = CFrame.new(0, 0.3, -0.6) })
	return nil
end


-- Returns model, animate (may be nil). The model's PrimaryPart is set to
-- a hidden anchor at its centre so it can be moved with PivotTo.
-- Variants recolor another pet's model: the hue is shifted, and minSat
-- lifts grey parts into color (dark features like eyes are left alone).
local function recolor(color, info)
	local h, sat, v = color:ToHSV()
	if info.minSat and v < 0.2 then
		return color -- keep dark features (eyes, nose) as they are
	end
	if sat < 0.35 then
		h = info.hue or h -- greys and whites take the new color outright
	else
		h = (h + (info.shift or info.hue or 0)) % 1 -- colored parts shift around the wheel
	end
	sat = math.max(sat * (info.satMul or 1), info.minSat or 0)
	v = math.clamp(v * (info.valMul or 1), 0, 1)
	return Color3.fromHSV(h, math.min(sat, 1), v)
end

-- Small extras stuck on top of whatever the model's highest part is.
local function addAccessory(model, kind, root)
	local top, topY = nil, -math.huge
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root and d.Transparency < 0.9 then
			local y = d.CFrame.Position.Y + d.Size.Y / 2
			if y > topY then
				top, topY = d, y
			end
		end
	end
	if not top then
		return
	end
	local cx, cz = top.CFrame.Position.X, top.CFrame.Position.Z
	local gold = Color3.fromRGB(255, 205, 60)
	if kind == "crown" then
		part(model, { Size = Vector3.new(1.0, 0.35, 1.0), Color = gold, Material = Enum.Material.Metal, CFrame = CFrame.new(cx, topY + 0.15, cz) })
		for _, dx in ipairs({ -0.4, 0, 0.4 }) do
			part(model, { Size = Vector3.new(0.22, 0.4, 0.22), Color = gold, Material = Enum.Material.Metal, CFrame = CFrame.new(cx + dx, topY + 0.5, cz) })
		end
		part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.25, 0.25, 0.25), Color = Color3.fromRGB(255, 80, 100), Material = Enum.Material.Neon, CFrame = CFrame.new(cx, topY + 0.2, cz - 0.52) })
	elseif kind == "tophat" then
		part(model, { Size = Vector3.new(1.3, 0.12, 1.3), Color = Color3.fromRGB(35, 30, 45), CFrame = CFrame.new(cx, topY + 0.05, cz) })
		part(model, { Size = Vector3.new(0.85, 0.9, 0.85), Color = Color3.fromRGB(35, 30, 45), CFrame = CFrame.new(cx, topY + 0.55, cz) })
		part(model, { Size = Vector3.new(0.87, 0.2, 0.87), Color = Color3.fromRGB(200, 50, 70), CFrame = CFrame.new(cx, topY + 0.3, cz) })
	elseif kind == "partyhat" then
		for i = 0, 3 do
			part(model, { Size = Vector3.new(0.9 - i * 0.22, 0.28, 0.9 - i * 0.22), Color = i % 2 == 0 and Color3.fromRGB(255, 90, 160) or Color3.fromRGB(90, 200, 255), CFrame = CFrame.new(cx, topY + 0.14 + i * 0.28, cz) })
		end
		part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.25, 0.25, 0.25), Color = gold, Material = Enum.Material.Neon, CFrame = CFrame.new(cx, topY + 1.3, cz) })
	elseif kind == "halo" then
		part(model, { Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, 1.3, 1.3), Color = gold, Material = Enum.Material.Neon, CFrame = CFrame.new(cx, topY + 0.55, cz) * CFrame.Angles(0, 0, math.pi / 2) })
	elseif kind == "bow" then
		local pink = Color3.fromRGB(255, 100, 160)
		part(model, { Size = Vector3.new(0.5, 0.4, 0.2), Color = pink, CFrame = CFrame.new(cx - 0.3, topY + 0.15, cz) * CFrame.Angles(0, 0, 0.5) })
		part(model, { Size = Vector3.new(0.5, 0.4, 0.2), Color = pink, CFrame = CFrame.new(cx + 0.3, topY + 0.15, cz) * CFrame.Angles(0, 0, -0.5) })
		part(model, { Shape = Enum.PartType.Ball, Size = Vector3.new(0.28, 0.28, 0.28), Color = Color3.fromRGB(255, 60, 120), CFrame = CFrame.new(cx, topY + 0.15, cz) })
	end
end

function Pets.build(id)
	local info = Pets.get(id)
	local variant = info and info.variantOf
	local builder = builders[variant or id]
	if not builder then
		return nil, nil
	end
	local model = Instance.new("Model")
	model.Name = "Pet_" .. id
	local animate = builder(model)
	local root = part(model, {
		Name = "PetRoot",
		Size = Vector3.new(0.2, 0.2, 0.2),
		Transparency = 1,
		CFrame = CFrame.new(0, 0, 0),
	})
	model.PrimaryPart = root
	if variant then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d ~= root then
				d.Color = recolor(d.Color, info)
				if info.neon and d.Transparency == 0 then
					local _, _, v = d.Color:ToHSV()
					if v >= 0.2 then
						d.Material = Enum.Material.Neon
					end
				end
			end
		end
	end
	if info and info.accessory then
		addAccessory(model, info.accessory, root)
	end

	-- Mythic rainbow pets cycle the color of every bright part.
	local rainbowParts = {}
	if info and info.rainbow then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d ~= root and d.Transparency < 0.5 then
				local _, _, v = d.Color:ToHSV()
				if v >= 0.2 then
					table.insert(rainbowParts, d)
				end
			end
		end
	end

	if not animate and #rainbowParts == 0 then
		return model, nil
	end
	return model, function(t)
		if animate then
			animate(t, root.CFrame)
		end
		for i, d in ipairs(rainbowParts) do
			d.Color = Color3.fromHSV((t * 0.25 + i * 0.045) % 1, 0.7, 1)
		end
	end
end

return Pets
