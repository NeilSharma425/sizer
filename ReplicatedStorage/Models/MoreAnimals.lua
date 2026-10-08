--[[
	MoreAnimals.lua
	ModuleScript: ReplicatedStorage.Models.MoreAnimals

	100 more animal models for ObjectModels, built from a few body-shape
	helpers (four-legged, bird, flyer, swimmer, seal, snake, lizard,
	turtle, insect, many-legged, critter). Side-on views facing -X, like
	ExtraAnimals; flyers and rays are seen from above with wings spread
	across the screen. Every builder returns `measure`: the model-unit
	length that matches the size listed for it in ExtraObjects (shoulder
	height, standing height, length or wingspan, as its fact says).

	Usage: require(MoreAnimals)(builders)
]]

local Kit = require(script.Parent:WaitForChild("Kit"))
local box, ball, beam, rod, slab, taper = Kit.box, Kit.ball, Kit.beam, Kit.rod, Kit.slab, Kit.taper
local quad, swimmer = Kit.quad, Kit.swimmer
local rgb, BLACK, WHITE = Kit.rgb, Kit.BLACK, Kit.WHITE
local V = Vector3.new

-- Squashed sphere (Part + SpecialMesh).
local function ell(m, size, pos, color, material)
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = typeof(pos) == "CFrame" and pos or CFrame.new(pos)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return Kit.add(m, p, color, material)
end

-- Eyes on both sides of a head centred at `pos`, `r` = head radius.
local function eyes(m, pos, r, size, color)
	for _, s in ipairs({ -1, 1 }) do
		ball(m, size or r * 0.35, pos + V(-r * 0.45, r * 0.2, s * r * 0.75), color or BLACK)
	end
end

-- Spots scattered over a quad body (deterministic).
local function spots(m, o, color, count)
	local lh, bh, len, w = o.legH, o.bodyH, o.len, o.width
	for i = 1, count or 10 do
		local x = (((i * 37) % 100) / 100 - 0.5) * len * 0.85
		local y = lh + bh * (0.25 + ((i * 53) % 100) / 100 * 0.65)
		local s = math.min(len, bh) * 0.12
		box(m, V(s, s, w * 1.02), V(x, y, 0), color)
	end
end

-- Antlers rising from the top of a quad's head.
local function antlers(m, x, y, w, size, color)
	for _, z in ipairs({ -w * 0.25, w * 0.25 }) do
		local top = V(x + size * 0.3, y + size, z * 2.2)
		beam(m, V(x, y, z), top, size * 0.08, color)
		beam(m, V(x + size * 0.1, y + size * 0.5, z * 1.6), V(x - size * 0.35, y + size * 0.85, z * 2), size * 0.06, color)
		beam(m, top, top + V(size * 0.35, size * 0.25, 0), size * 0.06, color)
		beam(m, top, top + V(-size * 0.25, size * 0.35, 0), size * 0.06, color)
	end
end

-- Head position of a quad (matches Kit.quad).
local function quadHead(o)
	local hx = -o.len / 2 - o.headLen * 0.35
	local hy = o.legH + o.bodyH + (o.neck or 0) - o.headH * 0.1
	return hx, hy
end

-- Bird standing on two legs, body tilted `tilt` degrees nose-up. Options:
-- legH, body = {l, h, w}, color, wing, belly, neck, head (size), beak =
-- {len, color, drop, thick}, tail = {len, angle, width}, legColor, crest,
-- measure ("height" or "length"). Returns the measured size.
local function bird(m, o)
	local bl, bh, bw = o.body[1], o.body[2], o.body[3]
	local t = math.rad(o.tilt or 15)
	local legH = o.legH
	local c = V(0, legH + bh * 0.4, 0)
	local front = c + V(-bl / 2 * math.cos(t), bl / 2 * math.sin(t), 0)
	local back = c + V(bl / 2 * math.cos(t), -bl / 2 * math.sin(t), 0)
	for _, z in ipairs({ -bw * 0.2, bw * 0.2 }) do
		rod(m, V(0, 0.05, z), V(0, legH + bh * 0.1, z), math.max(bw * 0.05, 0.03), o.legColor or rgb(230, 170, 70))
		box(m, V(bl * 0.25, bw * 0.05 + 0.02, bw * 0.12), V(-bl * 0.08, 0.03, z), o.legColor or rgb(230, 170, 70))
	end
	ell(m, V(bl, bh, bw), CFrame.new(c) * CFrame.Angles(0, 0, -t), o.color)
	if o.belly then
		ell(m, V(bl * 0.75, bh * 0.6, bw * 0.92), CFrame.new(c + V(-bl * 0.05, -bh * 0.18, 0)) * CFrame.Angles(0, 0, -t), o.belly)
	end
	for _, s in ipairs({ -1, 1 }) do
		ell(m, V(bl * 0.75, bh * 0.6, bw * 0.15), CFrame.new(c + V(bl * 0.08, bh * 0.05, s * bw * 0.45)) * CFrame.Angles(0, 0, -t - 0.08), o.wing or o.color)
	end
	local hs = o.head
	local neck = o.neck or 0
	local headPos = front + V(-hs * 0.2 - neck * 0.15, neck + hs * 0.2, 0)
	if neck > 0 then
		beam(m, front + V(bl * 0.1, 0, 0), headPos, hs * 0.45, o.neckColor or o.color)
	end
	ball(m, hs, headPos, o.headColor or o.color)
	eyes(m, headPos, hs / 2, hs * 0.2)
	local beakLen = o.beak[1]
	local tip = headPos + V(-hs * 0.4 - beakLen, -(o.beak[3] or 0), 0)
	beam(m, headPos + V(-hs * 0.3, -hs * 0.05, 0), tip, o.beak[4] or hs * 0.3, o.beak[2])
	if o.crest then
		beam(m, headPos + V(0, hs * 0.4, 0), headPos + V(hs * 0.5, hs * 1.0, 0), hs * 0.2, o.crest)
	end
	local tl = o.tail[1]
	local ta = math.rad(o.tail[2] or 0)
	local tailEnd = back + V(tl * math.cos(ta), tl * math.sin(ta), 0)
	slab(m, back - V(bl * 0.1, 0, 0), tailEnd, o.tail[3] or bw * 0.6, bh * 0.15, o.tailColor or o.wing or o.color)
	if o.measure == "length" then
		return math.max(tailEnd.X, back.X) - math.min(tip.X, headPos.X - hs / 2)
	elseif o.measure == "long" then
		return (headPos + V(0, hs / 2, 0) - tailEnd).Magnitude
	end
	return math.max(headPos.Y + hs / 2, tailEnd.Y)
end

-- Flying animal seen from above: body up the screen, wings spread across
-- it. Options: span, bodyL, bodyW, color, wing, tip, chord, tipChord,
-- sweep, head, beak = {len, color}, tail = {len, width}. Returns span.
local function flyer(m, o)
	local base = o.tail and o.tail[1] or 0
	local c = V(0, base + o.bodyL / 2, 0)
	ell(m, V(o.bodyW, o.bodyL, o.bodyW * 0.8), c, o.color)
	local headY = c.Y + o.bodyL / 2 + o.head * 0.3
	ball(m, o.head, V(0, headY, 0), o.headColor or o.color)
	for _, s in ipairs({ -1, 1 }) do
		ball(m, o.head * 0.22, V(s * o.head * 0.25, headY + o.head * 0.1, -o.head * 0.4), BLACK)
	end
	if o.beak then
		beam(m, V(0, headY + o.head * 0.3, 0), V(0, headY + o.head * 0.3 + o.beak[1], 0), o.head * 0.3, o.beak[2])
	end
	local rootY = c.Y + o.bodyL * 0.15
	local sweep = o.sweep or 0
	for _, s in ipairs({ -1, 1 }) do
		local root = V(s * o.bodyW * 0.3, rootY, 0.05)
		local mid = V(s * o.span * 0.25, rootY + sweep * 0.5, 0.05)
		local tip = V(s * o.span / 2, rootY + sweep, 0.05)
		slab(m, root, mid, 0.12, o.chord, o.wing or o.color)
		slab(m, mid, tip - V(s * o.tipChord * 0.3, 0, 0), 0.1, o.tipChord, o.tip or o.wing or o.color)
	end
	if o.tail then
		slab(m, V(0, c.Y - o.bodyL / 2 + 0.05, 0.05), V(0, 0, 0.05), 0.1, o.tail[2], o.tailColor or o.wing or o.color)
	end
	return o.span
end

-- Seal-like body lying on the ground. Options: len, thick, color, belly,
-- raise (lift of the head end), head (size), flipper colour. Returns length.
local function seal(m, o)
	local len, th, raise = o.len, o.thick, o.raise or 0
	ell(m, V(len * 0.6, th, th * 0.95), V(len * 0.05, th / 2, 0), o.color)
	ell(m, V(len * 0.38, th * 0.95, th * 0.9), CFrame.new(-len * 0.22, th / 2 + raise * 0.4, 0) * CFrame.Angles(0, 0, -math.atan(raise / (len * 0.4))), o.color)
	ell(m, V(len * 0.35, th * 0.6, th * 0.6), V(len * 0.32, th * 0.32, 0), o.color)
	if o.belly then
		ell(m, V(len * 0.5, th * 0.4, th * 0.9), V(-len * 0.05, th * 0.22, 0), o.belly)
	end
	local hs = o.head or th * 0.7
	local head = V(-len * 0.5 + hs / 2, th * 0.6 + raise, 0)
	ball(m, hs, head, o.headColor or o.color)
	eyes(m, head, hs / 2, hs * 0.16)
	ball(m, hs * 0.25, head + V(-hs * 0.48, -hs * 0.05, 0), BLACK)
	for _, s in ipairs({ -1, 1 }) do
		slab(m, V(-len * 0.2, th * 0.25, s * th * 0.45), V(-len * 0.08, 0.05, s * th * 0.75), th * 0.35, th * 0.08, o.flipper or o.color)
	end
	local tailEnd = V(len * 0.5, th * 0.15, 0)
	if o.fluke then
		ell(m, V(len * 0.18, th * 0.12, th * 1.1), tailEnd, o.flipper or o.color)
	else
		for _, s in ipairs({ -1, 1 }) do
			slab(m, V(len * 0.4, th * 0.2, s * th * 0.15), tailEnd + V(0, 0, s * th * 0.4), th * 0.4, th * 0.08, o.flipper or o.color)
		end
	end
	return tailEnd.X + (o.fluke and len * 0.09 or 0) - (head.X - hs / 2)
end

-- Snake with a gentle side-to-side curve. Options: len, thick, color,
-- pattern (colour of bands), head colour, rise (head lift), hood, rattle.
-- Returns its body length.
local function snake(m, o)
	local n = 14
	local seg = o.len / n
	local pts = {}
	local x = o.len * 0.45
	for i = 0, n do
		local f = i / n
		local lift = 0
		if o.rise and f > 0.7 then
			lift = o.rise * ((f - 0.7) / 0.3) ^ 2
		end
		pts[i] = V(x - i * seg * 0.97, o.thick / 2 + lift, math.sin(f * math.pi * 3) * o.len * 0.05)
	end
	local total = 0
	for i = 0, n - 1 do
		local a, b = pts[i], pts[i + 1]
		total += (b - a).Magnitude
		local r = o.thick * (0.45 + 0.55 * math.min(1, i / (n * 0.35)))
		rod(m, a, b, r / 2, (o.pattern and i % 3 == 0) and o.pattern or o.color)
		ball(m, r, b, (o.pattern and i % 3 == 0) and o.pattern or o.color)
	end
	local head = pts[n] + V(-o.thick * 0.5, 0, 0)
	ell(m, V(o.thick * 1.6, o.thick * 0.8, o.thick * 1.1), head, o.headColor or o.color)
	eyes(m, head, o.thick * 0.55, o.thick * 0.22)
	if o.hood then
		ell(m, V(o.thick * 0.5, o.thick * 3, o.thick * 2.4), pts[n - 1] + V(0, -o.thick * 0.6, 0), o.hood)
	end
	if o.rattle then
		for i = 1, 3 do
			ball(m, o.thick * 0.6, pts[0] + V(o.thick * 0.4 * i, o.thick * 0.1 * i, 0), o.rattle)
		end
	end
	return total + o.thick
