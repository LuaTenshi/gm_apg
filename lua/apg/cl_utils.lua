--[[------------------------------------------

    A.P.G. - a lightweight Anti Prop Griefing solution (v{{ script_version_name }})
    Made by :
    - While True (http://steamcommunity.com/id/76561197972967270)
    - LuaTenshi (http://steamcommunity.com/id/76561198096713277)

    Licensed to : http://steamcommunity.com/id/{{ user_id }}

]]--------------------------------------------

surface.CreateFont( "APG_title_font", {
    font = "Arial",
    size = 14,
    weight = 700,
} )

surface.CreateFont( "APG_title2_font", {
    font = "Arial",
    size = 13,
    weight = 700,
} )

surface.CreateFont( "APG_sideBar_font", {
    font = "Arial",
    size = 18,
    weight = 1500,
} )

surface.CreateFont( "APG_mainPanel_font", {
    font = "Arial",
    size = 19,
    weight = 8500,
} )

surface.CreateFont( "APG_tick_font", {
    font = "Arial",
    size = 29,
    weight = 1900,
} )

surface.CreateFont( "APG_element_font", {
    font = "Arial",
    size = 17,
    weight = 1300,
} )

surface.CreateFont( "APG_element2_font", {
    font = "Arial",
    size = 17,
    weight = 2900,
} )

local utils = {}

function utils.addBadEntity( class )
    local found = false
    for k, v in pairs ( ents.GetAll() ) do
        if class == v:GetClass() then
            found = true
            break
        end
    end
    if not found then
        for k in pairs (scripted_ents.GetList()) do
            if class == k then
                found = true
                break
            end
        end
    end
    APG.cfg["bad_ents"].value[ class ] = found
end

function utils.getNiceName( str )
    local nName = string.gsub(str,"^%l",string.upper)
    nName = string.gsub(nName,"_", " " )
    return nName
end

function utils.mainSwitch( x, y, on )
    draw.RoundedBox(10,x,y,45,18,Color( 58, 58, 58, 255))
    if on then
        draw.RoundedBox(10, x + 1, y + 1, 45 - 2, 18 - 2,Color( 11,70,30, 255))
        draw.DrawText( "ON", "APG_title_font", x + 8, y + 2, Color( 189, 189, 189 ), 3 )
        draw.RoundedBox(10, x + 27, y, 18, 18, Color( 88, 88, 88, 255))
    else
        --draw.RoundedBox(10,x,y,45,18,Color( 110, 28, 38, 255))
        draw.RoundedBox(10, x + 1, y + 1, 43, 16, Color( 34, 34, 34, 255))
        draw.DrawText( "OFF", "APG_title_font", x + 21, y + 2, Color( 189, 189, 189), 3 )
        draw.RoundedBox(10, x, y, 18, 18, Color( 88, 88, 88, 255))
    end
    --draw.RoundedBox(0,x+20,y,1,18,Color( 88, 88, 88, 255))
end

function utils.switch( panel, x, y, w, h, text, var )
    local button = vgui.Create("DButton",panel)
        button:SetPos(x,y)
        button:SetSize(w,h)
        button:SetText("")
        button.Paint = function(slf, w, h)
            local enabled = APG.cfg[ var ].value
                draw.RoundedBox(0,0, h * 0.95, w - 5, 1, Color(250, 250, 250,1))
                draw.DrawText( text, "APG_element2_font",0, 0, Color( 189, 189, 189), 3 )
                utils.mainSwitch( w-45, 0, enabled )
        end
        button.DoClick = function()
            APG.cfg[ var ].value = not APG.cfg[ var ].value
        end
end

function utils.numSlider( panel, x, y, w, h, text, var, minSlider, maxSlider, decimal )
    local slider = vgui.Create( "DNumSlider", panel )
        slider:SetPos( x, y )
        slider:SetSize( w, h )
        slider:SetText( "" )
        slider:SetMin( minSlider )
        slider:SetMax( maxSlider )
        slider:SetDecimals( decimal )
        slider:SetValue( APG.cfg[ var ].value )
        slider.OnValueChanged = function( self, newValue )
            APG.cfg[ var ].value = newValue
        end
        slider.Paint = function(slf, w, h)
            draw.RoundedBox( 0, 0, h * 0.97, w - 5, 1, Color(250, 250, 250, 1 ) )
            draw.DrawText( text, "APG_element2_font", 0, 0, Color( 189, 189, 189), 3 )
        end
        slider.Slider.Paint = function( slf, w, h)
            draw.RoundedBox( 0, 8, 9 - 1, w - 16, 1 + 2, Color( 250, 250, 250, 1))
        end
        slider.Slider.Knob.Paint = function(slf, w, h)
            draw.RoundedBox(6,0,4,10,10,Color( 11,70,30, 255))
        end

        slider.Slider:Dock( NODOCK )
        slider.Slider:SetPos( 300, 0 )
        slider.Slider:SetWide( 100 )

        slider.TextArea:Dock( NODOCK )
        slider.TextArea:SetPos( 265, - 3 )
        slider.TextArea.m_colText = Color(189, 189, 189)
        slider.TextArea.Paint = function( self, w, h)
            draw.RoundedBox(10,0,1,w-15,h,Color( 58, 58, 58, 255))
            derma.SkinHook( "Paint", "TextEntry", self, w, h )
        end
end

function utils.textEntry( panel, x, y, w, h, text, var )
    local label = vgui.Create( "DLabel", panel )
        label:SetPos( x, y )
        label:SetSize( w, h )
        label:SetText( text )
        label:SetFont("APG_element2_font")
        label:SetColor( Color( 189, 189, 189) )
        label.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, h * 0.97, w, 1, Color(250, 250, 250,1))
        end
    local txtEntry = vgui.Create( "DTextEntry", panel ) -- create the form as a child of frame
        txtEntry:SetPos( x + 267, y-1 )
        txtEntry:SetSize( 125, 20 )
        txtEntry:SetText( "custom" )
        txtEntry.OnEnter = function( self )
        end

end

function utils.comboBox(panel, x, y, w, h, text, var, content)
    local label = vgui.Create( "DLabel", panel )
        label:SetPos( x, y )
        label:SetSize( w, h )
        label:SetText( text )
        label:SetFont("APG_element2_font")
        label:SetColor( Color( 189, 189, 189) )
        label.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, h * 0.97, w, 1, Color(250, 250, 250,1))
        end
    local comboBox = vgui.Create( "DComboBox", panel )
        comboBox:SetPos( x + 267, y-2 )
        comboBox:SetSize( 125, 20 )
        comboBox:SetValue( APG.cfg[var].value )
        for k, v in pairs ( content ) do
            comboBox:AddChoice(v)
        end
        comboBox.OnSelect = function( panel, index, value )
            APG.cfg[var].value = value
        end
        comboBox.Paint = function(i, w, h)
            draw.RoundedBox(0,0,0,w,h,Color(58, 58, 58, 240))
        end
        comboBox:SetTextColor(Color( 189, 189, 189))
        local o_OpenMenu = comboBox.OpenMenu
        comboBox.OpenMenu = function( pControlOpener )
            o_OpenMenu(pControlOpener)
            comboBox.Menu.Paint = function (i,w,h)
                draw.RoundedBox(0,0,0,w,h,Color(58, 58, 58, 240))
            end
        end
end

return utils
