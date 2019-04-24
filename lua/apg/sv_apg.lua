--[[------------------------------------------

    A.P.G. - a lightweight Anti Prop Griefing solution (v{{ script_version_name }})
    Made by :
    - While True (http://steamcommunity.com/id/76561197972967270)
    - LuaTenshi (http://steamcommunity.com/id/76561198096713277)

    Licensed to : http://steamcommunity.com/id/{{ user_id }}

]]--------------------------------------------

util.AddNetworkString("apg_notice_s2c")
APG = APG or {}

local IsValid = IsValid
local table = table
local isentity = isentity

--[[------------------------------------------
            ENTITY Related
]]--------------------------------------------

function APG.canPhysGun( ent, ply )
    if not IsValid(ent) then return false end -- The entity isn't valid, don't pickup.
    if ply.APG_CantPickup then return false end -- Is APG blocking the pickup?
    if ent.CPPICanPhysgun then return ent:CPPICanPhysgun(ply) end -- Let CPPI handle things from here.

    return not ent.PhysgunDisabled -- By default everything can be picked up, unless it is PhysgunDisabled.
end

function APG.isBadEnt( ent )
    if ent and not ent.GetClass then return false end -- Ignore if we can't read the class.
    if not IsValid(ent) then return false end -- Ignore invalid entities.
    if ent.jailWall == true then return false end -- Ignore ULX jails.
    if Entity(0) == ent or ent:IsWorld() then return false end -- Ignore worldspawn.
    if ent:IsWeapon() then return false end -- Ignore weapons.
    if ent:GetClass() == "player" then return false end -- Ignore players.

    local h = hook.Run("APGisBadEnt", ent)
    if isbool(h) then return h end

    local class = ent:GetClass()
    for k, v in pairs (APG.cfg["bad_ents"].value) do
        if ( v and k == class ) or (not v and string.find( class, k ) ) then
            return true
        end
    end

    return false
end

function APG.getOwner( ent )
    local owner, _ = ent:CPPIGetOwner() or ent.FPPOwner or nil
    return owner
end

local function killvel(phys, freeze)
    local vec = Vector()
    if not IsValid(phys) then return end
    if freeze then phys:EnableMotion(false) return end

    phys:SetVelocity(vec)
    phys:SetVelocityInstantaneous(vec)
    phys:AddAngleVelocity(phys:GetAngleVelocity() * -1)

    phys:Sleep()
end

function APG.killVelocity(ent, extend, freeze, wake_target)
    local vec = Vector()
    if ent.GetClass and ent:GetClass() == "player" then ent:SetVelocity(ent:GetVelocity() * -1) return end
    ent:SetVelocity(vec)

    for i = 0, ent:GetPhysicsObjectCount() do killvel(ent:GetPhysicsObjectNum(i), freeze) end -- Includes self?

    if extend then
        for _,v in next, constraint.GetAllConstrainedEntities(ent) do killvel(v:GetPhysicsObject(), freeze) end
    end

    if wake_target then
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end
end

function APG.freezeIt( ent, extend )
    local obj = ent:GetPhysicsObject()
    if extend then
        for _,v in next, constraint.GetAllConstrainedEntities(ent) do
            killvel(v:GetPhysicsObject(), true)
            v.APG_Frozen = true
        end
    else
        if IsValid(obj) then
            killvel(obj, true)
            ent.APG_Frozen = true
        end
    end
end

function APG.FindWAC(ent)
    if not APG.cfg["vehIncludeWAC"].value then return false end

    local e
    local i = 0
    if ent.wac_seatswitch or ent.wac_ignore then return true end
    for _,v in next, constraint.GetAllConstrainedEntities(ent) do
        if v.wac_seatswitch or v.wac_ignore then e = v break end
        if i > 12 then break end -- Only check up to 12.
        i = i + 1
    end

    return IsValid(e)
end

function APG.IsVehicle(v, basic)
    if not IsValid(v) then return false end

    if v:IsVehicle() then return true end
    if string.find(v:GetClass(), "vehicle") then return true end
    if basic then return false end

    if APG.FindWAC(v) then return true end

    local parent = v:GetParent()
    return APG.IsVehicle(parent, true)
end

function APG.cleanUp( mode, notification, specific )
    mode = mode or "unfrozen"
    for _, v in next, specific or ents.GetAll() do
        APG.killVelocity(v,false)
        if not APG.isBadEnt(v) or not APG.getOwner( v ) or APG.IsVehicle(v) then continue end
        if mode == "unfrozen" and v.APG_Frozen then -- Whether to clean only not frozen ents or all ents
            continue
        else
            v:Remove()
        end
    end
    -- TODO : Fancy notification system
    if notification or APG.cfg["notificationLagFunc"].value then
        APG.userNotification("Cleaned up (mode: " .. mode .. ")", APG.cfg["notificationLevel"].value, 2)
    end
end

function APG.ghostThemAll( notification )
    if not APG.modules[ "ghosting" ] then
        return APG.log("[APG] Warning: Tried to ghost props but ghosting is disabled!")
    end
    for _, v in next, ents.GetAll() do
        if ( not APG.isBadEnt(v) ) or ( not APG.getOwner( v ) ) or APG.IsVehicle(v) or v.APG_Frozen then continue end
        APG.entGhost( v, false, true )
    end
    -- TODO : Fancy notification system
    if notification or APG.cfg["notificationLagFunc"].value then
      APG.userNotification("Unfrozen props ghosted!", APG.cfg["notificationLevel"].value, 1)
    end
end

function APG.freezeProps( notification )
    for _, v in next, ents.GetAll() do
        if not APG.isBadEnt(v) or not APG.getOwner( v ) then continue end
        APG.freezeIt( v )
    end
    -- TODO : Fancy notification system
    if notification or APG.cfg["notificationLagFunc"].value then
      APG.userNotification("Props frozen", APG.cfg["notificationLevel"].value, 0)
    end
end

local function GetPhysenv()
    local env = physenv.GetPerformanceSettings()
    local con = {}
    local vars = {
        "phys_upimpactforcescale",
        "phys_impactforcescale",
        "phys_pushscale",
        "sv_turbophysics",
    }

    for _,v in next, vars do
        local var = GetConVar(v)
        con[v] = var and var:GetString() or nil
    end

    return {con = con, env = env}
end

function APG.smartCleanup( notification )
    local defaults = GetPhysenv()
    local phys = table.Copy(defaults.env)

    hook.Add("PlayerSpawnObject", "APG_smartCleanup", function() return false end)

    RunConsoleCommand("phys_upimpactforcescale","0")
    RunConsoleCommand("phys_impactforcescale",  "0")
    RunConsoleCommand("phys_pushscale",         "0")
    RunConsoleCommand("sv_turbophysics",        "1")

    phys.MaxCollisionChecksPerTimestep = 0
    phys.MaxAngularVelocity = 0
    phys.MaxVelocity = 0
    physenv.SetPerformanceSettings(phys)

    local sphere = ents.FindInSphere
    local all = ents.GetAll()
    local bad = {}

    for _, v in next, all do
        if IsValid(v) and v.GetPhysicsObject then
            local phys = v:GetPhysicsObject()
            if IsValid(phys) and phys:IsMotionEnabled() then
                if v.isFadingDoor and APG.isBadEnt(ent) then
                    SafeRemoveEntity(v)
                else
                    table.insert(bad, {ent = v, phys = phys})
                end
            end
        end
    end

    APG.freezeProps()

    for _, v in next, bad do
        local count = 0

        local owner = APG.getOwner(v.ent)
        local space = sphere(v.ent:GetPos(), 7)
        local cache = {}

        for _, ent in next, space do
            if owner == APG.getOwner(ent) then
                count = count + 1
                table.insert(cache, ent)
            end
        end

        if count > 4 then
            for _, ent in next, cache do
                if APG.isBadEnt(ent) then
                    SafeRemoveEntity(ent)
                end
            end
        end
    end

    timer.Simple(1.5, function() -- Give a few seconds for the engine to catch up.
        for k,v in next, defaults.con do
            RunConsoleCommand(k, v)
        end
        physenv.SetPerformanceSettings(defaults.env)
        hook.Remove("PlayerSpawnObject", "APG_smartCleanup")
    end)
end

function APG.ForcePlayerDrop(ply, ent)
    if IsValid(ply) then
        ply:ConCommand("-attack")
    end
    if IsValid(ent) then
        ent:ForcePlayerDrop()
    end
end

function APG.blockPickup( ply )
    if not IsValid(ply) or ply.APG_CantPickup then return end
    ply.APG_CantPickup = true
    timer.Simple(10, function()
        if IsValid(ply) then
            ply.APG_CantPickup = false
        end
    end)
end

function APG.userNotification(msg, targets, level, log) -- The most advanced notification function in the world.
    if not APG.modules["notification"] then return end
    -- local logged = false -- not used, was there a reason this is here?
    msg = string.Trim(tostring(msg))
    level = level or 0

    if type(level) == "string" then
        level = string.lower(level)
        level = level == "notice" and 0 or level == "warning" and 1 or level == "alert" and 2
    end

    if isentity(targets) and IsValid(targets) and targets:GetClass() == "player" then
        targets = {targets}
    elseif type(targets) ~= "table" then -- Convert to a table.
        targets = string.lower(tostring(targets))
        if targets == "1" or targets == "superadmins" then
            local new_targets = {}
            for _,v in next, player.GetHumans() do
                if not IsValid(v) then continue end
                if not (v:IsSuperAdmin()) then continue end
                table.insert(new_targets,v)
            end
            targets = new_targets
        elseif targets == "2" or targets == "admins" then
            local new_targets = {}
            for _,v in next, player.GetHumans() do
                if not IsValid(v) then continue end
                if not (v:IsAdmin() or v:IsSuperAdmin()) then continue end
                table.insert(new_targets,v)
            end
            targets = new_targets
        elseif targets == "0" or targets == "all" or targets == "everyone" then
            targets = player.GetHumans()
        end
    end

    msg = (string.Trim(msg or "") ~= "") and msg or nil

    if msg and (log or level >= 2) then
        ServerLog("[APG] ", msg .. "\n")
    end

    if type(targets) ~= "table" then return false end

    for _,v in next, targets do
        if not IsValid(v) then continue end
        net.Start("apg_notice_s2c")
            net.WriteUInt(level, 3)
            net.WriteString(msg)
        net.Send(v)
    end

    return true
end


--[[------------------------------------------
    Entity pickup part
]]--------------------------------------------

hook.Add("PhysgunPickup","APG_PhysgunPickup", function(ply, ent)
    if not APG.isBadEnt( ent ) then return end
    if not APG.canPhysGun( ent, ply ) then return false end

    ent.APG_Picked = true
    ent.APG_Frozen = false

    if ent.APG_HeldBy and ent.APG_HeldBy.plys and not ent.APG_HeldBy.plys[sid] then
        local HasHolder = istable(ent.APG_HeldBy.plys) and (table.Count(ent.APG_HeldBy.plys) > 0)
        local HeldByLast = ent.APG_HeldBy.last

        if HasHolder then
            if HeldByLast and (ply:IsAdmin() or ply:IsSuperAdmin()) then
                for _,v in next, ent.APG_HeldBy.plys do
                    APG.ForcePlayerDrop(v, ent)
                end
            else
                return false
            end
        end
    end

    ent.APG_HeldBy = (ent.APG_HeldBy and istable(ent.APG_HeldBy.plys)) and ent.APG_HeldBy or { plys = {} }
    ent.APG_HeldBy.plys[ply:SteamID()] = ply
    ent.APG_HeldBy.last = {ply = ply, id = ply:SteamID()}

    ply.APG_CurrentlyHolding = ent

    if APG.cfg["blockContraptionMove"].value then
        local count = 0
        local noFrozen = true

        for _,v in next, constraint.GetAllConstrainedEntities(ent) do
            count = count + 1
            if v.APG_Frozen then
                noFrozen = false
                break
            end
        end

        if noFrozen and ( count > 1 ) then
            timer.Simple(0, function()
                APG.freezeIt(ent, true)
            end)
        end
    end
end)

--[[--------------------
    No Collide (between them) on props unfreezed
]]----------------------
hook.Add("PlayerUnfrozeObject", "APG_PlayerUnfrozeObject", function(ply, ent, object)
    if not APG.isBadEnt( ent ) then return end
    ent.APG_Frozen = false
end)

--[[------------------------------------------
    Entity drop part
]]--------------------------------------------

--[[--------------------
    PhysGun Drop and Anti Throw Props
]]----------------------
hook.Add( "PhysgunDrop", "APG_physGunDrop", function( ply, ent )
    ent.APG_HeldBy = ent.APG_HeldBy or {}

    if ent.APG_HeldBy.plys then
        ent.APG_HeldBy.plys[ply:SteamID()] = nil -- Remove the holder.
    end

    ply.APG_CurrentlyHolding = nil

    if #ent.APG_HeldBy > 0 then return end
    ent.APG_Picked = false

    if APG.isBadEnt( ent ) and not APG.cfg["allowPK"].value then
        APG.killVelocity(ent,true,false,true) -- Extend to constrained props, and wake target.
    end
end)

--[[--------------------
    Physgun Drop & Freeze
]]----------------------
hook.Add( "OnPhysgunFreeze", "APG_OnPhysgunFreeze", function( weap, phys, ent, ply )
    if not APG.isBadEnt( ent ) then return end
    ent.APG_Frozen = true
end)


--[[--------------------
    Admin utility
]]----------------------

function APG.log(msg, ply)
    if type(ply) ~= "string" and IsValid(ply) then
        ply:PrintMessage(3, msg .. "\n")
    else
        print(msg)
    end
end

--[[--------------------
    APG job manager
--]]----------------------
local toProcess = toProcess or {}

function APG.dJobRegister( job, delay, limit, func, onBegin, onEnd )
    local tab = {
        content = {},
        delay = delay,
        limit = limit,
        func = func,
        onBegin = onBegin or nil,
        onEnd = onEnd or nil
    }
    toProcess[job] = tab
end

local function APG_delayedTick( job )
    if toProcess[job].processing and toProcess[job].processing == true then return end
    toProcess[job].processing = true
    if toProcess[job].onBegin then toProcess[job].onBegin() end
    local delay, pLimit = toProcess[job].delay, toProcess[job].limit
    local total = #toProcess[job].content
    local count = math.Clamp(total,0,pLimit)
    for i = 1, count do
        local cur = toProcess[job].content[1]
        timer.Create( "delay_" .. job .. "_" .. i , ( i - 1 ) * delay , 1, function()
            toProcess[job].func( cur )
        end)
        table.remove(toProcess[job].content, 1)
    end
    timer.Create("dJob_" .. job .. "_process", ( count * delay ) + 0.1 , 1, function() toProcess[job].processing = false
        if #toProcess[job].content < 1 and toProcess[job].onEnd then toProcess[job].onEnd() end
    end)
end

function APG.startDJob( job, content )
    if not job or not isstring(job) or not content then return end
    if not toProcess or not toProcess[job] then
        ErrorNoHalt("[APG] No Process Found, Attempting Reload!\n---\nThis Shouldn't Happen Concider Restarting!\n")
        APG.reload()
        return
    end

    if table.HasValue(toProcess[job].content, content) then return end

    -- Is it a problem if there is a same ent being unghosted twice ?
    table.insert( toProcess[job].content, content )
    hook.Add("Tick", "APG_delayed_" .. job, function()
        if #toProcess[job].content > 0 then
            APG_delayedTick( job )
        else
            hook.Remove("Tick", "APG_delayed_" .. job)
        end
    end)
end

hook.Add("InitPostEntity", "APG_Load", function()
    timer.Simple(0, function() -- Make sure we load last!
        APG.reload()
    end)
end)
