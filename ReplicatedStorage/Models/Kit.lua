--[[
	Kit.lua
	ModuleScript: ReplicatedStorage.Models.Kit

	Shared Part-building helpers for ObjectModels and the category model
	modules next to this one. Builders work in their own units with the
	ground at y = 0, centered on x = 0, and the "front" facing -Z (toward
	the camera).
]]

local Kit = {}

local SMOOTH = Enum.Material.SmoothPlastic

local function add(model, p, color, material)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color
	p.Material = material or SMOOTH
	p.Parent = model
	return p
end

Kit.add = add

local function toCFrame(pos)
	return typeof(pos) == "CFrame" and pos or CFrame.new(pos)
end

function Kit.box(model, size, pos, color, material)
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = toCFrame(pos)
	return add(model, p, color, material)
end

function Kit.ball(model, diameter, pos, color, material)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(diameter, diameter, diameter)
	p.CFrame = CFrame.new(pos)
	return add(model, p, color, material)
end

-- Cylinder whose axis follows the given CFrame's X axis.
function Kit.cylinder(model, length, radius, cf, color, material)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(length, radius * 2, radius * 2)
	p.CFrame = cf
	return add(model, p, color, material)
end

function Kit.vcyl(model, height, radius, pos, color, material)
	return Kit.cylinder(model, height, radius, CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), color, material)
end

function Kit.zcyl(model, length, radius, pos, color, material)
	return Kit.cylinder(model, length, radius, CFrame.new(pos) * CFrame.Angles(0, math.pi / 2, 0), color, material)
end

function Kit.xcyl(model, length, radius, pos, color, material)
	return Kit.cylinder(model, length, radius, CFrame.new(pos), color, material)
end

-- CFrame.lookAt with the default up vector yields NaN for vertical
-- directions, so those use X as "up" instead.
local function lookAlong(from, to)
	local delta = to - from
	local up = math.abs(delta.Unit.Y) > 0.99 and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0)
	return CFrame.lookAt((from + to) / 2, to, up), delta.Magnitude
end

-- Square beam from one point to another.
function Kit.beam(model, from, to, thickness, color, material)
	local cf, length = lookAlong(from, to)
	return Kit.box(model, Vector3.new(thickness, thickness, length), cf, color, material)
end

-- Flat slab from one point to another: `width` across, `thickness` deep.
function Kit.slab(model, from, to, width, thickness, color, material)
	local cf, length = lookAlong(from, to)
	return Kit.box(model, Vector3.new(width, thickness, length), cf, color, material)
end

-- Round rod from one point to another.
function Kit.rod(model, from, to, radius, color, material)
	local cf, length = lookAlong(from, to)
	return Kit.cylinder(model, length, radius, cf * CFrame.Angles(0, math.pi / 2, 0), color, material)
end

-- Rod that narrows from r0 to r1 in `steps` pieces (horns, carrots, tails).
function Kit.taper(model, from, to, r0, r1, steps, color, material)
	steps = steps or 4
	for i = 0, steps - 1 do
		local a = from:Lerp(to, i / steps)
		local b = from:Lerp(to, (i + 1) / steps)
		Kit.rod(model, a, b, r0 + (r1 - r0) * (i + 0.5) / steps, color, material)
	end
end

-- Stepped cone standing on `base`, narrowing from r0 to r1.
function Kit.cone(model, height, r0, r1, base, color, material, steps)
	steps = steps or 5
	local h = height / steps
	for i = 0, steps - 1 do
		local r = r0 + (r1 - r0) * i / math.max(steps - 1, 1)
		Kit.vcyl(model, h, math.max(r, 0.02), base + Vector3.new(0, h * (i + 0.5), 0), color, material)
	end
end

-- Stepped square pyramid/spire standing on `base`.
function Kit.spire(model, height, w0, w1, base, color, material, steps)
	steps = steps or 5
	local h = height / steps
	for i = 0, steps - 1 do
		local w = w0 + (w1 - w0) * i / math.max(steps - 1, 1)
		Kit.box(model, Vector3.new(math.max(w, 0.04), h, math.max(w, 0.04)), base + Vector3.new(0, h * (i + 0.5), 0), color, material)
	end
end

-- Dome of stacked discs on `base` (half-sphere silhouette).
function Kit.dome(model, radius, base, color, material, steps)
	steps = steps or 4
	local h = radius / steps
	for i = 0, steps - 1 do
		local y = h * (i + 0.5)
		local r = math.sqrt(math.max(radius * radius - y * y, 0.0004))
		Kit.vcyl(model, h, r, base + Vector3.new(0, y, 0), color, material)
	end
