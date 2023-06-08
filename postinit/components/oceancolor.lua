IAENV = env
GLOBAL.setfenv(1, GLOBAL)

local OceanColor = require("components/oceancolor")

function OceanColor:SetVoid()
	self.inst:StopWallUpdatingComponent(self)
	TheWorld.Map:SetClearColor(0,0,0,0)
	TheWorld.Map:SetOceanTextureBlendAmount(0)
end

function OceanColor:ClearVoid()
	self.inst:StartWallUpdatingComponent(self)
	TheWorld.Map:SetClearColor(self.current_color[1], self.current_color[2], self.current_color[3], self.current_color[4])
	TheWorld.Map:SetOceanTextureBlendAmount(self.current_ocean_texture_blend)
end