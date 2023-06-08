local Widget = require "widgets/widget"
local Image = require "widgets/image"

-- NOTES(JBK): These constants are from MiniMapRenderer ZOOM_CLAMP_MIN and ZOOM_CLAMP_MAX
local ZOOM_CLAMP_MIN = 1
local ZOOM_CLAMP_MAX = 20
local testself

local function Zoom(self, delta)
	self.zoom = math.clamp(self.zoom + delta, ZOOM_CLAMP_MIN, ZOOM_CLAMP_MAX)
	self.maproot:SetScale(1/self.zoom, 1/self.zoom)
end

--[[ (H):
Mapping is not fully accurate to Single Player because of a quirk where here the image is centered in uv, while in DS it's clamped to the corner

fix that with magical goofy lil shader
]]

local InteriorMapWidget = Class(Widget, function(self)
    Widget._ctor(self, "InteriorMapWidget")
	self.owner = ThePlayer

    self.bg = self:AddChild(Image("images/hud.xml", "map.tex"))
    self.bg:SetVRegPoint(ANCHOR_MIDDLE)
    self.bg:SetHRegPoint(ANCHOR_MIDDLE)
    self.bg:SetVAnchor(ANCHOR_MIDDLE)
    self.bg:SetHAnchor(ANCHOR_MIDDLE)
    self.bg:SetScaleMode(SCALEMODE_FILLSCREEN)
	self.bg:SetBlendMode( BLENDMODE.Premultiplied )

	self.centerreticle = self.bg:AddChild(Image("images/hud.xml", "cursor02.tex"))

	self.maproot = self:AddChild(Widget("maproot"))
	self.maproot:SetHAnchor(ANCHOR_MIDDLE)
	self.maproot:SetVAnchor(ANCHOR_MIDDLE)

	self.mapbgs = {}
	self.mapobjects = {}

	local mapdata = self.owner.player_classified.MapExplorer:GetInteriorMapData()
	local currentdungeon = self.owner.player_classified.interior_visual:value().roomgroup:value()
	local currentinterior = self.owner.player_classified.interior_visual:value().roomid:value()
	--TODO(H): allow dungeon to be set! Qol from hamlet be be allowing players to view other interior dungeon maps
	
	--{
		--name = "mini_ruins_slab",
		--length = 15,
		--width = 10,
		--occupied = false,
		--pos = {x = 0, y = 0},
		--objects = {
			--{
				--x and y are percents of the rooms width and length
				--name = "researchlab2",
				--x = .2,
				--y = .5,
			--}
		--}
	--}
	--all of this assumes room texture is 64x64 pixels
	--todo(h): BLENDMODE.Additive needs to be applied to everything, but theres an issue with multiple additive blending widgets overlaying on top of eachother, use shaders....
	--todo(H): order icons properly, augh, MoveToFront and MoveToBack is so silly to use -_-, wish we could just use a simple set sort order and pass in a number
	for k, v in pairs(mapdata[currentdungeon]) do
		local occupied = v.id == currentinterior

		self.mapbgs[k] = self.maproot:AddChild(Image("levels/textures/map_interior/"..v.name..".xml", v.name..".tex"))
		--self.mapbgs[k].frame = self.maproot:AddChild(Image("levels/textures/map_interior/frame.xml", "frame.tex")) --TODO(H): support custom frames?
		--self.mapbgs[k].frame:SetScale(.86, .62) --TODO(H): kinda close (but not yet)
		--self.mapbgs[k].frame:SetBlendMode( BLENDMODE.Additive )
		--self.mapbgs[k].frame:SetPosition(250 * v.pos.x, 200 * v.pos.y)
		self.mapbgs[k]:SetUVMode(WRAP_MODE.WRAP)
		self.mapbgs[k]:SetUVScale(-3 * v.length / 10, -2 * v.width / 10) -- 1, 1 = one repeat, 0, 0 = 2 x 2, -1, -1 = 3 x 3
		self.mapbgs[k]:SetScale(v.length * INTERIOR_MAP_SCALE, v.width * INTERIOR_MAP_SCALE)
		self.mapbgs[k]:SetBlendMode( BLENDMODE.Additive )
		self.mapbgs[k]:MoveToBack()
		if not occupied then
			self.mapbgs[k]:SetTint(.4, .4, .4, 1)
		end

		local pixelLength, pixelWidth = self.mapbgs[k]:GetScaledSize()

		self.mapbgs[k]:SetPosition((pixelLength) * v.pos.x + 81 * v.pos.x, (pixelWidth) * v.pos.y + 81 * v.pos.y)
		--there need to be 81 pixels between each interior length and width wise

		local mapbgpos = self.mapbgs[k]:GetPosition()
		local lengthoffset, widthoffset = -pixelLength/2, -pixelWidth/2

		for i, j in pairs(v.objects) do
			local object = self.maproot:AddChild(Image(GetMiniMapIconAtlas(j.name), j.name))

			object:SetScale(.7, .7)
			object:SetPosition(mapbgpos.x + j.x * (pixelLength) + lengthoffset, mapbgpos.y + j.y * (pixelWidth) + widthoffset)
			--object:SetBlendMode( BLENDMODE.Additive )
			if not occupied then
				object:SetTint(.4, .4, .4, 1)
			end
			--render is not accurate, I think it should have BLENDMODE.Additive but this causes issues overlaying with the bg additive
			--todo(h): eh this implementation will change
			--todo(h): stuff like locked/unknown passage icons

			--40 between each
			if j.doordirection == "west" or j.doordirection == "east" then
				object.arrow = self.maproot:AddChild(Image("levels/textures/map_interior/passage.xml", "passage.tex"))
				object.arrow:SetScale(1.125, 1.1)
				if j.doordirection == "west" then
					object.arrow:SetPosition(mapbgpos.x - pixelLength/2 - 41, 0)
				else
					object.arrow:SetPosition(mapbgpos.x + pixelLength/2 + 41, 0)
				end
			elseif j.doordirection == "north" or j.doordirection == "south" then
				object.arrow = self.maproot:AddChild(Image("levels/textures/map_interior/passage.xml", "passage.tex"))
				object.arrow:SetScale(1.1, 1.125)
				object.arrow:SetRotation(90)
				if j.doordirection == "north" then
					object.arrow:SetPosition(0, mapbgpos.y + pixelWidth/2 + 41)
				else
					object.arrow:SetPosition(0, mapbgpos.x - pixelWidth/2 - 41)
				end
			end

			table.insert(self.mapobjects, object)
		end
	end
	
--[[
	self.testbg = self.maproot:AddChild(Image("levels/textures/map_interior/mini_ruins_slab.xml", "mini_ruins_slab.tex"))
	--self.testbg:SetEffect(resolvefilepath("shaders/map_interior.ksh"))
	self.testbg:SetUVMode(WRAP_MODE.WRAP)
	self.testbg:SetUVScale(-3 * 1.5, -2) -- 1, 1 = one repeat, 0, 0 = 2 x 2, -1, -1 = 3 x 3
	self.testbg:SetScale(1.5 * 1.77, 1 * 1.77) --length and width divided by 10, multiplied by 1.77

	self.testbg2 = self.maproot:AddChild(Image("levels/textures/map_interior/mini_ruins_slab.xml", "mini_ruins_slab.tex"))
	--self.testbg2:SetEffect(resolvefilepath("shaders/map_interior.ksh"))
	self.testbg2:SetUVMode(WRAP_MODE.WRAP)
	self.testbg2:SetUVScale(-3 * 1.5, -2) -- 1, 1 = one repeat, 0, 0 = 2 x 2, -1, -1 = 3 x 3
	self.testbg2:SetScale(1.5 * 1.77, 1 * 1.77)
	self.testbg2:SetPosition(-249, 0) -- 193
	-- 165
	--1.5 * 1.77 * 64 / 2
	--.4, .4, .4, 1 for fog of war
	self.testarrow = self.maproot:AddChild(Image("levels/textures/map_interior/passage.xml", "passage.tex"))
	self.testarrow:SetScale(1.125, 1.1)
	self.testarrow:SetPosition(-200, 0)
	self.testbg:SetBlendMode( BLENDMODE.Additive )
	self.testbg2:SetBlendMode( BLENDMODE.Additive )
	--1.5 * 1.77, 1 * 1.77 (H): 1.77 is le magic number!
	-- -3 * 1.5, -2 (H): i mean, kinda close

	--self.testbg2 = self.maproot:AddChild(Image("images/skilltree.xml", "wilson_background_text.tex"))
]]
    self.minimap = TheWorld.minimap.MiniMap

	self.zoom = 1
	self.lastpos = nil
	self:StartUpdating()

	testself = self
end)