end

-- Lizard/crocodile shape: low body, splayed legs, long tapering tail.
-- Options: len (body), h, legH, w, tail, head = {l, h}, color, belly,
-- spikes (colour of a back crest). Returns nose-to-tail length.
local function lizard(m, o)
	local y = o.legH + o.h / 2
	ell(m, V(o.len, o.h, o.w), V(0, y, 0), o.color)
	if o.belly then
		ell(m, V(o.len * 0.85, o.h * 0.5, o.w * 0.9), V(0, y - o.h * 0.22, 0), o.belly)
	end
	for _, x in ipairs({ -o.len * 0.32, o.len * 0.32 }) do
		for _, s in ipairs({ -1, 1 }) do
			local hip = V(x, y - o.h * 0.1, s * o.w * 0.4)
			local knee = V(x, y, s * (o.w * 0.4 + o.legH * 0.8))
			rod(m, hip, knee, o.w * 0.09, o.legColor or o.color)
			rod(m, knee, V(x - o.legH * 0.2, 0.05, s * (o.w * 0.4 + o.legH)), o.w * 0.08, o.legColor or o.color)
		end
	end
	local hl, hh = o.head[1], o.head[2]
	local head = V(-o.len / 2 - hl * 0.4, y + hh * 0.1, 0)
	ell(m, V(hl, hh, o.w * 0.7), head, o.headColor or o.color)
	eyes(m, head + V(hl * 0.15, hh * 0.1, 0), hh * 0.5, hh * 0.22, o.eye)
	local tailEnd = V(o.len / 2 + o.tail, 0.08, 0)
	taper(m, V(o.len * 0.4, y, 0), tailEnd, o.h * 0.4, o.h * 0.06, 5, o.tailColor or o.color)
	if o.spikes then
		for i = 0, 7 do
			local px = -o.len * 0.4 + i * o.len * 0.12
			box(m, V(o.h * 0.15, o.h * 0.3, o.h * 0.15), V(px, y + o.h * 0.5, 0), o.spikes)
		end
	end
	return tailEnd.X - (head.X - hl / 2)
end

-- Turtle: domed shell, four flippers or legs, head. Returns shell length.
local function turtle(m, o)
	local r = o.r
	local base = o.legH or r * 0.25
	Kit.dome(m, r, V(0, base, 0), o.shell, nil, 4)
	box(m, V(r * 2, r * 0.18, r * 1.7), V(0, base, 0), o.under or o.skin)
	for _, x in ipairs({ -r * 0.6, r * 0.6 }) do
		for _, s in ipairs({ -1, 1 }) do
			if o.flippers then
				slab(m, V(x, base, s * r * 0.6), V(x - r * 0.3, base * 0.5, s * r * 1.3), r * 0.35, r * 0.08, o.skin)
			else
				box(m, V(r * 0.35, base + 0.05, r * 0.35), V(x, base / 2, s * r * 0.6), o.skin)
			end
		end
	end
	local head = V(-r - r * 0.25, base + r * 0.15, 0)
	beam(m, V(-r * 0.7, base, 0), head, r * 0.3, o.skin)
	ball(m, r * 0.42, head, o.skin)
	eyes(m, head, r * 0.21, r * 0.09)
	if o.pattern then
		for i = -1, 1 do
			box(m, V(r * 0.4, r * 0.08, r * 0.4), V(i * r * 0.5, base + r * 0.95 - math.abs(i) * r * 0.25, 0), o.pattern)
		end
	end
	return r * 2
end

-- Insect: head, thorax and abdomen in a row, six legs, antennae and
-- optional raised wings. Options: len, h, color, abdomen colour, head
-- colour, legColor, wings colour, wingLen, stripes (abdomen bands),
-- antenna length. Returns length (head to abdomen tip).
local function insect(m, o)
	local len, h = o.len, o.h
	local legH = o.legH or h * 0.6
	local y = legH + h / 2
	local hs = len * (o.headFrac or 0.2)
	local tl = len * (o.thoraxFrac or 0.3)
	local al = len - hs - tl
	local hx = -len / 2 + hs / 2
	local tx = hx + hs / 2 + tl / 2
	local ax = tx + tl / 2 + al / 2
	ell(m, V(hs, hs * 0.9, hs * 0.9), V(hx, y + h * 0.05, 0), o.headColor or o.color)
	ell(m, V(tl, h * 0.8, h * 0.8), V(tx, y, 0), o.color)
	ell(m, V(al, h, h * 0.95), CFrame.new(ax, y + (o.abdomenLift or 0), 0), o.abdomen or o.color)
	if o.stripes then
		for i = -1, 1 do
			ell(m, V(al * 0.12, h * 1.02, h * 0.97), V(ax + i * al * 0.25, y + (o.abdomenLift or 0), 0), o.stripes)
		end
	end
	eyes(m, V(hx, y + h * 0.05, 0), hs / 2, hs * 0.35, o.eyeColor)
	for i = -1, 1 do
		for _, s in ipairs({ -1, 1 }) do
			local hip = V(tx + i * tl * 0.3, y - h * 0.2, s * h * 0.35)
			local knee = V(tx + i * tl * 0.6, y + h * 0.1, s * (h * 0.35 + legH * 0.8))
			rod(m, hip, knee, h * 0.05, o.legColor or BLACK)
			rod(m, knee, V(tx + i * tl * 0.9, 0.02, s * (h * 0.35 + legH)), h * 0.045, o.legColor or BLACK)
		end
	end
	local ant = o.antenna or len * 0.3
	for _, s in ipairs({ -1, 1 }) do
		rod(m, V(hx - hs * 0.2, y + hs * 0.35, s * hs * 0.2), V(hx - ant * 0.6, y + hs * 0.35 + ant * 0.8, s * hs * 0.5), h * 0.03, o.legColor or BLACK)
	end
	if o.wings then
		local wl = o.wingLen or len * 0.6
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(wl, wl * 0.35, 0.05), CFrame.new(tx + wl * 0.35, y + h * 0.5 + wl * 0.15, s * h * 0.25) * CFrame.Angles(0, 0, -0.35), o.wings, o.wingMaterial)
		end
	end
	return len
end

-- Many-legged animal (spider, crab): round body and `pairs` pairs of
-- jointed legs reaching out front and back. Returns leg span (along X).
local function legs(m, o)
	local y = o.legH + o.h / 2
	ell(m, V(o.body, o.h, o.body * 0.9), V(0, y, 0), o.color)
	if o.abdomen then
		ell(m, V(o.abdomen[1], o.abdomen[2], o.abdomen[1] * 0.9), V(o.body * 0.5 + o.abdomen[1] * 0.4, y + o.abdomen[2] * 0.1, 0), o.abdomenColor or o.color)
	end
	local minX, maxX = 0, 0
	local count = o.pairs or 4
	for i = 1, count do
		local a = math.rad(-70 + (i - 1) * 140 / math.max(count - 1, 1))
		for _, s in ipairs({ -1, 1 }) do
			local dir = V(math.sin(a), 0, s * math.cos(a))
			local hip = V(0, y, 0) + dir * o.body * 0.4
			local knee = V(0, y + o.legH * 0.7, 0) + dir * (o.body * 0.4 + o.reach * 0.45)
			local foot = V(0, 0.03, 0) + dir * (o.body * 0.4 + o.reach)
			rod(m, hip, knee, o.legT, o.legColor or o.color)
			rod(m, knee, foot, o.legT * 0.85, o.legColor or o.color)
			minX, maxX = math.min(minX, foot.X), math.max(maxX, foot.X)
		end
	end
	eyes(m, V(-o.body * 0.35, y + o.h * 0.15, 0), o.body * 0.18, o.body * 0.1, o.eyeColor)
	return maxX - minX
end

-- Small round animal (rodents, hedgehog). Options: len, h, color, belly,
-- head, ear = {w, h}, earColor, tail = {len, angle}, nose colour. Returns
-- body length.
local function critter(m, o)
	local legH = o.legH or o.h * 0.15
	local y = legH + o.h / 2
	for _, x in ipairs({ -o.len * 0.25, o.len * 0.25 }) do
		for _, s in ipairs({ -1, 1 }) do
			box(m, V(o.h * 0.18, legH + 0.05, o.h * 0.18), V(x, legH / 2, s * o.h * 0.3), o.legColor or o.color)
		end
	end
	ell(m, V(o.len, o.h, o.h * 0.9), V(0, y, 0), o.color)
	if o.belly then
		ell(m, V(o.len * 0.8, o.h * 0.5, o.h * 0.85), V(-o.len * 0.05, y - o.h * 0.22, 0), o.belly)
	end
	local hs = o.head
	local head = V(-o.len / 2, y + o.h * 0.12, 0)
	ell(m, V(hs * 1.25, hs, hs * 0.95), head, o.headColor or o.color)
	eyes(m, head, hs / 2, hs * 0.18)
	ball(m, hs * 0.2, head + V(-hs * 0.62, -hs * 0.05, 0), o.nose or rgb(240, 150, 160))
	if o.ear then
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(o.ear[1] * 0.4, o.ear[2], o.ear[1]), head + V(hs * 0.15, hs * 0.4 + o.ear[2] * 0.35, s * hs * 0.3), o.earColor or o.color)
		end
	end
	if o.tail then
		local a = math.rad(o.tail[2] or -20)
		local from = V(o.len * 0.45, y, 0)
		local tip = from + V(o.tail[1] * math.cos(a), o.tail[1] * math.sin(a), 0)
		taper(m, from, tip, o.tail[3] or o.h * 0.08, (o.tail[3] or o.h * 0.08) * 0.5, 3, o.tailColor or o.color)
	end
	return o.len + hs * 0.3
end

-- Upright ape: legs, torso, long arms, head. Returns standing height.
local function ape(m, o)
	local h = o.h
	for _, s in ipairs({ -1, 1 }) do
		box(m, V(h * 0.12, h * 0.38, h * 0.12), V(0, h * 0.19, s * h * 0.1), o.color)
		box(m, V(h * 0.18, h * 0.04, h * 0.12), V(-h * 0.04, h * 0.02, s * h * 0.1), o.skin)
	end
	ell(m, V(h * 0.26, h * 0.42, h * 0.34), V(0, h * 0.58, 0), o.color)
	for _, s in ipairs({ -1, 1 }) do
		beam(m, V(-h * 0.02, h * 0.74, s * h * 0.2), V(-h * 0.06, h * 0.3, s * h * 0.24), h * 0.08, o.color)
		ball(m, h * 0.09, V(-h * 0.06, h * 0.28, s * h * 0.24), o.skin)
	end
	local head = V(-h * 0.03, h * 0.88, 0)
	ball(m, h * 0.2, head, o.color)
	ell(m, V(h * 0.06, h * 0.14, h * 0.15), head + V(-h * 0.09, -h * 0.01, 0), o.skin)
	eyes(m, head + V(-h * 0.02, 0, 0), h * 0.1, h * 0.03)
	if o.cheeks then
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(h * 0.04, h * 0.14, h * 0.08), head + V(-h * 0.05, -h * 0.01, s * h * 0.13), o.cheeks)
		end
	end
	return h
end