end

function Kit.wedge(model, size, cf, color, material)
	local p = Instance.new("WedgePart")
	p.Size = size
	p.CFrame = cf
	return add(model, p, color, material)
end

-- Triangular peak in the X/Y plane (faces the camera), extruded along Z.
-- Wedges rise toward their local +Z, so each half is turned to rise
-- toward the center line.
function Kit.peak(model, centerX, baseY, centerZ, halfWidth, height, depth, color, material)
	local size = Vector3.new(depth, height, halfWidth)
	local y = baseY + height / 2
	Kit.wedge(model, size, CFrame.new(centerX - halfWidth / 2, y, centerZ) * CFrame.Angles(0, math.pi / 2, 0), color, material)
	Kit.wedge(model, size, CFrame.new(centerX + halfWidth / 2, y, centerZ) * CFrame.Angles(0, -math.pi / 2, 0), color, material)
end

-- Ring of boxes around `center` in the X/Y plane (faces the camera).
function Kit.ring(model, center, radius, thickness, depth, segments, color, material)
	for i = 0, segments - 1 do
		local a = 2 * math.pi * i / segments
		local chord = 2 * radius * math.sin(math.pi / segments) + thickness * 0.5
		Kit.box(
			model,
			Vector3.new(chord, thickness, depth),
			CFrame.new(center + Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)) * CFrame.Angles(0, 0, a + math.pi / 2),
			color,
			material
		)
	end
end

-- Wheel facing the camera: tire plus hub.
function Kit.wheel(model, pos, radius, width, tireColor, hubColor)
	Kit.zcyl(model, width, radius, pos, tireColor or Color3.fromRGB(30, 30, 35))
	Kit.zcyl(model, width + 0.06, radius * 0.5, pos, hubColor or Color3.fromRGB(190, 190, 200))
end

-- Grid of window panes on the -Z face at depth z.
function Kit.windows(model, x0, x1, y0, y1, z, cols, rows, color, fill)
	fill = fill or 0.6
	local cw, rh = (x1 - x0) / cols, (y1 - y0) / rows
	for i = 0, cols - 1 do
		for j = 0, rows - 1 do
			Kit.box(
				model,
				Vector3.new(cw * fill, rh * fill, 0.1),
				Vector3.new(x0 + cw * (i + 0.5), y0 + rh * (j + 0.5), z),
				color
			)
		end
	end
end

-- Point on a sphere; lon = 0 faces the camera (-Z).
function Kit.onSphere(center, radius, latDeg, lonDeg)
	local lat, lon = math.rad(latDeg), math.rad(lonDeg)
	return center + Vector3.new(radius * math.cos(lat) * math.sin(lon), radius * math.sin(lat), -radius * math.cos(lat) * math.cos(lon))
end

function Kit.rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Kit.BLACK = Kit.rgb(25, 25, 30)
Kit.WHITE = Kit.rgb(245, 245, 245)
Kit.NEON = Enum.Material.Neon