function TestBG()
	return testself.testbg2
end

function TestMapRoot()
	return testself.maproot
end

function TestArrow()
	return testself.testarrow
end

--these need proper implementations for 'toxy boy's ability to function
function InteriorMapWidget:WorldPosToMapPos(x,y,z)
    --return self.minimap:WorldPosToMapPos(x,y,z)
end

function InteriorMapWidget:MapPosToWorldPos(x,y,z)
	--return self.minimap:MapPosToWorldPos(x,y,z)
end

function InteriorMapWidget:SetTextureHandle(handle)
	--self.img.inst.ImageWidget:SetTextureHandle( handle )
end

function InteriorMapWidget:OnZoomIn(negativedelta)
	if self.shown and self:GetZoom() > ZOOM_CLAMP_MIN and self:GetZoom() <= ZOOM_CLAMP_MAX then
		Zoom(self, negativedelta or -.1)
		return true
	end
	return false
end

function InteriorMapWidget:OnZoomOut(positivedelta)
	if self.shown and self:GetZoom() < ZOOM_CLAMP_MAX and self:GetZoom() >= ZOOM_CLAMP_MIN then
		Zoom(self, positivedelta or .1)
		return true
	end
	return false
end

function InteriorMapWidget:GetZoom()
	return self.zoom
end

function InteriorMapWidget:UpdateTexture()
	--local handle = self.minimap:GetTextureHandle()
	--self:SetTextureHandle( handle )
end

function InteriorMapWidget:OnUpdate(dt)

	if not self.shown then return end
	--print("HI, OnUpdate")
	if TheInput:IsControlPressed(CONTROL_PRIMARY) then
		local pos = TheInput:GetScreenPosition()
		if self.lastpos then
			-- NOTES(JBK): The magic constant 9 comes from the scaler in MiniMapRenderer ZOOM_MODIFIER.
			local scale = 2 / 9
			local dx = scale * ( pos.x - self.lastpos.x )
			local dy = scale * ( pos.y - self.lastpos.y )
			self:Offset( dx, dy )
		end

		self.lastpos = pos
	else
		self.lastpos = nil
	end
end

function InteriorMapWidget:Offset(dx,dy)
	dx = dx * 4
	dy = dy * 4
	local pos = self.maproot:GetPosition()
	print("Offset ", dx, dy)
	self.maproot:SetPosition(pos.x + dx, pos.y + dy)
end

function InteriorMapWidget:OnShow()
	--self.minimap:ResetOffset()
end

function InteriorMapWidget:OnHide()
	self.lastpos = nil
end

return InteriorMapWidget