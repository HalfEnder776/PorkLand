local assets =
{
    Asset("ANIM", "anim/hermitcrab_home.zip"),
}

local _str_to_type = {
    exit = 1,
    
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("hermitcrab_home")
    inst.AnimState:SetBuild("hermitcrab_home")
    inst.AnimState:PlayAnimation("idle_stage4", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("interiordoor")

    return inst
end

return Prefab("debug_door", fn, assets)
