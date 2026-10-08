--[[
	BodyKit.lua
	ModuleScript: ReplicatedStorage.Models.BodyKit

	Body-shape helpers shared by the animal and record-breaker models:
	four-legged (Kit.quad), bird, flyer (seen from above, wings spread),
	seal, snake, lizard, turtle, insect, many-legged, critter, ape,
	two-legged dinosaur and frog, plus small extras (eyes, spots, antlers,
	trunk, tusks). Side-on builders face -X; each returns its measure.
]]

local Kit = require(script.Parent:WaitForChild("Kit"))
local box, ball, beam, rod, slab, taper = Kit.box, Kit.ball, Kit.beam, Kit.rod, Kit.slab, Kit.taper
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

return {
	ell = ell,
	eyes = eyes,
	spots = spots,
	antlers = antlers,
	quadHead = quadHead,
	bird = bird,
	flyer = flyer,
	seal = seal,
	snake = snake,
	lizard = lizard,
	turtle = turtle,
	insect = insect,
	legs = legs,
	critter = critter,
	ape = ape,
	theropod = theropod,
	frog = frog,
	trunk = trunk,
	tusks = tusks,
}
