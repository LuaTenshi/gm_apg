--[[------------------------------------------

	============================
		TOOLS MODULE
	============================

	Developer informations :
	---------------------------------
	Used variables :

]]--------------------------------------------
local mod = "tools"

function APG.canTool( ply, tool, ent )
	if IsValid(ent) then
		if ent.ToolDisabled == false then
			return false
		end

		if ent.CPPICanTool then
			return ent:CPPICanTool(ply, tool)
		end -- Let CPPI handle things from here.

	end

	if APG.cfg[ "checkCanTool" ].value and ply.APG_CantPickup == true then-- If we can't pickup we can't tool either.
		return false
	end

	return 0 -- return 0 so if all of the check's don't return anything then it doesn't default to disabling toolgun.
end

--[[--------------------
	APG CanTool Check
]]----------------------

APG.hookAdd(mod, "CanTool", "APG_ToolMain", function(ply, tr, tool)
	if not APG.canTool(ply, tool, tr.Entity) then
		return false
	end
end)

--[[--------------------
	Tool Spam Control
]]----------------------

APG.hookAdd(mod, "CanTool", "APG_ToolSpamControl", function(ply)
	if not APG.cfg[ "blockToolSpam" ].value then return end
	ply.APG_ToolCTRL = ply.APG_ToolCTRL or {}

	local ply = ply.APG_ToolCTRL
	ply.curTime = CurTime()
	ply.toolDelay = ply.toolDelay or 0
	ply.toolUseTimes = ply.toolUseTimes or 0

	if ply.curTime > ply.toolDelay then
		ply.toolUseTimes = ply.toolUseTimes - 1
		if ply.toolUseTimes < 0 or ply.curTime > ply.toolDelay + 2 then
			ply.toolUseTimes = 0
		end
	else
		ply.toolUseTimes = ply.toolUseTimes + 1
		if ply.toolUseTimes > APG.cfg[ "blockToolRate" ].value then
			return false
		end
	end

	ply.toolDelay = ply.curTime + 1
end)

--[[--------------------
	Block Tool World
]]----------------------

APG.hookAdd(mod, "CanTool", "APG_ToolWorldControl", function(ply, tr)
	if not APG.cfg[ "blockToolWorld" ].value then return end
	if tr.HitWorld and not tr.Entity then
		return false
	end
end)

--[[--------------------
	Block Tool Unfreeze
]]----------------------

APG.hookAdd(mod, "CanTool", "APG_ToolUnfreezeControl", function(ply, tr)
	if not APG.cfg[ "blockToolUnfreeze" ].value then return end
	
	timer.Simple(0.003, function()
		local ent = tr.Entity
		local phys = NULL

		if IsValid(ent) then
			phys = ent:GetPhysicsObject()
			if IsValid(phys) and phys:IsMotionEnabled() then
				phys:EnableMotion( false )
			end
		end
	end)
end)

--[[------------------------------------------
		Load hooks and timers
]]--------------------------------------------

APG.updateHooks(mod)
APG.updateTimers(mod)