-- Two-legged dinosaur (like the T. rex): legs, leaning body, tail, head.
-- Options: len (body), h (hip height), color, belly, head = {l, h}, tail,
-- arms, sail. Returns nose-to-tail length.
local function theropod(m, o)
	local hip = o.h
	for _, z in ipairs({ -o.len * 0.12, o.len * 0.12 }) do
		box(m, V(o.len * 0.14, hip, o.len * 0.1), V(o.len * 0.05, hip / 2, z), o.color)
		box(m, V(o.len * 0.24, hip * 0.08, o.len * 0.1), V(-o.len * 0.02, hip * 0.04, z), o.color)
	end
	local body = V(0, hip + o.len * 0.12, 0)
	ell(m, V(o.len, o.len * 0.32, o.len * 0.28), CFrame.new(body) * CFrame.Angles(0, 0, 0.1), o.color)
	if o.belly then
		ell(m, V(o.len * 0.75, o.len * 0.15, o.len * 0.27), body + V(-o.len * 0.05, -o.len * 0.1, 0), o.belly)
	end
	local hl, hh = o.head[1], o.head[2]
	local neckTop = body + V(-o.len * 0.5, o.len * 0.2, 0)
	beam(m, body + V(-o.len * 0.35, 0, 0), neckTop, o.len * 0.14, o.color)
	local head = neckTop + V(-hl * 0.35, hh * 0.1, 0)
	box(m, V(hl, hh, o.len * 0.14), head, o.color)
	eyes(m, head + V(-hl * 0.05, hh * 0.15, 0), hh * 0.45, hh * 0.18, rgb(250, 200, 50))
	for i = 0, 3 do
		box(m, V(hl * 0.06, hh * 0.18, o.len * 0.145), head + V(-hl * 0.45 + i * hl * 0.12, -hh * 0.42, 0), WHITE)
	end
	local tailEnd = body + V(o.len * 0.5 + o.tail, -o.len * 0.08, 0)
	taper(m, body + V(o.len * 0.35, 0, 0), tailEnd, o.len * 0.12, o.len * 0.03, 4, o.color)
	if o.arms then
		for _, z in ipairs({ -o.len * 0.1, o.len * 0.1 }) do
			beam(m, body + V(-o.len * 0.3, -o.len * 0.05, z), body + V(-o.len * 0.45, -o.len * 0.2, z), o.len * 0.04, o.color)
		end
	end
	if o.sail then
		for i = -2, 2 do
			local hgt = o.sail * (1 - math.abs(i) * 0.22)
			box(m, V(o.len * 0.16, hgt, o.len * 0.03), body + V(i * o.len * 0.15, o.len * 0.12 + hgt / 2, 0), o.sailColor)
		end
	end
	return tailEnd.X - (head.X - hl / 2)
end

-- Frog in the Common Frog's pose. `k` scales it; returns its length.
local function frog(m, k, color, accent)
	box(m, V(3, 1.6, 2.6) * k, V(0, 1.2, 0) * k, color)
	box(m, V(2.2, 1.2, 2.4) * k, V(-1.5, 1.8, 0) * k, color)
	for _, z in ipairs({ -0.8, 0.8 }) do
		ball(m, 0.9 * k, V(-2, 2.7, z) * k, color)
		ball(m, 0.4 * k, V(-2.35, 2.75, z * 1.1) * k, BLACK)
		box(m, V(2.4, 0.6, 0.6) * k, V(1.2, 0.4, z * 2.2) * k, accent or color)
		box(m, V(0.6, 0.6, 0.6) * k, V(-2.4, 0.3, z * 1.7) * k, accent or color)
	end
	return 3.4 * k
end

-- Elephant-style trunk hanging from the front of a quad's head.
local function trunk(m, hx, hy, hl, len, thick, color)
	taper(m, V(hx - hl * 0.45, hy, 0), V(hx - hl * 0.6, hy - len, 0), thick, thick * 0.6, 4, color)
end

local function tusks(m, hx, hy, hl, len, w, color)
	for _, z in ipairs({ -w * 0.25, w * 0.25 }) do
		beam(m, V(hx - hl * 0.4, hy - hl * 0.3, z), V(hx - hl * 0.4 - len, hy - hl * 0.3 + len * 0.35, z), len * 0.12, color)
	end
end

