--[[------------------------------------------

    A.P.G. - a lightweight Anti Prop Griefing solution (v{{ script_version_name }})
    Made by :
    - While True (http://steamcommunity.com/id/76561197972967270)
    - LuaTenshi (http://steamcommunity.com/id/76561198096713277)

    Licensed to : http://steamcommunity.com/id/{{ user_id }}

    ============================
       STACK DETECTION MODULE
    ============================

    Developper informations :
    ---------------------------------
    Used variables :
        stackMax = { value = 20, desc = "Max amount of entities stacked on a small area"}
        stackArea = { value = 15, desc = "Sphere radius for stack detection (gmod units)"}

]]--------------------------------------------
local mod = "stack_detection"

function APG.checkStack( ent, pcount )
    if not APG.isBadEnt( ent ) then return end

    local efound = ents.FindInSphere(ent:GetPos(), APG.cfg["stackArea"].value )
    local count = 0
    local max_count = APG.cfg["stackMax"].value
    for k, v in pairs (efound) do
        if APG.isBadEnt( v ) and APG.getOwner( v ) then
            count = count + 1
        end
    end
    if count >= (pcount or max_count) then
        local owner, _ = ent:CPPIGetOwner()
        ent:Remove()
        if not owner.APG_CantPickup then
            APG.blockPickup( owner )
            APG.notify("Do not try to crash the server!", ply, 1)

            local msg = owner:Nick().." ["..owner:SteamID().."]" .. " tried to unfreeze a stack of props!"
            APG.notify(msg, "admins", 2)
        end
    end
end

APG.hookRegister(mod, "PhysgunPickup","APG_stackCheck",function(ply, ent)
    if not APG.canPhysGun( ent, ply ) then return end
    if not APG.modules[ mod ] or not APG.isBadEnt( ent ) then return end
    APG.checkStack( ent )
end)

--[[--------------------
    Stacker Exploit Quick Fix
]]----------------------
hook.Add( "InitPostEntity", "APG_InitStackFix", function()
    timer.Simple(60, function()
        local TOOL = weapons.GetStored("gmod_tool")["Tool"][ "stacker" ] or weapons.GetStored("gmod_tool")["Tool"][ "stacker_v2" ]
        if not TOOL then return end

        -- Stacker improved (beta) fixed this by setting a maximum number of constraints
        -- See : https://git.io/vPvJK

        APG.dJobRegister( "weld", 0.3, 20, function( sents )
            if not IsValid( sents[1] ) or not IsValid( sents[2]) then return end
            constraint.Weld( sents[1], sents[2], 0, 0, 0 )
        end)

        function TOOL:ApplyWeld( lastEnt, newEnt )
            if ( not self:ShouldForceWeld() and not self:ShouldApplyWeld() ) then return end
            APG.startDJob( "weld", {lastEnt, newEnt} )
        end
    end)
end)

--[[------------------------------------------
        Load hooks and timers
]]--------------------------------------------
for k, v in next, APG[mod]["hooks"] do
    hook.Add( v.event, v.identifier, v.func )
end

for k, v in next, APG[mod]["timers"] do
    timer.Create( v.identifier, v.delay, v.repetitions, v.func )
end