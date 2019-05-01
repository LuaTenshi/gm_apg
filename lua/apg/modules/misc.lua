--[[------------------------------------------

	============================
		MISCELLANEOUS MODULE
	============================

	Developer informations :
	---------------------------------
	Used variables :
		vehDamage = { value = true, desc = "True to enable vehicles damages, false to disable." }
		vehNoCollide = { value = false, desc = "True to disable collisions between vehicles and players"}
		autoFreeze = { value = false, desc = "Freeze every unfrozen prop each X seconds" }
		autoFreezeTime = { value = 120, desc = "Auto freeze timer (seconds)"}

]]--------------------------------------------
local mod = "misc"

--[[--------------------
	Vehicle damage
]]----------------------
local function isVehDamage( dmg, atk, ent )
	if not IsValid( ent ) then return false end
	if dmg:GetDamageType() == DMG_VEHICLE or APG.IsVehicle( atk ) or APG.IsVehicle( ent ) then
		return true
	end
	return false
end

--[[--------------------
	No Collide vehicles on spawn
]]----------------------
APG.hookAdd( mod,"OnEntityCreated", "APG_noCollideVeh", function( ent )
	timer.Simple(0.03, function()
		if APG.cfg[ "vehNoCollide" ].value and APG.IsVehicle( ent ) then
			ent:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		end
	end)
end)

--[[--------------------
	Disable prop damage
]]----------------------
APG.hookAdd( mod, "EntityTakeDamage","APG_noPropDmg", function( target, dmg )
	if ( not APG.cfg[ "allowPK" ].value ) then -- Check if prop kill is allowed, before checking anything else.
		local atk, ent = dmg:GetAttacker(), dmg:GetInflictor()
		if APG.isBadEnt( ent ) or dmg:GetDamageType() == DMG_CRUSH or ( APG.cfg[ "vehDamage" ].value and isVehDamage( dmg, atk, ent ) ) then
			dmg:SetDamage(0)
			return true
			-- ^ Returning true overrides and blocks all related damage, it also prevents the hook from running any further preventing unintentional damage from other addons.
		end
	end
end)

--[[--------------------
	Block Physgun Reload
]]----------------------
APG.hookAdd( mod, "OnPhysgunReload", "APG_blockPhysgunReload", function( _, ply )
	if APG.cfg[ "blockPhysgunReload" ].value then
		--APG.notification("Physgun Reloading is Currently Disabled", ply, 1)
		return false
	end
end)

--[[--------------------
	Auto prop freeze
]]----------------------
APG.timerAdd( mod, "APG_autoFreeze", APG.cfg[ "autoFreezeTime" ].value, 0, function()
	if APG.cfg[ "autoFreeze" ].value then
		APG.freezeProps()
	end
end)

--[[------------------------------------------
		Load hooks and timers
]]--------------------------------------------

APG.updateHooks(mod)
APG.updateTimers(mod)
