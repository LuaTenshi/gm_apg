--[[------------------------------------------

	============================
			MISC2 MODULE
	============================

]]--------------------------------------------
local mod = "misc2"

local function getPhys(ent)
	local phys = IsValid(ent) and ent.GetPhysicsObject and ent:GetPhysicsObject() or false
	return IsValid(phys) and phys or false
end

APG.hookAdd(mod, "CanTool", "APG_canTool", function(ply, tr, tool)
	if IsValid(tr.Entity) and tr.Entity.APG_Ghosted then
		APG.notification("Cannot use tool on ghosted entity!", ply, 1)
		return false
	end

	if APG.cfg["fadingDoorHook"].value and tool == "fading_door" then
		timer.Simple(0, function()
			if IsValid(tr.Entity) and not tr.Entity:IsPlayer() then
				local ent = tr.Entity



				if not IsValid(ent) then return end
				if not ent.isFadingDoor then return end

				local state = ent.fadeActive

				if state then
					ent:fadeDeactivate()
				end

				ent.oldFadeActivate = ent.oldFadeActivate or ent.fadeActivate
				ent.oldFadeDeactivate = ent.oldFadeDeactivate or ent.fadeDeactivate

				function ent:fadeActivate()
					if hook.Run("APG.FadingDoorToggle", self, true, ply) then return end
					ent:oldFadeActivate()
				end

				function ent:fadeDeactivate()
					if hook.Run("APG.FadingDoorToggle", self, false, ply) then return end
					ent:oldFadeDeactivate()
					ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)
				end

				if state then
					ent:fadeActivate()
				end
			end
		end)
	end
end)

APG.hookAdd(mod, "APG.FadingDoorToggle", "init", function(ent, state, ply)
	if ent.APG_Ghosted then
		APG.entUnGhost(ent, ply, "Your fading door is ghosted! (" .. ( ent.GetModel and ent:GetModel() or "???" ) .. ")")
		return true
	end

	ent:ForcePlayerDrop()

	local phys = getPhys(ent)
	if phys then
		phys:EnableMotion(false)
	end
end)

--[[ FRZR9K ]]--

local zero = Vector(0,0,0)
local pstop = FrameTime() * 3

APG.timerAdd(mod, "frzr9k", pstop, 0, function()
	if APG.cfg["sleepyPhys"].value then
		for _,v in next, ents.GetAll() do
			local phys = getPhys(v)
			if IsValid(phys) and phys:IsMotionEnabled() and not v:IsPlayerHolding() then
				local vel = v:GetVelocity()
				if vel:Distance(zero) <= 23 then
					phys:Sleep()
				end
			end
		end
	end
end)

-- Collision Monitoring --
local function collcall(ent, data)
	local hit = data.HitObject
	local mep = data.PhysObject

	if IsValid(ent) and IsValid(hit) and IsValid(mep) then
		ent["frzr9k"] = ent["frzr9k"] or {}

		local obj = ent["frzr9k"]

		obj.Collisions = (obj.Collisions or 0) + 1

		obj.CollisionTime = obj.CollisionTime or (CurTime() + 5)
		obj.LastCollision = CurTime()

		if obj.Collisions > 23 then
			obj.Collisions = 0
			for _,e in next, {mep, hit} do
			e:SetVelocityInstantaneous(Vector(0,0,0))
			e:Sleep()
			end
		end

		if obj.CollisionTime < obj.LastCollision then
			local subtract = 1
			local mem = obj.CollisionTime

			while true do
			mem = mem + 5
			subtract = subtract + 1
			if mem >= obj.LastCollision then
				break
			end
			end

			obj.Collisions = (obj.Collisions - subtract)
			obj.Collisions = (obj.Collisions > 1) and obj.Collisions or 1

			obj.CollisionTime = (CurTime() + 5)
		end

		ent["frzr9k"] = obj
	end
end

APG.hookAdd(mod, "OnEntityCreated", "frzr9k", function(ent)
	if APG.cfg["sleepyPhys"].value and APG.cfg["sleepyPhysHook"].value then
		timer.Simple(0.1, function()
			if IsValid(ent) and ent.getPhysicsObject and IsValid(ent:GetPhysicsObject()) then
				ent:AddCallback("PhysicsCollide", collcall)
			end
		end)
	end
end)

--[[------------------------------------------
		Load hooks and timers
]]--------------------------------------------

APG.updateHooks(mod)
APG.updateTimers(mod)
