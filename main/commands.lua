GLOBAL.setfenv(1, GLOBAL)

function c_checktile()
    local player = ConsoleCommandPlayer()
    if player then
        local x, y, z = player.Transform:GetLocalPosition()
        local tile = TheWorld.Map:GetTileAtPoint(x, y, z)

        for tile_name, num  in pairs(WORLD_TILES) do
            if tile == num then
                print(tile_name, num)
                break
            end
        end
    end
end

function c_poison()
    local inst = c_select()
    if inst and inst.components.poisonable then
        if inst.components.poisonable:IsPoisoned() then
            inst.components.poisonable:DonePoisoning()
        else
            inst.components.poisonable:Poison()
        end
    end
end


-- house helper commands

function c_createantroom(group, x, y)
	local inst = c_spawn("debug_door")
	local id = CreateAntRoom(group, x, y)
    print("Created ant room with id:", id)
	
	inst.components.interiordoor.targetInteriorID = id
	--inst.components.interiordoor.targetDoor = id
	return inst
end

function c_createpalaceroom(group, x, y)
	local inst = c_spawn("debug_door")
	local id = CreatePalaceRoom(group, x, y)
    print("Created palace room with id:", id)
	
	inst.components.interiordoor.targetInteriorID = id
	--inst.components.interiordoor.targetDoor = id
	return inst
end

function c_createinteriordoor(group, x, y)
	local inst = c_spawn("debug_door")
	local id = CreateInteriorRoom(group, x, y)
    print("Created interior room with id:", id)
	
	inst.components.interiordoor.targetInteriorID = id
	--inst.components.interiordoor.targetDoor = id
	return inst
end

function c_createinteriordoorexit(id)
	local inst = c_spawn("debug_door")
	
	inst.components.interiordoor.targetInteriorID = id
	inst.components.interiordoor.outside = true
	return inst
end

--------------------------------------------------------------------------

local unpack = unpack

--------------------------------------------------------------------------
local ConsoleScreen = require("screens/consolescreen")
local TextEdit = require "widgets/textedit"

local prediction_command = {
    "checktile", "poison", "createantroom",
    "createpalaceroom", "createinteriordoor",
    "createinteriordoorexit"
}

local _DoInit = ConsoleScreen.DoInit
function ConsoleScreen:DoInit(...)
    
    -- Hacky but for some reason I cannot add more commands after the DoInit and cant find out why, neither can Hornet
    local _AddWordPredictionDictionary = TextEdit.AddWordPredictionDictionary
    function TextEdit:AddWordPredictionDictionary(data, ...)
        if data.words and data.delim ~= nil and data.delim == "c_" then
            for k, v in pairs(prediction_command) do
                table.insert(data.words, v)
            end
        end
        
        return _AddWordPredictionDictionary(self, data, ...)
    end

    local rets = {_DoInit(self, ...)}

    TextEdit.AddWordPredictionDictionary = _AddWordPredictionDictionary

    return unpack(rets)
end

