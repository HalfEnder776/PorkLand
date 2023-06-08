local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

----------------------------------------------------------------------------------------



----------------------------------------------------------------------------------------
--Try to initialise all functions locally outside of the post-init so they exist in RAM only once
----------------------------------------------------------------------------------------

IAENV.AddPlayerPostInit(function(inst)
	
    if not TheWorld.ismastersim then
        return
    end

	inst:AddComponent("interiorplayer")
end)

