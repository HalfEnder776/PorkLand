IAENV = env
GLOBAL.setfenv(1, GLOBAL)

local PlayerVision = require("components/playervision")
local _UpdateCCTable = PlayerVision.UpdateCCTable

function PlayerVision:SetInteriorCCTable(cc)
	if cc == nil then self.interior_cc = nil self:UpdateCCTable() return end

	local INTVISION_COLOURCUBES = { day = resolvefilepath(cc), dusk = resolvefilepath(cc), night = resolvefilepath(cc), full_moon = resolvefilepath(cc) }
	self.interior_cc = INTVISION_COLOURCUBES
	self:UpdateCCTable()
end

function PlayerVision:UpdateCCTable(...)
	_UpdateCCTable(self, ...)

	if self.currentcctable == nil and self.interior_cc then
		self.currentcctable = self.interior_cc
        self.currentccphasefn = nil
        self.inst:PushEvent("ccoverrides", self.interior_cc)
        self.inst:PushEvent("ccphasefn", nil)
	end
end