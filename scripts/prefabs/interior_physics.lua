local function SquareMesh(vertices, height)
   local triangles = {}
   local y0 = 0
   local y1 = height

   local idx0 = #vertices
   for idx1 = 1, #vertices do
       local x0, z0 = vertices[idx0].x, vertices[idx0].z
	   local x1, z1 = vertices[idx1].x, vertices[idx1].z

       table.insert(triangles, x0)
       table.insert(triangles, y0)
       table.insert(triangles, z0)

       table.insert(triangles, x0)
       table.insert(triangles, y1)
       table.insert(triangles, z0)

       table.insert(triangles, x1)
       table.insert(triangles, y0)
       table.insert(triangles, z1)

       table.insert(triangles, x1)
       table.insert(triangles, y0)
       table.insert(triangles, z1)

       table.insert(triangles, x0)
       table.insert(triangles, y1)
       table.insert(triangles, z0)

       table.insert(triangles, x1)
       table.insert(triangles, y1)
       table.insert(triangles, z1)

       idx0 = idx1
   end

   return triangles
end

local vertices = {
	Vector3(5, 0, -7.5),
	Vector3(-5, 0, -7.5),
	Vector3(-5, 0, 7.5),
	Vector3(5, 0, 7.5),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    --[[Non-networked entity]]
    inst:AddTag("CLASSIFIED")

    local phys = inst.entity:AddPhysics()
    phys:SetMass(0)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.GROUND)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:CollidesWith(COLLISION.WORLD)
    phys:CollidesWith(COLLISION.ITEMS)
    phys:CollidesWith(COLLISION.FLYERS)
    phys:CollidesWith(COLLISION.SANITY)
    phys:SetTriangleMesh(SquareMesh(vertices, 3))
	phys:SetDontRemoveOnSleep(true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.SetRectangle = function(inst, length, width, height)
		length = length or 15
		width = width or 10
		local vertexes = {
			Vector3((width/2), 0, -(length/2)),
			Vector3(-(width/2), 0, -(length/2)),
			Vector3(-(width/2), 0, (length/2)),
			Vector3((width/2), 0, (length/2)),
		}
		phys:SetTriangleMesh(SquareMesh(vertexes, height or 3))
	end

	inst.persists = false

    return inst
end

return Prefab("interior_physics", fn)