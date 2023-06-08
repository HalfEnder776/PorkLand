local IAENV = env
GLOBAL.setfenv(1, GLOBAL)

IAENV.AddPrefabPostInit("world", function(inst)

    if not inst.ismastersim then
        return
    end

    inst:AddComponent("interiormanager")
end)