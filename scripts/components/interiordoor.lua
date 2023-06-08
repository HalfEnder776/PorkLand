--(NOTE) Hornet: original component is named 'door' in Hamlette. Changed to 'interiordoor' to make it more intuitive to understand
local InteriorDoor = Class(function(self, inst)
    self.inst = inst
	self.targetInteriorID = nil
	self.targetDoor = nil
end)

function InteriorDoor:Activate(doer)
	--Hornet: 'doer' is assumed to be a player.
	doer:ScreenFade(false, 0.5)
	doer.components.playercontroller:Enable(false)
	
	self.inst:DoTaskInTime(.5, function() --Do this in stategraph instead?
		doer.components.playercontroller:Enable(true)

		if self.outside then
			TheWorld.components.interiormanager:ExitInterior(doer, self.targetInteriorID, self.targetDoor)
		else
			TheWorld.components.interiormanager:EnterInterior(doer, self.targetInteriorID, self.targetDoor)
		end
	end)
end

function InteriorDoor:OnSave()
	local data = {}

	data.targetInteriorID = self.targetInteriorID
	data.targetDoor = self.targetDoor

	return data
end

function InteriorDoor:OnLoad(data)
	if data == nil then return end
	
	self.targetInteriorID = data.targetInteriorID or nil
	self.targetDoor = data.targetDoor or nil
end

return InteriorDoor