return function(builders)
	local function q(name, o, extra)
		builders[name] = function(m)
			local measure = quad(m, o)
			if extra then
				extra(m, o)
			end
			return measure
		end
	end

	--======================================================================
	-- Dogs and wild canines
	--======================================================================
	q("Chihuahua", { len = 3, bodyH = 1.4, legH = 1.4, width = 1.2, color = rgb(225, 185, 130), headLen = 1.4, headH = 1.3, neck = 0.4, snout = rgb(200, 160, 110), ear = { 0.5, 1.1 }, tail = 1.4 })
	q("Great Dane", { len = 6, bodyH = 2.6, legH = 4.4, width = 2, color = rgb(115, 120, 135), headLen = 2.5, headH = 2, neck = 1.6, snout = rgb(85, 90, 100), ear = { 0.5, 0.9 }, tail = 3 })
	q("German Shepherd", { len = 5.4, bodyH = 2.4, legH = 3.2, width = 2, color = rgb(190, 135, 70), headLen = 2.2, headH = 1.8, neck = 1, snout = BLACK, ear = { 0.5, 1.2 }, earColor = rgb(60, 45, 35), tail = 2.6 }, function(m, o)
		box(m, V(3.4, 1.2, 2.04), V(0.4, 5.05, 0), rgb(50, 40, 35))
	end)
	q("Dachshund", { len = 5, bodyH = 1.6, legH = 0.8, width = 1.4, color = rgb(140, 75, 40), headLen = 2, headH = 1.3, neck = 0.4, snout = rgb(120, 60, 30), ear = { 0.5, 1.1 }, earColor = rgb(100, 50, 25), tail = 1.6 })
	q("Corgi", { len = 4.4, bodyH = 1.8, legH = 1, width = 1.8, color = rgb(225, 150, 70), belly = WHITE, legColor = WHITE, headLen = 1.8, headH = 1.6, neck = 0.4, snout = WHITE, ear = { 0.6, 1 }, tail = 0.4 })
	q("Gray Wolf", { len = 6, bodyH = 2.6, legH = 4, width = 2, color = rgb(140, 140, 148), belly = rgb(215, 215, 220), headLen = 2.4, headH = 1.8, neck = 1, snout = rgb(205, 205, 210), ear = { 0.5, 0.9 }, tail = 3 })
	q("Red Fox", { len = 5, bodyH = 1.9, legH = 2.1, width = 1.6, color = rgb(215, 110, 40), belly = WHITE, legColor = rgb(60, 40, 35), headLen = 2, headH = 1.5, neck = 0.6, snout = WHITE, ear = { 0.5, 0.9 }, tail = 4 }, function(m)
		ball(m, 0.9, V(5.4, 2.1, 0), WHITE)
	end)
	q("Arctic Fox", { len = 4.4, bodyH = 1.9, legH = 1.6, width = 1.7, color = rgb(242, 242, 248), headLen = 1.8, headH = 1.5, neck = 0.5, snout = rgb(230, 230, 236), ear = { 0.5, 0.6 }, tail = 3.4 })
	q("Coyote", { len = 5.4, bodyH = 2.2, legH = 3.4, width = 1.8, color = rgb(170, 140, 100), belly = rgb(225, 210, 185), headLen = 2.2, headH = 1.6, neck = 0.8, snout = rgb(200, 175, 140), ear = { 0.5, 1 }, tail = 2.8, tailColor = rgb(120, 100, 75) })

	--======================================================================
	-- Big cats
	--======================================================================
	q("Bengal Tiger", { len = 8, bodyH = 3.2, legH = 3.6, width = 2.8, color = rgb(230, 130, 40), stripes = BLACK, belly = WHITE, headLen = 2.4, headH = 2.4, neck = 0.6, snout = WHITE, ear = { 0.5, 0.5 }, tail = 4 })
	local leopard = { len = 6.6, bodyH = 2.6, legH = 3, width = 2.2, color = rgb(225, 180, 90), headLen = 2.2, headH = 2, neck = 0.6, snout = rgb(240, 220, 180), ear = { 0.5, 0.5 }, tail = 4.2 }
	q("Leopard", leopard, function(m, o)
		spots(m, o, rgb(60, 40, 25), 14)
	end)
	local cheetah = { len = 6.4, bodyH = 2.2, legH = 4, width = 1.8, color = rgb(230, 190, 100), headLen = 1.8, headH = 1.6, neck = 0.6, snout = rgb(245, 230, 200), ear = { 0.4, 0.4 }, tail = 4.6 }
	q("Cheetah", cheetah, function(m, o)
		spots(m, o, BLACK, 16)
	end)
	local snowLeopard = { len = 6, bodyH = 2.4, legH = 2.6, width = 2, color = rgb(225, 225, 220), headLen = 2, headH = 1.9, neck = 0.5, snout = rgb(240, 240, 238), ear = { 0.4, 0.4 }, tail = 5.2 }
	q("Snow Leopard", snowLeopard, function(m, o)
		spots(m, o, rgb(120, 120, 125), 12)
	end)
	q("Eurasian Lynx", { len = 4.6, bodyH = 2.4, legH = 3.2, width = 1.8, color = rgb(190, 160, 120), headLen = 1.9, headH = 1.8, neck = 0.6, snout = rgb(230, 215, 190), ear = { 0.4, 1 }, earColor = rgb(60, 45, 35), tail = 0.6, tailColor = BLACK })

	--======================================================================
	-- Bears and big grazers
	--======================================================================
	q("American Black Bear", { len = 7, bodyH = 3.8, legH = 3, width = 3, color = rgb(40, 35, 38), headLen = 2.6, headH = 2.2, neck = 0.3, snout = rgb(170, 130, 90), ear = { 0.6, 0.6 }, tail = 0.6 })
	local moose = { len = 8, bodyH = 4, legH = 7, width = 3, color = rgb(85, 60, 40), legColor = rgb(60, 42, 30), headLen = 3.4, headH = 2.2, neck = 1.2, snout = rgb(70, 50, 35), ear = { 0.5, 1 }, tail = 0.8 }
	q("Moose", moose, function(m, o)
		local hx, hy = quadHead(o)
		for _, z in ipairs({ -1, 1 }) do
			box(m, V(2.8, 1.2, 0.3), CFrame.new(hx + 1, hy + 1.8, z * 1.4) * CFrame.Angles(0, 0, -0.25), rgb(205, 185, 150))
			for i = 0, 3 do
				box(m, V(0.25, 0.8, 0.25), V(hx + i * 0.7, hy + 2.6 - i * 0.18, z * 1.4), rgb(205, 185, 150))
			end
		end
		box(m, V(0.8, 1.6, 0.6), V(hx + 0.4, hy - 1.7, 0), rgb(60, 42, 30)) -- dewlap
	end)
	local elk = { len = 7.6, bodyH = 3.4, legH = 5.4, width = 2.6, color = rgb(165, 115, 70), legColor = rgb(110, 75, 50), headLen = 2.8, headH = 1.8, neck = 2.4, snout = rgb(90, 65, 45), mane = rgb(95, 65, 45), ear = { 0.4, 0.9 }, tail = 0.8, tailColor = rgb(225, 205, 170) }
	q("Elk", elk, function(m, o)
		local hx, hy = quadHead(o)
		antlers(m, hx + 0.6, hy + 0.9, o.width, 4.4, rgb(220, 205, 175))
	end)
	local reindeer = { len = 6.4, bodyH = 3, legH = 4, width = 2.4, color = rgb(130, 105, 85), mane = rgb(235, 230, 220), legColor = rgb(100, 80, 65), headLen = 2.4, headH = 1.8, neck = 1.6, snout = rgb(60, 50, 45), ear = { 0.4, 0.8 }, tail = 0.6, tailColor = WHITE }
	q("Reindeer", reindeer, function(m, o)
		local hx, hy = quadHead(o)
		antlers(m, hx + 0.5, hy + 0.9, o.width, 3.6, rgb(220, 205, 175))
	end)
	builders["American Bison"] = function(m)
		local o = { len = 9, bodyH = 4.4, legH = 3.6, width = 3.6, color = rgb(95, 65, 40), headLen = 3, headH = 3, neck = -0.6, mane = rgb(60, 40, 28), horns = rgb(50, 45, 40), ear = { 0.5, 0.4 }, tail = 1.6, hump = 2.2 }
		quad(m, o)
		box(m, V(4.6, 3.6, 3.7), V(-2.4, 6.8, 0), rgb(65, 45, 30))
		return o.legH + o.bodyH + o.hump
	end
	q("Water Buffalo", { len = 8.4, bodyH = 4, legH = 4, width = 3.2, color = rgb(70, 70, 76), headLen = 2.8, headH = 2.4, neck = 0, snout = rgb(55, 55, 60), ear = { 0.6, 0.5 }, tail = 2.6 }, function(m, o)
		local hx, hy = quadHead(o)
		for _, z in ipairs({ -1, 1 }) do
			beam(m, V(hx + 0.4, hy + 1.2, z * 0.9), V(hx + 2.4, hy + 2, z * 2.6), 0.5, rgb(60, 55, 50))
			beam(m, V(hx + 2.4, hy + 2, z * 2.6), V(hx + 3.2, hy + 3.2, z * 2.2), 0.4, rgb(60, 55, 50))
		end
	end)
	q("Yak", { len = 8, bodyH = 4.2, legH = 3.6, width = 3.4, color = rgb(60, 45, 40), headLen = 2.6, headH = 2.4, neck = -0.2, horns = rgb(225, 215, 195), ear = { 0.5, 0.5 }, tail = 2.6, hump = 1.2 }, function(m, o)
		box(m, V(8.2, 1.8, 3.5), V(0, 3.6, 0), rgb(50, 38, 34)) -- shaggy skirt
	end)
	q("Llama", { len = 5.6, bodyH = 3, legH = 4.6, width = 2.2, color = rgb(235, 225, 205), headLen = 2, headH = 1.6, neck = 4.6, snout = rgb(210, 195, 170), ear = { 0.4, 1.2 }, tail = 1 })
	q("Alpaca", { len = 4.6, bodyH = 3, legH = 3.2, width = 2.4, color = rgb(200, 160, 120), headLen = 1.8, headH = 1.6, neck = 3.4, snout = rgb(170, 130, 95), ear = { 0.4, 0.9 }, tail = 0.8 }, function(m, o)
		ball(m, 1.4, V(-2.7, 10.4, 0), rgb(215, 180, 140)) -- fluffy topknot
	end)
	q("Goat", { len = 5, bodyH = 2.6, legH = 3, width = 2, color = WHITE, headLen = 2, headH = 1.6, neck = 1, snout = rgb(240, 220, 215), horns = rgb(150, 135, 115), ear = { 0.6, 0.4 }, tail = 0.8 }, function(m, o)
		local hx, hy = quadHead(o)
		box(m, V(0.5, 1.2, 0.5), V(hx - 0.3, hy - 1.3, 0), rgb(225, 225, 225)) -- beard
	end)
	q("Donkey", { len = 6.4, bodyH = 3.2, legH = 4.4, width = 2.4, color = rgb(150, 140, 135), belly = rgb(220, 215, 210), headLen = 3, headH = 1.9, neck = 1.8, snout = rgb(225, 220, 215), mane = rgb(70, 60, 55), ear = { 0.5, 2 }, tail = 3 })
	q("Shetland Pony", { len = 6, bodyH = 3.2, legH = 3.4, width = 2.4, color = rgb(110, 70, 45), headLen = 2.6, headH = 1.9, neck = 2, snout = rgb(90, 55, 35), mane = rgb(235, 225, 200), ear = { 0.4, 0.7 }, tail = 3.4, tailColor = rgb(235, 225, 200) })
	q("Clydesdale Horse", { len = 9, bodyH = 4.2, legH = 6.6, width = 3, color = rgb(125, 60, 35), headLen = 3.6, headH = 2.4, neck = 4, snout = WHITE, mane = BLACK, ear = { 0.4, 1 }, tail = 4.4, tailColor = BLACK }, function(m, o)
		for _, x in ipairs({ -3.6, 3.6 }) do
			for _, z in ipairs({ -1.05, 1.05 }) do
				box(m, V(1.3, 1.6, 1.3), V(x, 0.8, z), WHITE) -- feathered feet
			end
		end
	end)
	q("Okapi", { len = 7, bodyH = 3.2, legH = 5.4, width = 2.4, color = rgb(75, 40, 35), headLen = 2.8, headH = 1.8, neck = 2.6, snout = rgb(225, 215, 200), ear = { 0.7, 1.2 }, tail = 2.4 }, function(m, o)
		for _, x in ipairs({ -2.9, 2.9 }) do
			for i = 0, 3 do
				box(m, V(0.75, 0.3, 2.45), V(x, 1.4 + i * 0.8, 0), WHITE)
			end
		end
	end)
	q("Blue Wildebeest", { len = 7, bodyH = 3.4, legH = 4.4, width = 2.4, color = rgb(100, 100, 108), stripes = rgb(70, 70, 76), headLen = 3, headH = 2, neck = 0.6, snout = BLACK, mane = BLACK, horns = rgb(60, 55, 50), ear = { 0.4, 0.5 }, tail = 3, tailColor = BLACK })
	q("Thomson's Gazelle", { len = 4.4, bodyH = 2, legH = 3.2, width = 1.4, color = rgb(205, 145, 80), belly = WHITE, headLen = 1.8, headH = 1.2, neck = 1.6, snout = rgb(230, 210, 180), horns = BLACK, ear = { 0.3, 0.8 }, tail = 0.8, tailColor = BLACK }, function(m, o)
		box(m, V(4.2, 0.35, 1.42), V(0, 4, 0), BLACK)
	end)
	q("Warthog", { len = 5.4, bodyH = 2.6, legH = 2.2, width = 2.2, color = rgb(120, 100, 92), headLen = 2.4, headH = 2, neck = -0.2, snout = rgb(140, 115, 105), mane = rgb(70, 55, 50), ear = { 0.5, 0.6 }, tail = 2 }, function(m, o)
		local hx, hy = quadHead(o)
		tusks(m, hx, hy + 0.5, o.headLen, 1.2, o.width, rgb(240, 235, 215))
	end)
	q("Wild Boar", { len = 6, bodyH = 3, legH = 2.4, width = 2.4, color = rgb(95, 75, 60), headLen = 2.6, headH = 2.2, neck = -0.3, snout = rgb(110, 85, 70), ear = { 0.5, 0.7 }, tail = 1.2 }, function(m, o)
		local hx, hy = quadHead(o)
		tusks(m, hx, hy + 0.4, o.headLen, 0.8, o.width, rgb(240, 235, 215))
		box(m, V(5, 0.6, 1.2), V(0, 5.6, 0), rgb(70, 55, 45))
	end)
	q("Malayan Tapir", { len = 7, bodyH = 3.4, legH = 3, width = 2.6, color = BLACK, headLen = 2.6, headH = 2, neck = 0, ear = { 0.5, 0.6 }, tail = 0.6 }, function(m, o)
		box(m, V(3.4, 3.45, 2.65), V(1.2, 4.7, 0), WHITE)
		local hx, hy = quadHead(o)
		trunk(m, hx, hy, o.headLen, 1.2, 0.45, BLACK)
	end)
	q("Capybara", { len = 4.6, bodyH = 2.6, legH = 1.4, width = 2.2, color = rgb(150, 105, 70), headLen = 2, headH = 1.8, neck = 0, snout = rgb(120, 85, 55), ear = { 0.4, 0.4 }, tail = 0.1 })
	builders["Woolly Mammoth"] = function(m)
		local o = { len = 9, bodyH = 5.6, legH = 5, width = 4.4, color = rgb(110, 75, 45), headLen = 3.4, headH = 3.4, neck = 0, ear = { 0.6, 0.8 }, tail = 1.2, hump = 1.4 }
		quad(m, o)
		local hx, hy = quadHead(o)
		trunk(m, hx, hy, o.headLen, 5.6, 0.9, o.color)
		for _, z in ipairs({ -1, 1 }) do
			beam(m, V(hx - 1.2, hy - 1.4, z * 1.1), V(hx - 3.6, hy - 2.4, z * 1.4), 0.6, rgb(240, 230, 200))
			beam(m, V(hx - 3.6, hy - 2.4, z * 1.4), V(hx - 4.6, hy - 0.4, z * 1.2), 0.55, rgb(240, 230, 200))
		end
		return o.legH + o.bodyH + o.hump
	end
	builders["Asian Elephant"] = function(m)
		local o = { len = 9, bodyH = 5, legH = 4.4, width = 4, color = rgb(140, 135, 135), headLen = 3.2, headH = 3.4, neck = 0, ear = { 0.4, 2.2 }, tail = 2.4 }
		local measure = quad(m, o)
		local hx, hy = quadHead(o)
		trunk(m, hx, hy, o.headLen, 5.2, 0.8, o.color)
		box(m, V(1.6, 2.6, 4.2), V(hx + 1.4, hy - 0.2, 0), rgb(125, 120, 122)) -- ears
		return measure
	end
	q("Giant Anteater", { len = 6, bodyH = 2.4, legH = 2, width = 1.8, color = rgb(120, 100, 82), headLen = 3.4, headH = 0.9, neck = -0.6, ear = { 0.2, 0.2 }, tail = 5.6, tailColor = rgb(80, 65, 55) }, function(m, o)
		slab(m, V(-2.6, 4.2, 0), V(1, 2.6, 0), 1.85, 0.6, BLACK)
		box(m, V(2.4, 2.4, 0.6), V(4.6, 3, 0), rgb(80, 65, 55)) -- bushy tail
	end)
	q("Ring-tailed Lemur", { len = 3.6, bodyH = 1.6, legH = 1.6, width = 1.4, color = rgb(160, 160, 165), belly = WHITE, headLen = 1.4, headH = 1.2, neck = 0.4, snout = BLACK, ear = { 0.4, 0.5 }, tail = 0.1 }, function(m)
		for i = 0, 9 do
			box(m, V(0.5, 0.42, 0.5), V(2.1 + i * 0.12, 3.4 + i * 0.42, 0), i % 2 == 0 and BLACK or WHITE)
		end
	end)

	--======================================================================
	-- Small mammals
	--======================================================================
	q("Raccoon", { len = 4, bodyH = 2, legH = 1.4, width = 1.8, color = rgb(130, 130, 135), headLen = 1.6, headH = 1.4, neck = 0.2, snout = WHITE, ear = { 0.4, 0.5 }, tail = 0.1 }, function(m)
		box(m, V(1, 0.4, 1.4), V(-2.5, 3.2, 0), BLACK)
		for i = 0, 5 do
			box(m, V(0.4, 0.6, 0.6), V(2.2 + i * 0.32, 2.6 - i * 0.12, 0), i % 2 == 0 and BLACK or rgb(170, 170, 175))
		end
	end)
	q("Striped Skunk", { len = 3.6, bodyH = 1.8, legH = 0.8, width = 1.6, color = BLACK, headLen = 1.4, headH = 1.2, neck = 0.2, ear = { 0.3, 0.3 }, tail = 0.1 }, function(m)
		box(m, V(3.4, 0.4, 0.8), V(0, 2.75, 0), WHITE)
		ell(m, V(1.6, 3.2, 1.2), V(2.4, 3.4, 0), BLACK)
		ell(m, V(0.6, 2.8, 1.25), V(2.3, 3.6, 0), WHITE)
	end)
	q("European Badger", { len = 4.4, bodyH = 2, legH = 1, width = 2, color = rgb(140, 140, 145), legColor = BLACK, headLen = 1.8, headH = 1.4, neck = 0, snout = WHITE, ear = { 0.3, 0.3 }, tail = 0.6 }, function(m)
		box(m, V(1.9, 0.35, 1.52), V(-2.8, 2.6, 0), BLACK)
	end)
	builders["Hedgehog"] = function(m)
		local measure = critter(m, { len = 3, h = 2, color = rgb(120, 100, 80), head = 1.1, headColor = rgb(215, 195, 165), nose = BLACK, ear = { 0.3, 0.3 } })
		for i = 0, 11 do
			local a = math.rad(20 + i * 12)
			local p = V(math.cos(a) * 1.5 - 0.1, 1.3 + math.sin(a) * 1.05, 0)
			beam(m, p, p + V(math.cos(a), math.sin(a), 0) * 0.6, 0.12, rgb(70, 55, 45))
		end
		return measure
	end
	builders["Nine-banded Armadillo"] = function(m)
		local measure = critter(m, { len = 4, h = 1.8, color = rgb(160, 140, 120), head = 1, ear = { 0.4, 0.6 }, tail = { 3, -15, 0.25 }, nose = rgb(140, 120, 100) })
		for i = -4, 4 do
			box(m, V(0.18, 1.9, 1.7), V(i * 0.4, 1.35, 0), rgb(130, 112, 95))
		end
		return measure
	end
	builders["North American Beaver"] = function(m)
		critter(m, { len = 4.4, h = 2.4, color = rgb(120, 75, 45), head = 1.8, ear = { 0.4, 0.3 }, nose = BLACK })
		box(m, V(0.3, 0.4, 0.4), V(-3.15, 1.6, 0), WHITE)
		box(m, V(3.2, 0.3, 1.4), V(3.6, 0.3, 0), rgb(65, 50, 45)) -- flat tail
		return (3.6 + 1.6) - (-2.2 - 1.1)
	end
	builders["Red Squirrel"] = function(m)
		local measure = critter(m, { len = 2.4, h = 1.4, color = rgb(200, 90, 40), belly = WHITE, head = 1.1, ear = { 0.3, 0.6 }, nose = BLACK })
		ell(m, V(1.4, 3, 1.1), CFrame.new(1.7, 2.4, 0) * CFrame.Angles(0, 0, 0.25), rgb(190, 85, 35))
		return measure
	end
	builders["Guinea Pig"] = function(m)
		local measure = critter(m, { len = 2.8, h = 1.6, color = rgb(230, 150, 70), head = 1.3, ear = { 0.4, 0.3 }, legH = 0.15 })
		box(m, V(1.2, 1.62, 1.46), V(0.4, 1.0, 0), WHITE)
		return measure
	end
	builders["House Mouse"] = function(m)
		return critter(m, { len = 2.2, h = 1.2, color = rgb(150, 145, 140), head = 0.9, ear = { 0.6, 0.6 }, earColor = rgb(240, 170, 170), tail = { 2.6, -10, 0.1 }, tailColor = rgb(240, 170, 170) })
	end
	builders["Brown Rat"] = function(m)
		return critter(m, { len = 3, h = 1.4, color = rgb(120, 95, 75), belly = rgb(190, 175, 160), head = 1.1, ear = { 0.5, 0.45 }, earColor = rgb(225, 160, 160), tail = { 3, -12, 0.14 }, tailColor = rgb(225, 160, 160) })
	end
	builders["Ferret"] = function(m)
		local measure = critter(m, { len = 4, h = 1.1, color = rgb(215, 195, 160), head = 0.9, headColor = WHITE, ear = { 0.3, 0.3 }, tail = { 1.6, -10, 0.25 }, tailColor = rgb(90, 70, 55), legColor = rgb(90, 70, 55) })
		box(m, V(0.35, 0.25, 0.92), V(-2.05, 1.05, 0), rgb(90, 70, 55)) -- mask
		return measure
	end
	builders["Meerkat"] = function(m)
		local tan = rgb(200, 170, 125)
		for _, z in ipairs({ -0.35, 0.35 }) do
			box(m, V(0.5, 1.2, 0.35), V(0.2, 0.6, z), tan)
		end
		ell(m, V(1.5, 3.6, 1.3), V(0, 2.8, 0), tan)
		ell(m, V(0.9, 2.4, 1.2), V(-0.35, 2.4, 0), rgb(230, 210, 175))
		for _, z in ipairs({ -0.45, 0.45 }) do
			beam(m, V(-0.4, 3.8, z), V(-0.8, 3.1, z * 0.8), 0.28, tan)
		end
		local head = V(-0.25, 5, 0)
		ell(m, V(1.5, 1, 1), head, tan)
		box(m, V(0.35, 0.3, 1.05), head + V(-0.15, 0.1, 0), BLACK)
		ball(m, 0.2, head + V(-0.78, -0.05, 0), BLACK)
		taper(m, V(0.6, 1.4, 0), V(2.2, 0.1, 0), 0.25, 0.1, 3, tan)
		return 5.5
	end
	builders["Koala"] = function(m)
		local gray = rgb(160, 160, 168)
		ell(m, V(3, 3.6, 2.8), V(0, 2, 0), gray)
		ell(m, V(1.6, 2.2, 2.4), V(-0.8, 1.7, 0), rgb(230, 228, 225))
		for _, z in ipairs({ -1, 1 }) do
			beam(m, V(-0.6, 2.8, z * 1.2), V(-1.4, 1.4, z * 1.1), 0.7, gray)
			ell(m, V(1.6, 0.8, 1), V(-0.8, 0.4, z * 0.9), gray)
		end
		local head = V(-0.6, 4.6, 0)
		ell(m, V(2.4, 2.2, 2.4), head, gray)
		for _, z in ipairs({ -1, 1 }) do
			ell(m, V(0.7, 1.4, 1.4), head + V(0.3, 0.9, z * 1.3), rgb(220, 220, 225))
		end
		ell(m, V(0.5, 1, 0.7), head + V(-1.2, -0.2, 0), BLACK)
		eyes(m, head + V(0, 0.2, 0), 1.1, 0.25)
		return 5.9
	end
	builders["Red Kangaroo"] = function(m)
		local red = rgb(190, 95, 60)
		for _, z in ipairs({ -0.6, 0.6 }) do
			box(m, V(3, 0.5, 0.6), V(-0.6, 0.25, z), red)
			slab(m, V(0.6, 0.4, z), V(-0.4, 3.4, z), 0.7, 1.2, red)
		end
		ell(m, V(3, 6, 2.6), CFrame.new(0.4, 5.4, 0) * CFrame.Angles(0, 0, -0.25), red)
		ell(m, V(1.8, 3.6, 2.4), CFrame.new(-0.4, 5, 0) * CFrame.Angles(0, 0, -0.25), rgb(225, 190, 160))
		taper(m, V(1.6, 3.2, 0), V(5.6, 0.2, 0), 0.7, 0.25, 4, red)
		for _, z in ipairs({ -0.7, 0.7 }) do
			beam(m, V(-0.6, 7, z), V(-1.6, 5.8, z), 0.35, red)
		end
		local head = V(-0.8, 9.2, 0)
		ell(m, V(2.4, 1.4, 1.3), head + V(-0.4, 0, 0), red)
		for _, z in ipairs({ -0.4, 0.4 }) do
			ell(m, V(0.4, 1.4, 0.6), head + V(0.5, 1.1, z), red)
		end
		eyes(m, head, 0.6, 0.22)
		ball(m, 0.3, head + V(-1.6, -0.05, 0), BLACK)
		return 10.2
	end
	builders["Chimpanzee"] = function(m)
		return ape(m, { h = 8, color = rgb(45, 38, 35), skin = rgb(205, 170, 140) })
	end
	builders["Bornean Orangutan"] = function(m)
		return ape(m, { h = 8, color = rgb(190, 90, 35), skin = rgb(120, 85, 70), cheeks = rgb(110, 80, 65) })
	end

	--======================================================================
	-- Birds
	--======================================================================
	builders["Flamingo"] = function(m)
		return bird(m, { legH = 5, body = { 3, 1.8, 1.6 }, tilt = 10, color = rgb(250, 140, 160), wing = rgb(240, 110, 135), neck = 4, head = 1, beak = { 1.2, BLACK, 0.6, 0.35 }, tail = { 0.8, 0 }, legColor = rgb(240, 120, 140) })
	end
	builders["Peacock"] = function(m)
		local measure = bird(m, { legH = 2, body = { 2.6, 2, 1.6 }, tilt = 25, color = rgb(30, 90, 200), wing = rgb(70, 120, 90), neck = 1.6, head = 0.9, beak = { 0.5, rgb(220, 210, 180) }, crest = rgb(30, 90, 200), tail = { 9, -12, 2.2 }, tailColor = rgb(40, 140, 80), legColor = rgb(160, 150, 140), measure = "length" })
		for i = 1, 6 do
			local p = V(1.4 + i * 1.3, 2.6 - i * 0.28, -0.6)
			ball(m, 0.6, p, rgb(30, 90, 200))
			ball(m, 0.3, p + V(0, 0, -0.2), rgb(240, 200, 60))
		end
		return measure
	end
	builders["Chicken"] = function(m)
		return bird(m, { legH = 1.2, body = { 2.4, 2, 1.8 }, tilt = 20, color = rgb(245, 240, 230), neck = 0.8, head = 1.1, beak = { 0.4, rgb(240, 180, 50) }, crest = rgb(225, 40, 40), tail = { 1.4, 50, 1.2 }, legColor = rgb(240, 180, 50) })
	end
	builders["Wild Turkey"] = function(m)
		local measure = bird(m, { legH = 2.6, body = { 4, 3, 2.6 }, tilt = 20, color = rgb(90, 60, 40), wing = rgb(120, 85, 55), neck = 1.6, head = 0.9, headColor = rgb(170, 200, 230), beak = { 0.4, rgb(220, 200, 160) }, tail = { 0.5, 60 }, legColor = rgb(200, 120, 110) })
		for i = -3, 3 do
			local a = math.rad(70 + i * 16)
			slab(m, V(1.6, 4.4, 0), V(1.6 + math.cos(a) * 3.4, 4.4 + math.sin(a) * 3.4, 0), 0.2, 1.1, i % 2 == 0 and rgb(110, 75, 45) or rgb(150, 105, 65))
		end
		ball(m, 0.5, V(-2.6, 6.4, 0), rgb(210, 50, 50)) -- wattle
		return math.max(measure, 4.4 + 3.4)
	end
	builders["Mallard Duck"] = function(m)
		return bird(m, { legH = 0.5, body = { 3.2, 1.8, 1.8 }, tilt = 0, color = rgb(150, 125, 100), wing = rgb(120, 100, 85), neck = 0.7, head = 1.1, headColor = rgb(30, 120, 60), beak = { 0.8, rgb(240, 200, 40), 0.1, 0.3 }, tail = { 0.6, 20 }, legColor = rgb(240, 140, 40), measure = "length" })
	end
	builders["Mute Swan"] = function(m)
		return bird(m, { legH = 0.4, body = { 4.6, 2.2, 2.4 }, tilt = -5, color = WHITE, neck = 3.4, head = 1, beak = { 1, rgb(240, 120, 40), 0.2, 0.35 }, tail = { 0.8, 25 }, legColor = BLACK, measure = "length" })
	end
	builders["Canada Goose"] = function(m)
		return bird(m, { legH = 1.2, body = { 3.6, 2, 2 }, tilt = 5, color = rgb(130, 110, 90), belly = rgb(225, 220, 210), neck = 2.4, neckColor = BLACK, head = 1, headColor = BLACK, beak = { 0.7, BLACK }, tail = { 0.7, 15 }, legColor = BLACK, measure = "length" })
	end
	builders["Rock Pigeon"] = function(m)
		return bird(m, { legH = 0.6, body = { 2.2, 1.4, 1.3 }, tilt = 20, color = rgb(130, 135, 150), wing = rgb(160, 165, 178), neck = 0.4, head = 0.9, neckColor = rgb(100, 140, 120), beak = { 0.35, rgb(60, 60, 65) }, tail = { 1.6, -10, 0.9 }, tailColor = rgb(100, 105, 120), legColor = rgb(220, 90, 90), measure = "length" })
	end
	builders["American Crow"] = function(m)
		return bird(m, { legH = 0.8, body = { 2.6, 1.4, 1.3 }, tilt = 20, color = rgb(30, 30, 38), neck = 0.4, head = 1, beak = { 0.8, rgb(25, 25, 30), 0.1, 0.35 }, tail = { 2, -12, 0.9 }, legColor = rgb(25, 25, 30), measure = "length" })
	end
	builders["Scarlet Macaw"] = function(m)
		return bird(m, { legH = 0.6, body = { 2.6, 1.6, 1.4 }, tilt = 65, color = rgb(220, 30, 40), wing = rgb(250, 200, 40), neck = 0.3, head = 1.2, beak = { 0.5, rgb(235, 225, 210), 0.4, 0.5 }, tail = { 4.4, -100, 0.6 }, tailColor = rgb(40, 90, 200), legColor = rgb(100, 100, 105), measure = "long" })
	end
	builders["Toco Toucan"] = function(m)
		return bird(m, { legH = 0.6, body = { 2.4, 1.6, 1.4 }, tilt = 60, color = rgb(25, 25, 30), belly = WHITE, neck = 0.2, head = 1.1, beak = { 2.6, rgb(250, 140, 30), 0.3, 0.8 }, tail = { 2.2, -105, 0.7 }, legColor = rgb(60, 110, 200), measure = "long" })
	end
	builders["Great Horned Owl"] = function(m)
		local measure = bird(m, { legH = 0.6, body = { 3, 2.6, 2.4 }, tilt = 80, color = rgb(130, 100, 70), belly = rgb(200, 180, 150), neck = 0, head = 2, beak = { 0.3, rgb(50, 45, 40), 0.3, 0.35 }, tail = { 0.6, -100 }, legColor = rgb(200, 180, 150) })
		for _, z in ipairs({ -0.55, 0.55 }) do
			box(m, V(0.35, 0.9, 0.35), V(-0.2, measure + 0.25, z), rgb(110, 85, 60)) -- ear tufts
			ball(m, 0.6, V(-1.25, measure - 0.85, z * 1.05), rgb(250, 190, 40))
		end
		return measure + 0.6
	end
	builders["Ruby-throated Hummingbird"] = function(m)
		local measure = bird(m, { legH = 0.3, body = { 1.8, 0.9, 0.8 }, tilt = 30, color = rgb(70, 150, 90), belly = rgb(225, 225, 225), neck = 0.1, head = 0.7, beak = { 1.4, BLACK, -0.1, 0.12 }, tail = { 0.8, -30, 0.5 }, legColor = BLACK, measure = "length" })
		ball(m, 0.5, V(-0.95, 1.05, 0), rgb(220, 30, 60))
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(0.5, 2.2, 0.08), CFrame.new(0.1, 1.9, s * 0.5) * CFrame.Angles(0, 0, 0.4), rgb(160, 200, 190), nil).Transparency = 0.3
		end
		return measure
	end
	builders["Emu"] = function(m)
		return bird(m, { legH = 5, body = { 4.4, 3.2, 2.8 }, tilt = 10, color = rgb(100, 85, 70), neck = 3.4, neckColor = rgb(120, 130, 160), head = 0.9, beak = { 0.6, rgb(60, 55, 50) }, tail = { 0.6, -40 }, legColor = rgb(120, 110, 100) })
	end
	builders["Southern Cassowary"] = function(m)
		local measure = bird(m, { legH = 4.4, body = { 4.4, 3.4, 3 }, tilt = 15, color = rgb(25, 25, 30), neck = 3, neckColor = rgb(40, 110, 220), head = 1, headColor = rgb(40, 110, 220), beak = { 0.7, BLACK }, tail = { 0.6, -40 }, legColor = rgb(120, 110, 90) })
		box(m, V(0.8, 1.2, 0.5), V(-2.6, measure + 0.4, 0), rgb(120, 90, 60)) -- casque
		box(m, V(0.3, 1, 0.5), V(-2.6, measure - 2.2, 0), rgb(220, 40, 40)) -- wattle
		return measure + 1
	end
	builders["Brown Kiwi"] = function(m)
		return bird(m, { legH = 0.9, body = { 3, 2.6, 2.4 }, tilt = 0, color = rgb(130, 100, 70), neck = 0, head = 1.1, beak = { 2, rgb(225, 205, 175), 0.9, 0.2 }, tail = { 0.2, 0 }, legColor = rgb(200, 180, 150) })
	end
	builders["Atlantic Puffin"] = function(m)
		return bird(m, { legH = 0.6, body = { 2, 2.2, 1.6 }, tilt = 55, color = rgb(25, 25, 30), belly = WHITE, neck = 0, head = 1.3, headColor = rgb(230, 230, 230), beak = { 0.6, rgb(240, 110, 40), 0.15, 0.6 }, tail = { 0.4, -80 }, legColor = rgb(240, 120, 40) })
	end
	builders["Shoebill"] = function(m)
		return bird(m, { legH = 4.4, body = { 3, 3.2, 2.4 }, tilt = 60, color = rgb(130, 140, 150), neck = 1, head = 1.6, beak = { 1.6, rgb(200, 180, 140), 0.4, 1 }, tail = { 0.6, -90 }, legColor = rgb(60, 60, 65) })
	end
	builders["Secretary Bird"] = function(m)
		local measure = bird(m, { legH = 5.6, body = { 3.4, 2, 2 }, tilt = 15, color = rgb(200, 205, 210), wing = BLACK, neck = 1.8, head = 1, beak = { 0.5, rgb(90, 90, 95), 0.2 }, tail = { 3.4, -60, 0.8 }, legColor = rgb(240, 180, 120) })
		for i = 0, 3 do
			beam(m, V(-0.4, measure - 0.6, 0), V(0.8 + i * 0.25, measure + 0.5 - i * 0.25, 0), 0.15, BLACK)
		end
		return measure + 0.3
	end
	builders["White Stork"] = function(m)
		return bird(m, { legH = 4.4, body = { 3.6, 2, 2 }, tilt = 10, color = WHITE, wing = BLACK, neck = 2.2, head = 1, beak = { 2, rgb(225, 50, 40), 0.6, 0.35 }, tail = { 0.8, -20 }, legColor = rgb(225, 50, 40) })
	end
	builders["Great Blue Heron"] = function(m)
		return bird(m, { legH = 5, body = { 3.4, 1.8, 1.8 }, tilt = 25, color = rgb(120, 140, 165), neck = 3.6, neckColor = rgb(170, 175, 185), head = 0.9, crest = BLACK, beak = { 1.8, rgb(230, 200, 80), 0.2, 0.3 }, tail = { 1, -20 }, legColor = rgb(150, 140, 120) })
	end
	builders["Andean Condor"] = function(m)
		return flyer(m, { span = 32, bodyL = 6, bodyW = 3, color = BLACK, wing = BLACK, tip = rgb(230, 230, 230), chord = 4.4, tipChord = 3.2, sweep = 1.2, head = 1.6, headColor = rgb(200, 120, 110), beak = { 0.8, rgb(220, 210, 190) }, tail = { 2.6, 2.2 } })
	end
	builders["Wandering Albatross"] = function(m)
		return flyer(m, { span = 31, bodyL = 5, bodyW = 2.6, color = WHITE, wing = WHITE, tip = BLACK, chord = 2.4, tipChord = 1.6, sweep = -0.4, head = 1.5, beak = { 1.2, rgb(240, 190, 160) }, tail = { 1.2, 1.4 } })
	end
	builders["Large Flying Fox"] = function(m)
		local brown = rgb(70, 55, 45)
		local measure = flyer(m, { span = 15, bodyL = 4, bodyW = 2, color = rgb(130, 85, 45), wing = brown, chord = 4.4, tipChord = 3.6, sweep = 1.6, head = 1.6, headColor = rgb(150, 100, 55) })
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(0.4, 0.8, 0.4), V(s * 0.5, 5.3, 0), rgb(150, 100, 55)) -- ears
			for i = 1, 3 do
				beam(m, V(s * 1, 4.2, 0), V(s * i * 2.4, 4.2 + 1.6 - i * 1.4, 0), 0.15, rgb(50, 40, 35))
			end
		end
		return measure
	end

	--======================================================================
	-- Ocean
	--======================================================================
	builders["Humpback Whale"] = function(m)
		swimmer(m, 30, 7, rgb(50, 55, 70), rgb(220, 220, 225), 1.4)
		for _, s in ipairs({ -1, 1 }) do
			slab(m, V(-6, 3, s * 3.2), V(2, 1, s * 4.6), 2, 0.6, rgb(220, 220, 225))
		end
		return 30
	end
	builders["Sperm Whale"] = function(m)
		swimmer(m, 32, 7, rgb(85, 85, 95), rgb(120, 120, 130), 1.4)
		box(m, V(11, 7.4, 6.6), V(-11, 5.6, 0), rgb(85, 85, 95))
		box(m, V(8, 0.8, 1.6), V(-11.5, 2, 0), rgb(110, 110, 120)) -- lower jaw
		box(m, V(0.4, 0.4, 0.1), V(-8, 5, -3.35), BLACK)
		return 32
	end
	builders["Narwhal"] = function(m)
		swimmer(m, 9, 2.4, rgb(150, 155, 160), rgb(225, 225, 228), 0.3)
		for i = 0, 6 do
			box(m, V(0.6, 0.6, 2.2), V(-3 + i * 1.1, 2.6, 0), rgb(100, 105, 115))
		end
		taper(m, V(-5.2, 1.8, 0), V(-11.4, 2.6, 0), 0.22, 0.05, 4, rgb(240, 235, 215))
		return 9
	end
	builders["Beluga Whale"] = function(m)
		swimmer(m, 8, 2.8, rgb(240, 242, 245), rgb(225, 228, 232), 0.2)
		ell(m, V(1.8, 2, 2.2), V(-3.6, 2.8, 0), rgb(240, 242, 245)) -- melon
		return 8
	end
	builders["West Indian Manatee"] = function(m)
		return seal(m, { len = 9, thick = 3.4, color = rgb(130, 130, 135), head = 2.2, raise = 0, fluke = true })
	end
	builders["Walrus"] = function(m)
		local measure = seal(m, { len = 9, thick = 4, color = rgb(170, 120, 95), head = 2.6, raise = 1.6 })
		local head = V(-4.5 + 1.3, 2.4 + 1.6, 0)
		for _, z in ipairs({ -0.5, 0.5 }) do
			beam(m, head + V(-1, -0.8, z), head + V(-1.2, -3.2, z), 0.35, rgb(245, 240, 225))
		end
		ell(m, V(1.2, 1, 2), head + V(-1.1, -0.4, 0), rgb(200, 160, 135))
		return measure
	end
	builders["California Sea Lion"] = function(m)
		return seal(m, { len = 7, thick = 2.2, color = rgb(110, 80, 55), head = 1.5, raise = 2.4 })
	end
	builders["Harbor Seal"] = function(m)
		local measure = seal(m, { len = 6, thick = 2.2, color = rgb(150, 150, 155), belly = rgb(200, 200, 205), head = 1.6, raise = 0.6 })
		for i = 1, 10 do
			box(m, V(0.3, 0.3, 2.1), V(-2 + (i * 37 % 50) / 10, 1 + (i * 17 % 10) / 10, 0), rgb(90, 90, 95))
		end
		return measure
	end
	builders["Sea Otter"] = function(m)
		local brown = rgb(110, 80, 60)
		ell(m, V(5, 1.6, 1.8), V(0, 1, 0), brown)
		local head = V(-2.8, 1.4, 0)
		ball(m, 1.6, head, rgb(200, 185, 165))
		eyes(m, head, 0.8, 0.22)
		ball(m, 0.3, head + V(-0.8, 0, 0), BLACK)
		ball(m, 0.9, V(-1.4, 2, 0), rgb(130, 100, 80)) -- paws holding a shell
		box(m, V(1.6, 0.4, 0.8), V(3.2, 1.3, 0), brown)
		return 7.6
	end
	builders["Great Hammerhead"] = function(m)
		swimmer(m, 18, 3.6, rgb(130, 140, 150), WHITE, 4)
		box(m, V(1.2, 0.8, 6), V(-9.6, 2.7, 0), rgb(130, 140, 150))
		for _, z in ipairs({ -3, 3 }) do
			box(m, V(0.3, 0.3, 0.1), V(-9.8, 2.8, z - 0.05 * z), BLACK)
		end
		return 18
	end
	builders["Whale Shark"] = function(m)
		swimmer(m, 24, 5.6, rgb(70, 90, 115), rgb(225, 228, 232), 3)
		for i = 1, 18 do
			box(m, V(0.4, 0.4, 5.2), V(-9 + (i * 41 % 180) / 10, 5 + (i * 23 % 25) / 10, 0), WHITE)
		end
		box(m, V(0.6, 0.8, 4), V(-14, 3.6, 0), rgb(40, 50, 65)) -- wide mouth
		return 24
	end
	builders["Giant Manta Ray"] = function(m)
		local back, belly = rgb(40, 45, 60), rgb(225, 228, 232)
		local measure = flyer(m, { span = 28, bodyL = 9, bodyW = 6, color = back, wing = back, tip = rgb(55, 60, 75), chord = 7, tipChord = 3, sweep = -2.4, head = 2, tail = { 6, 0.4 } })
		for _, s in ipairs({ -1, 1 }) do
			box(m, V(0.9, 2.6, 0.5), V(s * 1.6, 17.2, -0.2), back) -- head fins
			ell(m, V(2.4, 3, 0.2), V(s * 1.6, 12.4, -2.3), belly) -- pale shoulder patches
		end
		return measure
	end
	builders["Swordfish"] = function(m)
		swimmer(m, 10, 2, rgb(70, 80, 120), rgb(200, 205, 215), 2.2)
		beam(m, V(-5.2, 1.5, 0), V(-11, 1.6, 0), 0.25, rgb(70, 80, 120))
		return 16.5
	end
	builders["Clownfish"] = function(m)
		swimmer(m, 4, 1.8, rgb(250, 120, 30), rgb(250, 140, 50), 0.8)
		for _, x in ipairs({ -1.4, 0, 1.3 }) do
			box(m, V(0.35, 1.9, 1.75), V(x, 1.45, 0), WHITE)
		end
		return 4
	end
	builders["Goldfish"] = function(m)
		swimmer(m, 4, 2, rgb(250, 150, 40), rgb(255, 190, 90), 1)
		for _, a in ipairs({ 0.5, -0.5 }) do
			ell(m, V(2.4, 1.2, 0.15), CFrame.new(2.8, 1.8, 0) * CFrame.Angles(0, 0, a), rgb(255, 170, 70))
		end
		return 4.5
	end
	builders["Atlantic Bluefin Tuna"] = function(m)
		swimmer(m, 12, 3.2, rgb(30, 50, 100), rgb(210, 215, 225), 1.6)
		for i = 0, 5 do
			box(m, V(0.35, 0.35, 0.8), V(1 + i * 0.6, 1.6, 0), rgb(250, 210, 40))
		end
		return 12
	end
	builders["Atlantic Salmon"] = function(m)
		swimmer(m, 8, 1.8, rgb(140, 155, 170), rgb(240, 200, 195), 1)
		for i = 1, 8 do
			box(m, V(0.2, 0.2, 1.65), V(-2.5 + i * 0.6, 1.8 + (i % 2) * 0.2, 0), BLACK)
		end
		return 8
	end
	builders["Common Octopus"] = function(m)
		local red = rgb(210, 100, 80)
		ell(m, V(3.6, 4, 3.2), V(0.6, 6, 0), red)
		ell(m, V(2.6, 2, 2.6), V(0, 3.6, 0), red)
		for _, s in ipairs({ -1, 1 }) do
			ball(m, 0.7, V(-1.2, 3.9, s * 0.8), rgb(250, 230, 150))
		end
		for i = 1, 8 do
			local x = -1 + 2 * (i - 1) / 7
			local z = (i % 2 == 0) and 0.6 or -0.6
			local mid = V(x * 2.6, 1.6, z)
			local tip = V(x * 5.2, 0.4 + (i % 2) * 0.5, z * 1.5)
			taper(m, V(x * 0.8, 2.8, z * 0.5), mid, 0.5, 0.35, 2, red)
			taper(m, mid, tip, 0.35, 0.1, 2, red)
		end
		return 10.4
	end
	builders["Giant Squid"] = function(m)
		local red = rgb(200, 90, 75)
		ell(m, V(10, 2.6, 2.6), V(5, 1.6, 0), red)
		Kit.wedge(m, V(0.2, 2.2, 2.4), CFrame.new(9.4, 2.6, 0) * CFrame.Angles(0, math.pi / 2, 0), red)
		ball(m, 2, V(-0.6, 1.6, 0), red)
		eyes(m, V(-0.6, 1.6, 0), 1, 0.7, rgb(30, 30, 40))
		for i = 1, 8 do
			taper(m, V(-1.4, 1.6 + (i - 4.5) * 0.15, (i - 4.5) * 0.15), V(-7, 1.6 + (i - 4.5) * 0.4, (i - 4.5) * 0.3), 0.25, 0.08, 3, red)
		end
		for _, s in ipairs({ -1, 1 }) do
			taper(m, V(-1.4, 1.6, s * 0.3), V(-13, 1.6 + s * 0.7, s * 0.5), 0.12, 0.05, 4, red)
			ell(m, V(1.4, 0.5, 0.5), V(-13.4, 1.6 + s * 0.7, s * 0.5), red)
		end
		return 24
	end
	builders["Moon Jellyfish"] = function(m)
		local jelly = rgb(200, 210, 255)
		local bell = ell(m, V(6, 3, 6), V(0, 7, 0), jelly)
		bell.Transparency = 0.25
		for i = 0, 3 do
			ell(m, V(0.9, 0.9, 0.6), V(-1.6 + i * 1.05, 7, -1.6), rgb(240, 160, 220))
		end
		for i = -5, 5 do
			rod(m, V(i * 0.55, 5.6, 0), V(i * 0.6 + math.sin(i) * 0.4, 0.4, 0), 0.06, jelly)
		end
		return 6
	end
	builders["Seahorse"] = function(m)
		local yellow = rgb(240, 180, 60)
		taper(m, V(0.8, 5, 0), V(0.6, 2.4, 0), 0.9, 0.7, 3, yellow)
		ell(m, V(1.6, 2.4, 1.2), V(0.4, 3.6, 0), yellow)
		ball(m, 1.2, V(0.8, 5.6, 0), yellow)
		beam(m, V(0.3, 5.6, 0), V(-1, 5.3, 0), 0.4, yellow)
		eyes(m, V(0.8, 5.6, 0), 0.6, 0.25)
		for i = 0, 5 do
			local a = i * 0.9
			local p = V(0.8 + math.sin(a) * 0.7 * (1 - i / 7), 2.2 - i * 0.35, 0)
			ball(m, 0.6 - i * 0.07, p, yellow)
		end
		box(m, V(0.2, 0.9, 0.6), V(1.3, 3.8, 0), rgb(250, 220, 140)) -- fin
		return 6.2
	end
	builders["Common Starfish"] = function(m)
		local orange = rgb(240, 110, 50)
		ball(m, 1.4, V(0, 0.5, 0), orange)
		for i = 0, 4 do
			local a = math.rad(i * 72)
			taper(m, V(0, 0.4, 0), V(math.cos(a) * 3, 0.2, math.sin(a) * 3), 0.6, 0.15, 3, orange)
		end
		return 6
	end
	builders["American Lobster"] = function(m)
		local red = rgb(190, 60, 40)
		local measure = insect(m, { len = 6, h = 1.4, legH = 0.5, color = red, headFrac = 0.18, thoraxFrac = 0.35, legColor = red, antenna = 4 })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(-2, 1, s * 0.6), V(-3.4, 1.3, s * 1.2), 0.35, red)
			ell(m, V(2.4, 1.1, 0.9), V(-4.4, 1.4, s * 1.3), red)
		end
		ell(m, V(1.4, 0.3, 2.2), V(3.4, 1.2, 0), red) -- tail fan
		return measure
	end
	builders["Japanese Spider Crab"] = function(m)
		local orange = rgb(220, 110, 60)
		local measure = legs(m, { body = 3, h = 2, legH = 2.4, reach = 15, legT = 0.18, color = orange, pairs = 4, legColor = rgb(235, 140, 90) })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(-1.2, 3.2, s * 0.6), V(-4, 2.6, s * 1.2), 0.25, orange)
		end
		return measure
	end
	builders["Green Sea Turtle"] = function(m)
		return turtle(m, { r = 4, shell = rgb(110, 115, 70), skin = rgb(140, 150, 110), under = rgb(220, 210, 160), pattern = rgb(90, 80, 50), flippers = true, legH = 0.8 })
	end
	builders["Megalodon"] = function(m)
		swimmer(m, 30, 8, rgb(105, 115, 130), WHITE, 6)
		for i = 0, 5 do
			box(m, V(0.5, 0.8, 0.4), V(-16 + i * 0.8, 4.8, -3.4), WHITE)
		end
		return 30
	end

	--======================================================================
	-- Reptiles and amphibians
	--======================================================================
	builders["Komodo Dragon"] = function(m)
		return lizard(m, { len = 5, h = 1.6, legH = 1, w = 1.8, tail = 5, head = { 2, 1.1 }, color = rgb(110, 105, 85), belly = rgb(150, 140, 110) })
	end
	builders["Green Anaconda"] = function(m)
		return snake(m, { len = 30, thick = 1.6, color = rgb(85, 100, 50), pattern = rgb(40, 40, 30) })
	end
	builders["King Cobra"] = function(m)
		return snake(m, { len = 20, thick = 0.9, color = rgb(110, 95, 50), pattern = rgb(220, 200, 120), rise = 4.4, hood = rgb(130, 110, 60) })
	end
	builders["Rattlesnake"] = function(m)
		return snake(m, { len = 12, thick = 0.9, color = rgb(180, 150, 100), pattern = rgb(110, 85, 55), rise = 1, rattle = rgb(220, 200, 160) })
	end
	builders["Green Iguana"] = function(m)
		return lizard(m, { len = 3.6, h = 1.4, legH = 0.8, w = 1.4, tail = 7, head = { 1.6, 1.2 }, color = rgb(90, 170, 70), spikes = rgb(70, 130, 55), tailColor = rgb(80, 140, 60) })
	end
	builders["Panther Chameleon"] = function(m)
		local measure = lizard(m, { len = 3, h = 1.8, legH = 0.6, w = 1, tail = 2.6, head = { 1.4, 1.4 }, color = rgb(60, 160, 200), belly = rgb(240, 200, 60), eye = rgb(240, 140, 40) })
		box(m, V(0.7, 0.7, 0.6), V(-1.8, 2.3, 0), rgb(60, 160, 200)) -- helmet crest
		ball(m, 1.2, V(3.4, 0.7, 0), rgb(60, 160, 200)) -- curled tail
		return measure
	end
	builders["Leopard Gecko"] = function(m)
		local measure = lizard(m, { len = 3.2, h = 1, legH = 0.6, w = 1.1, tail = 2.6, head = { 1.4, 0.9 }, color = rgb(240, 210, 80), belly = rgb(250, 240, 210) })
		for i = 1, 8 do
			box(m, V(0.25, 0.25, 1.15), V(-1.4 + i * 0.5, 1.3 + (i % 2) * 0.2, 0), rgb(60, 50, 40))
		end
		return measure
	end
	builders["American Alligator"] = function(m)
		return lizard(m, { len = 7, h = 1.8, legH = 0.8, w = 3, tail = 8, head = { 4, 1.1 }, color = rgb(55, 65, 45), belly = rgb(190, 185, 150), spikes = rgb(45, 55, 38) })
	end
	builders["Eastern Box Turtle"] = function(m)
		return turtle(m, { r = 3, shell = rgb(120, 85, 40), skin = rgb(100, 90, 70), under = rgb(190, 160, 90), pattern = rgb(240, 190, 60) })
	end
	builders["Axolotl"] = function(m)
		local pink = rgb(250, 175, 190)
		local measure = lizard(m, { len = 3.4, h = 1.4, legH = 0.6, w = 1.4, tail = 3, head = { 1.8, 1.4 }, color = pink, eye = BLACK })
		for _, s in ipairs({ -1, 1 }) do
			for i = 0, 2 do
				beam(m, V(-2.6, 1.6 + i * 0.35, s * 0.6), V(-2 + i * 0.1, 2.4 + i * 0.5, s * 1.5), 0.2, rgb(240, 90, 130))
			end
		end
		return measure
	end
	builders["Strawberry Poison Frog"] = function(m)
		local measure = frog(m, 1, rgb(220, 30, 40), rgb(40, 70, 170))
		for i = 0, 4 do
			box(m, V(0.3, 0.3, 2.65), V(-1 + i * 0.5, 1.4 + (i % 2) * 0.4, 0), BLACK)
		end
		return measure
	end
	builders["American Bullfrog"] = function(m)
		return frog(m, 1.3, rgb(100, 130, 60), rgb(80, 105, 50))
	end

	--======================================================================
	-- Bugs and other small creatures
	--======================================================================
	builders["Honeybee"] = function(m)
		return insect(m, { len = 4, h = 1.6, color = rgb(240, 180, 40), abdomen = rgb(240, 180, 40), stripes = BLACK, wings = rgb(220, 235, 245), wingLen = 2.4, abdomenLift = -0.1 })
	end
	builders["Ladybug"] = function(m)
		local measure = insect(m, { len = 3, h = 1.6, legH = 0.4, color = BLACK, headFrac = 0.22, thoraxFrac = 0.18, abdomen = rgb(220, 30, 30) })
		for i = 1, 5 do
			box(m, V(0.35, 0.35, 1.55), V(-0.2 + (i % 3) * 0.6, 1.5 + (i % 2) * 0.45, 0), BLACK)
		end
		return measure
	end
	builders["Monarch Butterfly"] = function(m)
		local orange = rgb(240, 130, 30)
		ell(m, V(0.5, 3.4, 0.5), V(0, 4, 0), BLACK)
		ball(m, 0.6, V(0, 5.9, 0), BLACK)
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(4.6, 3.4, 0.1), CFrame.new(s * 2.4, 5.2, 0.05) * CFrame.Angles(0, 0, s * 0.35), orange)
			ell(m, V(3.6, 2.8, 0.1), CFrame.new(s * 1.8, 2.8, 0.05) * CFrame.Angles(0, 0, -s * 0.3), orange)
			ell(m, V(4.8, 0.4, 0.12), CFrame.new(s * 2.4, 6.4, 0.02) * CFrame.Angles(0, 0, s * 0.35), BLACK)
			for i = 1, 3 do
				ball(m, 0.3, V(s * (1.6 + i * 1.1), 6.2 - i * 0.2, -0.05), WHITE)
			end
			rod(m, V(s * 0.1, 6.2, 0), V(s * 0.9, 7.6, 0), 0.05, BLACK)
		end
		return 9.6
	end
	builders["Black Garden Ant"] = function(m)
		return insect(m, { len = 4, h = 1, legH = 0.8, color = BLACK, headFrac = 0.25, thoraxFrac = 0.3, abdomen = rgb(40, 35, 35) })
	end
	builders["Goliath Birdeater"] = function(m)
		local brown = rgb(110, 75, 55)
		return legs(m, { body = 2.4, h = 1.6, legH = 1.6, reach = 3.6, legT = 0.3, color = brown, pairs = 4, abdomen = { 2.8, 2.2 }, eyeColor = rgb(20, 20, 20) })
	end
	builders["Emperor Scorpion"] = function(m)
		local black = rgb(30, 30, 40)
		local measure = insect(m, { len = 5, h = 1, legH = 0.6, color = black, headFrac = 0.2, thoraxFrac = 0.35, legColor = black, antenna = 0.1 })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(-2.4, 1, s * 0.5), V(-3.4, 1.1, s * 1.2), 0.3, black)
			ell(m, V(1.6, 0.8, 0.8), V(-4.2, 1.2, s * 1.2), black)
		end
		local p = V(2.5, 1.1, 0)
		for i = 1, 5 do
			local a = math.rad(20 + i * 30)
			local q2 = p + V(math.cos(a) * 0.9, math.sin(a) * 0.9, 0)
			rod(m, p, q2, 0.25, black)
			p = q2
		end
		ball(m, 0.5, p, rgb(140, 90, 40))
		return measure
	end
	builders["Praying Mantis"] = function(m)
		local green = rgb(120, 190, 80)
		local measure = insect(m, { len = 6, h = 0.8, legH = 1.2, color = green, headFrac = 0.1, thoraxFrac = 0.35, legColor = green, wings = rgb(150, 210, 110), wingLen = 2.6, antenna = 1.5 })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(-1.8, 2, s * 0.3), V(-2.6, 3, s * 0.5), 0.2, green)
			beam(m, V(-2.6, 3, s * 0.5), V(-2.6, 2.2, s * 0.5), 0.2, green)
		end
		ell(m, V(0.6, 0.8, 1), V(-3.2, 2.3, 0), green)
		return measure
	end
	builders["Emperor Dragonfly"] = function(m)
		local blue = rgb(60, 140, 220)
		local measure = insect(m, { len = 8, h = 0.7, legH = 0.6, color = rgb(90, 160, 90), headFrac = 0.1, thoraxFrac = 0.15, abdomen = blue, eyeColor = rgb(80, 180, 120), antenna = 0.2 })
		for _, s in ipairs({ -1, 1 }) do
			for _, dx in ipairs({ -0.3, 0.5 }) do
				ell(m, V(1, 4, 0.06), CFrame.new(-2.4 + dx * 1.6, 3, s * 0.3) * CFrame.Angles(0, 0, dx * 0.4), rgb(210, 230, 240)).Transparency = 0.3
			end
		end
		return measure
	end
	builders["Garden Snail"] = function(m)
		local skin = rgb(170, 150, 120)
		ell(m, V(5, 0.8, 1.2), V(0, 0.4, 0), skin)
		beam(m, V(-2, 0.4, 0), V(-2.6, 1.6, 0), 0.6, skin)
		for _, z in ipairs({ -0.2, 0.2 }) do
			rod(m, V(-2.6, 1.6, z), V(-2.9, 2.6, z * 2), 0.06, skin)
			ball(m, 0.2, V(-2.9, 2.6, z * 2), BLACK)
		end
		ball(m, 3, V(0.4, 2.1, 0), rgb(150, 100, 50))
		ball(m, 2, V(0.2, 2.2, -0.6), rgb(180, 130, 70))
		ball(m, 1, V(0.1, 2.3, -1.1), rgb(150, 100, 50))
		return 5
	end
	builders["Earthworm"] = function(m)
		return snake(m, { len = 10, thick = 0.5, color = rgb(210, 130, 130), pattern = rgb(190, 110, 115), headColor = rgb(220, 140, 140) })
	end
	builders["Atlas Moth"] = function(m)
		local rust = rgb(170, 70, 40)
		ell(m, V(0.8, 3, 0.8), V(0, 4.4, 0), rgb(140, 60, 40))
		for _, s in ipairs({ -1, 1 }) do
			ell(m, V(6, 4.2, 0.1), CFrame.new(s * 3, 5.6, 0.05) * CFrame.Angles(0, 0, s * 0.2), rust)
			ell(m, V(4.6, 3.6, 0.1), CFrame.new(s * 2.2, 2.8, 0.05) * CFrame.Angles(0, 0, -s * 0.3), rgb(150, 60, 35))
			ell(m, V(1.2, 0.8, 0.12), V(s * 3, 5.6, 0), rgb(250, 240, 220))
			ell(m, V(1.4, 1.6, 0.12), V(s * 5.6, 6.8, 0), rgb(240, 200, 120)) -- snake-head wing tips
			rod(m, V(s * 0.2, 5.8, 0), V(s * 1, 7, 0), 0.15, rgb(200, 150, 90))
		end
		return 12
	end
	builders["Hercules Beetle"] = function(m)
		insect(m, { len = 6, h = 2, legH = 0.8, color = BLACK, headFrac = 0.15, thoraxFrac = 0.25, abdomen = rgb(180, 160, 90) })
		beam(m, V(-1.6, 3.2, 0), V(-5, 3.4, 0), 0.4, BLACK) -- upper horn
		beam(m, V(-2.6, 2, 0), V(-4.6, 2.6, 0), 0.3, BLACK) -- lower horn
		return 8
	end
	builders["Grasshopper"] = function(m)
		local green = rgb(130, 180, 60)
		local measure = insect(m, { len = 5, h = 1.1, legH = 0.6, color = green, headFrac = 0.18, thoraxFrac = 0.3, legColor = rgb(110, 150, 50), wings = rgb(150, 170, 90), wingLen = 2.6, antenna = 2 })
		for _, s in ipairs({ -1, 1 }) do
			beam(m, V(0, 1.4, s * 0.5), V(1.6, 2.6, s * 0.6), 0.3, green)
			beam(m, V(1.6, 2.6, s * 0.6), V(2.4, 0.1, s * 0.6), 0.2, green)
		end
		return measure
	end

	--======================================================================
	-- Dinosaurs
	--======================================================================
	builders["Triceratops"] = function(m)
		local o = { len = 9, bodyH = 4.4, legH = 2.8, width = 4, color = rgb(150, 120, 80), headLen = 3.6, headH = 2.8, neck = -0.4, ear = { 0.1, 0.1 }, tail = 5 }
		quad(m, o)
		local hx, hy = quadHead(o)
		box(m, V(0.8, 4.6, 4.6), V(hx + 2, hy + 1.6, 0), rgb(175, 110, 70)) -- frill
		for _, z in ipairs({ -0.8, 0.8 }) do
			beam(m, V(hx, hy + 1.2, z), V(hx - 2.4, hy + 3, z), 0.35, rgb(240, 230, 200))
		end
		beam(m, V(hx - 1.4, hy + 0.4, 0), V(hx - 2, hy + 1.4, 0), 0.4, rgb(240, 230, 200))
		local head = hx - o.headLen / 2 - 0.4
		return (o.len / 2 + o.tail * 0.7) - head
	end
	builders["Stegosaurus"] = function(m)
		local o = { len = 9, bodyH = 4.4, legH = 3.4, width = 3.4, color = rgb(120, 140, 80), headLen = 2, headH = 1.4, neck = -2.2, ear = { 0.1, 0.1 }, tail = 6 }
		quad(m, o)
		for i = -3, 3 do
			local h = 2.6 - math.abs(i) * 0.4
			Kit.peak(m, i * 1.2, 7.8, 0, 0.6, h, 0.4, rgb(200, 110, 70))
		end
		for _, z in ipairs({ -0.4, 0.4 }) do
			beam(m, V(8, 5.4, z), V(9.2, 6.4, z * 3), 0.25, rgb(235, 225, 195))
		end
		local hx = quadHead(o)
		return (o.len / 2 + o.tail * 0.7 + 0.6) - (hx - o.headLen / 2)
	end
	builders["Brachiosaurus"] = function(m)
		local o = { len = 10, bodyH = 5, legH = 6.4, width = 4, color = rgb(120, 140, 120), headLen = 2.4, headH = 1.6, neck = 10, ear = { 0.1, 0.1 }, tail = 6 }
		quad(m, o)
		local _, hy = quadHead(o)
		return hy + o.headH / 2 + 0.2
	end
	builders["Velociraptor"] = function(m)
		local measure = theropod(m, { len = 4, h = 2, color = rgb(160, 120, 80), belly = rgb(215, 190, 150), head = { 1.6, 0.8 }, tail = 4.4, arms = true })
		for i = 0, 3 do
			box(m, V(0.3, 0.6, 0.6), V(-1.2 + i * 0.8, 3.6, 0), rgb(110, 70, 50)) -- feathers
		end
		return measure
	end
	builders["Spinosaurus"] = function(m)
		return theropod(m, { len = 12, h = 6, color = rgb(110, 110, 90), belly = rgb(190, 180, 150), head = { 5, 1.6 }, tail = 12, arms = true, sail = 5, sailColor = rgb(190, 90, 70) })
	end
	builders["Pteranodon"] = function(m)
		local measure = flyer(m, { span = 24, bodyL = 4, bodyW = 1.8, color = rgb(200, 170, 130), wing = rgb(150, 110, 80), chord = 3.4, tipChord = 1.6, sweep = 1, head = 1.4, beak = { 3.4, rgb(220, 200, 160) } })
		beam(m, V(0, 5.4, 0), V(0, 3.8, 0.3), 0.4, rgb(200, 90, 60)) -- crest behind the head
		return measure
	end
end