-- Four-legged body with legs, head, ears and tail. Options:
-- len, bodyH, legH, width, color, belly, headLen, headH, neck (rise of the
-- head above the back), ear = {w, h}, tail (length), snout (color),
-- horns (color), mane (color), hump (height), stripes (color).
function Kit.quad(m, o)
	local len, bh, lh, w = o.len, o.bodyH, o.legH, o.width
	local lw = o.legW or w * 0.3
	local color = o.color
	for _, x in ipairs({ -len / 2 + lw * 0.7, len / 2 - lw * 0.7 }) do
		for _, z in ipairs({ -w / 2 + lw / 2, w / 2 - lw / 2 }) do
			Kit.box(m, Vector3.new(lw, lh, lw), Vector3.new(x, lh / 2, z), o.legColor or color)
		end
	end
	Kit.box(m, Vector3.new(len, bh, w), Vector3.new(0, lh + bh / 2, 0), color)
	if o.belly then
		Kit.box(m, Vector3.new(len * 0.8, bh * 0.35, w * 1.02), Vector3.new(0, lh + bh * 0.2, 0), o.belly)
	end
	if o.stripes then
		for i = -2, 2 do
			Kit.box(m, Vector3.new(len * 0.07, bh * 1.02, w * 1.02), Vector3.new(i * len * 0.17, lh + bh / 2, 0), o.stripes)
		end
	end
	if o.hump then
		Kit.box(m, Vector3.new(len * 0.28, o.hump, w * 0.8), Vector3.new(len * 0.05, lh + bh + o.hump / 2, 0), color)
	end
	local hl, hh = o.headLen, o.headH
	local neck = o.neck or 0
	local hx = -len / 2 - hl * 0.35
	local hy = lh + bh + neck - hh * 0.1
	if neck > 0 then
		Kit.beam(m, Vector3.new(-len / 2 + len * 0.1, lh + bh * 0.8, 0), Vector3.new(hx + hl * 0.3, hy, 0), w * 0.55, color)
	end
	Kit.box(m, Vector3.new(hl, hh, w * 0.75), Vector3.new(hx, hy, 0), color)
	if o.snout then
		Kit.box(m, Vector3.new(hl * 0.35, hh * 0.55, w * 0.6), Vector3.new(hx - hl * 0.45, hy - hh * 0.2, 0), o.snout)
		Kit.box(m, Vector3.new(hl * 0.08, hh * 0.15, w * 0.3), Vector3.new(hx - hl * 0.66, hy - hh * 0.1, 0), Kit.BLACK)
	end
	if o.mane then
		Kit.box(m, Vector3.new(hl * 0.8, hh * 1.25, w * 0.95), Vector3.new(hx + hl * 0.55, hy, 0), o.mane)
	end
	local ear = o.ear or { w * 0.18, hh * 0.45 }
	for _, z in ipairs({ -w * 0.22, w * 0.22 }) do
		Kit.box(m, Vector3.new(ear[1], ear[2], ear[1]), Vector3.new(hx + hl * 0.2, hy + hh / 2 + ear[2] / 2, z), o.earColor or color)
		if o.horns then
			Kit.beam(m, Vector3.new(hx + hl * 0.1, hy + hh / 2, z * 1.2), Vector3.new(hx - hl * 0.1, hy + hh / 2 + ear[2] * 1.6, z * 1.8), w * 0.08, o.horns)
		end
	end
	Kit.box(m, Vector3.new(hl * 0.12, hh * 0.18, 0.05 * w), Vector3.new(hx - hl * 0.25, hy + hh * 0.18, -w * 0.38), Kit.BLACK)
	local tl = o.tail or len * 0.25
	Kit.beam(m, Vector3.new(len / 2, lh + bh * 0.85, 0), Vector3.new(len / 2 + tl * 0.7, lh + bh * 0.85 - tl * 0.5, 0), w * 0.12, o.tailColor or color)
	return lh + bh -- shoulder height
end

-- Torpedo-shaped swimmer facing -X with fins.
function Kit.swimmer(m, len, thick, color, belly, finH)
	local y = thick * 0.8
	Kit.box(m, Vector3.new(len * 0.5, thick, thick * 0.9), Vector3.new(0, y, 0), color)
	Kit.box(m, Vector3.new(len * 0.25, thick * 0.8, thick * 0.8), Vector3.new(-len * 0.34, y - thick * 0.05, 0), color)
	Kit.box(m, Vector3.new(len * 0.18, thick * 0.55, thick * 0.55), Vector3.new(-len * 0.5, y - thick * 0.1, 0), color)
	Kit.box(m, Vector3.new(len * 0.3, thick * 0.65, thick * 0.7), Vector3.new(len * 0.38, y + thick * 0.05, 0), color)
	Kit.box(m, Vector3.new(len * 0.5, thick * 0.45, thick * 0.92), Vector3.new(-len * 0.02, y - thick * 0.3, 0), belly)
	Kit.wedge(m, Vector3.new(thick * 0.1, finH, len * 0.16), CFrame.new(-len * 0.02, y + thick / 2 + finH / 2, 0) * CFrame.Angles(0, math.pi / 2, 0), color)
	Kit.box(m, Vector3.new(len * 0.1, thick * 0.12, thick * 1.1), Vector3.new(len * 0.5, y + thick * 0.15, 0), color)
	Kit.box(m, Vector3.new(len * 0.14, thick * 0.1, thick * 1.3), Vector3.new(-len * 0.18, y - thick * 0.45, 0), color)
	Kit.box(m, Vector3.new(thick * 0.08, thick * 0.08, 0.1), Vector3.new(-len * 0.4, y + thick * 0.15, -thick * 0.4), Kit.BLACK)
end

return Kit
