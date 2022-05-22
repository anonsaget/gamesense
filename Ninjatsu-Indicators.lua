--Ninjatsu Indicators by Chinese / Chinaman -- Discord shaftAndi#5802
--Credits to AESI, Falchion, MLC, ALSE for helping with development
--Thank you to HypeLevels, JFK Peeked my Scout, Sigma, Wendi, and Saphh for beta testing and giving feedback

--Ninjatsu Indicators aims to achieve in making Skeet features feel as if they were abilities in a game rather than a basic "DT" icon 

local images = require "gamesense/images" or error("Missing gamesense/images")
local vector = require "vector"
local ffi = require("ffi")
local entitylib = require 'gamesense/entity'

ffi.cdef[[
    struct glow_object_definition_t {
        int m_next_free_slot;
        void *m_ent;
        float r;
        float g;
        float b;
        float a;
        bool m_glow_alpha_capped_by_render_alpha;
        float m_glow_alpha_function_of_max_velocity;
        float m_glow_alpha_max;
        float m_glow_pulse_overdrive;
        bool m_render_when_occluded;
        bool m_render_when_unoccluded;
        bool m_full_bloom_render;
        char pad_0;
        int m_full_bloom_stencil_test_value;
        int m_style;
        int split_screen_slot;
    
        static const int END_OF_FREE_LIST = -1;
        static const int ENTRY_IN_USE = -2;
    };
    struct c_glow_object_mngr {
        struct glow_object_definition_t *m_glow_object_definitions;
        int m_max_size;
        int m_pad;
        int m_size;
        struct glow_object_definition_t *m_glow_object_definitions2;
        int m_current_objects;
    }; 
    typedef void*(__thiscall* get_client_entity_t)(void*, int);
]]

-----Attempt (failed)


ffi.cdef[[
    typedef void*( __thiscall* get_client_entity)( void*, int );
    typedef void*(__thiscall* get_view_model_fn)(void*, int);
]]


ffi.cdef('typedef struct { float x; float y; float z; } vmodel_vec3_t;')
ffi.cdef('typedef struct { float x; float y; float z; } vmodel_ang3_t;')

--[[
local native_GetClientEntity = vtable_bind("client.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*,int)")
local native_GetClientEntityFromHandle = vtable_bind("client.dll", "VClientEntityList003", 4, "void*(__thiscall*)(void*,unsigned long)")
local native_GetRenderOrigin = vtable_thunk(1, "vmodel_vec3_t(__thiscall*)(void**)")
local native_LookupAttachment = vtable_thunk(33, "int(__thiscall*)(void*, const char*)")
local native_GetAttachment = vtable_thunk(34, "bool(__thiscall*)(void*, int, vmodel_vec3_t&, vmodel_ang3_t&)")
local native_GetActiveWeapon vtable_thunk(267, "void*(__thiscall*)(void*)")

local sig = client.find_signature("client.dll", "\x55\x8B\xEC\x8B\x45\x08\x53\x8B\xD9\x56\x8B\x84\x83\xF8\x32\x00\x00") or error("sig scanning failed")
local get_view_model_func = ffi.cast("get_view_model_fn", sig) or error("failed to get get_view_model_func")

local origin_c = ffi.cast("vmodel_vec3_t&", ffi.new("char[?]", ffi.sizeof("vmodel_vec3_t")))
local angles_c = ffi.cast("vmodel_ang3_t&", ffi.new("char[?]", ffi.sizeof("vmodel_ang3_t")))

  ]]
-----------------


local cast = ffi.cast
local glow_object_manager_sig = "\x0F\x11\x05\xCC\xCC\xCC\xCC\x83\xC8\x01"
local match = client.find_signature("client_panorama.dll", glow_object_manager_sig) or error("sig not found")
local glow_object_manager = cast("struct c_glow_object_mngr**", cast("char*", match) + 3)[0] or error("glow_object_manager is nil")
local rawientitylist = client.create_interface("client_panorama.dll", "VClientEntityList003") or error("VClientEntityList003 wasnt found", 2)
local ientitylist = cast(ffi.typeof("void***"), rawientitylist) or error("rawientitylist is nil", 2)
local get_client_entity = cast("get_client_entity_t", ientitylist[0][3]) or error("get_client_entity is nil", 2)

------------------------------------------------------------------------------------------------------------------------------------------------------
---- https://github.com/Aviarita/lua-scripts/blob/master/local_player_glow/local_player_glow.lua  Credit to Aviarita for Easy Glow Implementation ----
------------------------------------------------------------------------------------------------------------------------------------------------------

--Checking if Reference exists 
local function ReferenceExists( ... )
    local args = {...}
    local suc, err = pcall(function()
        return ui.reference(unpack(args))
    end)

    if not suc or err == "not found" then
        return false
    end

    return true
end
--Thanks to my son AESI <3
--AESI is my son, number 1 LUA coder. Best GS user on forum.

function lerp(start, vend, time)
return start + (vend - start) * time end

local colorSchemes = {
    "Default",
    "Sigma",
    "Custom",
}

local soundSelection = {
    "Naruto",
    "Sekiro",
    "Custom",
}

local menu_startup = {
    ["Label"] = ui.new_label("LUA", "B", "              ------Ninjatsu Indicators-----            "),
    ["Indicators"] = ui.new_checkbox("LUA", "B", "Ninjatsu Indicators"),
}

local menu = {
    ["IndicatorsHud"] = ui.new_checkbox("LUA", "B", "Enable Static Indicators"),
    ["IndicatorsKnife"] = ui.new_checkbox("LUA", "B", "Knife Effect"),
    ["IndicatorsZeus"] = ui.new_checkbox("LUA", "B", "Zeus Effect"),
    ["IndicatorColorScheme"] = ui.new_combobox("LUA", "B", "Indicators Color Scheme", colorSchemes),
    ["JutsuSounds"] = ui.new_checkbox("LUA", "B", "Justsu Sounds"),
    ["JutsuSoundsSelect"] = ui.new_combobox("LUA", "B", "Jutsu Sound Selection", soundSelection),
    ["JutsuSoundsSlider"] = ui.new_slider("LUA", "B", "Justsu Sound Slider",0,100,2,true,"%"),
    ["debugToggle"] = ui.new_checkbox("LUA", "B", "Toggle Debug Options"),
    ["colorSeperator"]= ui.new_label("LUA", "B", "              ------Change Colors-----            "),
}

--When adding your own indicator, add two new UI elements so your next color picker UI element is an even number, as seen here
local menu_custom_color = {
    ui.new_label("LUA", "B", "DoubleTap Color"),  
    ui.new_color_picker("LUA", "B", "DoubleTap Color", 255,255,255,255),    --2

    ui.new_label("LUA", "B", "HideShots Color"),
    ui.new_color_picker("LUA", "B", "HideShots Color", 255,255,255,255),    --4

    ui.new_label("LUA", "B", "Quick Peek Color"),
    ui.new_color_picker("LUA", "B", "Quick Peek Color", 255,255,255,255),   --6

    ui.new_label("LUA", "B", "FakeDuck Color"),
    ui.new_color_picker("LUA", "B", "FakeDuck Color", 255,255,255,255),     --8

    ui.new_label("LUA", "B", "Slow Walk Color"),
    ui.new_color_picker("LUA", "B", "Slow Walk Color", 255,255,255,255),    --10

    ui.new_label("LUA", "B", "Your Own Menu Element Color"),
    ui.new_color_picker("LUA", "B", "Your Own Menu Element Color", 255,255,255,255),       --12

    ui.new_label("LUA", "B", "Zeus Color"),
    ui.new_color_picker("LUA", "B", "Zeus Color", 255,255,255,255),         --14

    ui.new_label("LUA", "B", "Knife Color"),
    ui.new_color_picker("LUA", "B", "Knife Color", 255,255,255,255),        --16
}

local menu_debug = {
    ["debugLabel"] = ui.new_label("LUA", "B", "              ------Debug Options-----            "),
    ["IndicatorsHudMove"] = ui.new_slider("LUA", "B", "Adjust Static Indicators Position", 0 , 900, 0),
    ["debugPosition"] = ui.new_checkbox("LUA", "B", "Toggle Manual Indicator Positioning"),
    ["debugExample"] = ui.new_checkbox("LUA", "B", "Preview Current Indicator Placement"),
    ["animSpeed"] = ui.new_slider("LUA", "B", "Set Indicator Animation Speed", 0 , 64, 12),
    ["glowOpacity"] = ui.new_slider("LUA", "B", "Glow Opacity", 0 , 255, 65),
    ["glowEaseSpeed"] = ui.new_slider("LUA", "B", "Glow Easing Speed", 1 , 20, 3),
    ["SampleSlider"] = ui.new_slider("LUA", "B", "Example of easing speed", 0 , 255, 0),
    
}

--Define your ref here and set it false for now
local refs = { 
    ["fakeduck"] = false,
    ["thirdperson"] = false,
    ["DT"] = false,
    ["HideShot"]= false,
    ["quickpeek"] = false,
    ["slowwalk"] = false,
}


--Table of colors to glow with correlating image
local glowColorScheme = {
    ["Default"] = --Presets
        {   
            ["DT"]={255, 0, 0, 10}, 
            ["Ideal"]={0, 255, 255, 10},
            ["HideShot"]={78, 44, 173, 10},  
            ["FakeDuck"]={240, 244, 142, 10}, 
            ["SlowWalk"]={0, 255, 0, 10}, 
            ["customColorPreset"]={227, 109, 254, 10}, 
            ["Zeus"]={0, 175, 255, 10}, 
            ["Knife"]={255, 0, 0, 10}, 
        },
    ["Sigma"] = --As seen on Sigma YouTube
        {   
            ["DT"]={0,102,255,10}, 
            ["Ideal"]={255, 114, 0, 10}, 
            ["HideShot"]={78, 44, 173, 10},  
            ["FakeDuck"]={240, 244, 142, 10}, 
            ["SlowWalk"]={0, 255, 0, 10}, 
            ["customColorPreset"]={227, 109, 254, 10}, 
            ["Zeus"]={0, 175, 255, 10}, 
            ["Knife"]={255, 0, 0, 10}, 
        },
    ["Custom"] = --Custom color picker (text will be notably more white)
        {   
            ["DT"]={ui.get(menu_custom_color[2])}, 
            ["HideShot"]={ui.get(menu_custom_color[4])},  
            ["Ideal"]={ui.get(menu_custom_color[6])}, 
            ["FakeDuck"]={ui.get(menu_custom_color[8])}, 
            ["SlowWalk"]={ui.get(menu_custom_color[10])}, 
            ["customColorPreset"]={ui.get(menu_custom_color[12])}, 
            ["Zeus"]={ui.get(menu_custom_color[14])}, 
            ["Knife"]={ui.get(menu_custom_color[16])}, 
        },
}

--Defining image paths, when adding your own image, include the same image in other paths as well to prevent errors
local imgsPath = {
    ["Default"] = 
        {   
            ["DT"]="Ninjatsu-Indi/Default/DT.png", 
            ["Ideal"]="Ninjatsu-Indi/Default/Ideal.png",
            ["HideShot"]="Ninjatsu-Indi/Default/HideShots.png",
            ["FakeDuck"]="Ninjatsu-Indi/Default/FakeDuck.png",
            ["SlowWalk"]="Ninjatsu-Indi/Default/SlowWalk.png",
            ["customElement"]="Ninjatsu-Indi/Default/your_own_img.png",
            ["Zeus"]="Ninjatsu-Indi/Default/Zeus.png",
            ["Knife"]="Ninjatsu-Indi/Default/BackStab.png",
        },
    ["Sigma"] = 
        {   
            ["DT"]="Ninjatsu-Indi/Sigma/DT.png", 
            ["Ideal"]="Ninjatsu-Indi/Sigma/Ideal.png",
            ["HideShot"]="Ninjatsu-Indi/Sigma/HideShots.png",
            ["FakeDuck"]="Ninjatsu-Indi/Sigma/FakeDuck.png",
            ["SlowWalk"]="Ninjatsu-Indi/Sigma/SlowWalk.png",
            ["customElement"]="Ninjatsu-Indi/Sigma/your_own_img.png",
            ["Zeus"]="Ninjatsu-Indi/Sigma/Zeus.png",
            ["Knife"]="Ninjatsu-Indi/Sigma/BackStab.png",
        },
    ["Custom"] = 
        {   
            ["DT"]="Ninjatsu-Indi/Blank/DT_Fade.png", 
            ["DT_Text"]="Ninjatsu-Indi/Blank/DT_Text.png", 
            ["Ideal"]="Ninjatsu-Indi/Blank/Ideal_Fade.png",
            ["Ideal_Text"]="Ninjatsu-Indi/Blank/Ideal_Text.png",
            ["HideShot"]="Ninjatsu-Indi/Blank/HideShots_Fade.png",
            ["HideShot_Text"]="Ninjatsu-Indi/Blank/HideShots_Text.png",
            ["FakeDuck"]="Ninjatsu-Indi/Blank/FakeDuck_Fade.png",
            ["FakeDuck_Text"]="Ninjatsu-Indi/Blank/FakeDuck_Text.png",
            ["SlowWalk"]="Ninjatsu-Indi/Blank/SlowWalk_Fade.png",
            ["SlowWalk_Text"]="Ninjatsu-Indi/Blank/SlowWalk_Text.png",
            ["customElement"]="Ninjatsu-Indi/Blank/your_own_img_Fade.png",
            ["customElement_Text"]="Ninjatsu-Indi/Blank/your_own_img_Text.png",
            ["Zeus"]="Ninjatsu-Indi/Blank/Zeus_Fade.png",
            ["Zeus_Text"]="Ninjatsu-Indi/Blank/Zeus_Text.png",
            ["Knife"]="Ninjatsu-Indi/Blank/Knife_Fade.png",
            ["Knife_Text"]="Ninjatsu-Indi/Blank/Knife_Text.png",
        },
}

---Credit to mlc / falchion's
function angle_forward(angle)
    local sin_pitch = math.sin(math.rad(angle.x))
    local cos_pitch = math.cos(math.rad(angle.x))
    local sin_yaw   = math.sin(math.rad(angle.y))
    local cos_yaw   = math.cos(math.rad(angle.y))

    return vector(cos_pitch * cos_yaw, cos_pitch * sin_yaw, -sin_pitch)
end

function angle_right( angle )
    local sin_pitch = math.sin( math.rad( angle.x ) );
    local cos_pitch = math.cos( math.rad( angle.x ) );
    local sin_yaw   = math.sin( math.rad( angle.y ) );
    local cos_yaw   = math.cos( math.rad( angle.y ) );
    local sin_roll  = math.sin( math.rad( angle.z ) );
    local cos_roll  = math.cos( math.rad( angle.z ) );

    return vector(
        -1.0 * sin_roll * sin_pitch * cos_yaw + -1.0 * cos_roll * -sin_yaw,
        -1.0 * sin_roll * sin_pitch * sin_yaw + -1.0 * cos_roll * cos_yaw,
        -1.0 * sin_roll * cos_pitch
    );
end


function vecotr_ma(start, scale, direction_x, direction_y, direction_z)
    return vector(start.x + scale * direction_x, start.y + scale * direction_y, start.z + scale * direction_z)
end

local function clamp(x, min, max)
    return x < min and min or x > max and max or x
end

function lerp(start, vend, time)
    return start + (vend - start) * time 
end

--Creds to Falchion

-- When adding your own indicator, add one extra to the array, 
-- example: 
-- alpha = {0,0,0,0,0,0,0,0} 
-- becomes 
-- alpha = {0,0,0,0,0,0,0,0,0}
-- Each element in this array represents a potential indicator to be render, this is due to have a functional
-- fade in and fade out look, without the tank in performance
-- by default you have 8 elements, index 6 being your custom reference if desired
--                     V    <--- that one is index 6
local ani = {
    alpha = {0,0,0,0,0,0,0,0},  --changes from 0 to 255
    tableAlpha = {0,0,0,0,0,0,0,0}, --changes from 0 to 255
    glowAlpha = {0,0,0,0,0,0,0,0}, --changes from 0 to ui.get(menu_debug.glowOpacity)+1
    switch = {false,false,false,false,false,false,false,false}, --Dictates whether the main indicator has been shown or not
    audioSwitch = {true,true,true,true,true,true,true,true},    --Dictates whether the audio has been played or not
    glowSwitch = {false,false,false,false,false,false,false,false}, --Dictates whether glow will be ran
    imgArray = {{nil, nil}, {nil, nil}, {nil, nil}, {nil, nil}, {nil, nil}, {nil, nil}, {nil, nil}, {nil, nil}}, --For the table function, we're putting images in an array so they stack nicely, granted I should of done this in the first place but too late
    y_array = {0,0,0,0,0,0,0,0},    --Small Y axis animation for the indicator
    x_tblarray = {1,1,1,1,1,1,1,1}, --X axis animation for the table
}

local function displayPerma()
    local scr = {client.screen_size()}
    local counter = 0

    for i, v in ipairs(ani.imgArray) do
        if(ani.tableAlpha[i] > 1) then
            counter = counter + 1
            ani.x_tblarray[i] = lerp((ani.x_tblarray[i]), (counter * 70),globals.frametime() * ui.get(menu_debug.animSpeed))
            if(ui.get(menu.IndicatorColorScheme) == "Custom") then
                local r,g,b,a = ui.get(menu_custom_color[i*2])     
                ani.imgArray[i][1]:draw(ui.get(menu_debug.IndicatorsHudMove) + (scr[1] / (5) + (ani.x_tblarray[i])), scr[2] / 1.053, math.floor((scr[1]/38.4)+0.5), math.floor((scr[2]/21.6)+0.5), r, g, b, ani.tableAlpha[i]) 
                ani.imgArray[i][2]:draw(ui.get(menu_debug.IndicatorsHudMove) + (scr[1] / (5) + (ani.x_tblarray[i])), scr[2] / 1.053, math.floor((scr[1]/38.4)+0.5), math.floor((scr[2]/21.6)+0.5), 255, 255, 255, ani.tableAlpha[i]) 
            else
                ani.imgArray[i][1]:draw(ui.get(menu_debug.IndicatorsHudMove) + (scr[1] / (5) + (ani.x_tblarray[i])), scr[2] / 1.053, math.floor((scr[1]/38.4)+0.5), math.floor((scr[2]/21.6)+0.5), 255, 255, 255, ani.tableAlpha[i]) 
            end
        end
    end
end

--Indicator rendering function
local function indicatorRender(center_x, center_y, indicatorCondition, img, rgb, arrIndex, customImgText)
    local scr = {client.screen_size()}
    local lpent = get_client_entity(ientitylist, entity.get_local_player())

    --Checking if image is contained in table at our index, if not, we will add it!
    if(not ani.imgArray[arrIndex][{img, customImgText}]) then
        ani.imgArray[arrIndex] = {img, customImgText}
    end

    --Main indicator fade in
    if (indicatorCondition) and (not ani.switch[arrIndex]) then
        ani.glowSwitch[arrIndex] = true 
        ani.y_array[arrIndex] = lerp(ani.y_array[arrIndex], 20,globals.frametime() * ui.get(menu_debug.animSpeed))
        ani.alpha[arrIndex] = lerp(ani.alpha[arrIndex],255,globals.frametime() * ui.get(menu_debug.animSpeed))
        ani.tableAlpha[arrIndex] = lerp(ani.tableAlpha[arrIndex],255,globals.frametime() * ui.get(menu_debug.animSpeed))

        --Checking if audio is toggled
        if(ui.get(menu.JutsuSounds) and ani.audioSwitch[arrIndex]) then
            if(ui.get(menu.JutsuSoundsSelect) == "Naruto") then 
                client.exec("playvol NinjatsuSounds/naruto.mp3 " .. tostring(ui.get(menu.JutsuSoundsSlider) / 100))
            elseif(ui.get(menu.JutsuSoundsSelect) == "Sekiro") then
                client.exec("playvol NinjatsuSounds/sekiro.mp3 " .. tostring(ui.get(menu.JutsuSoundsSlider) / 100))
            end
            ani.audioSwitch[arrIndex] = false
        end
        --Main indicator has met its opacity level
        if(ani.alpha[arrIndex] >= 254) then 
            ani.switch[arrIndex] = true --We're setting this to true to meet our next condition, and we wont run this if statement afterwards unless the condition has been set to false
        end
    end

    --Main indicator fade out   
    if(ani.switch[arrIndex]) then
        ani.alpha[arrIndex] = lerp(ani.alpha[arrIndex],-1,globals.frametime() * ui.get(menu_debug.animSpeed))   --god bless lerp
    end

    if(indicatorCondition) then
        ani.glowAlpha[arrIndex] = lerp(ani.glowAlpha[arrIndex],ui.get(menu_debug.glowOpacity)+1,globals.frametime() * ui.get(menu_debug.glowEaseSpeed))
        ui.set(menu_debug.SampleSlider, ani.glowAlpha[arrIndex])
    end

    --When the condition is false, we will set our variables to default settings.
    if(not indicatorCondition) then
        ani.switch[arrIndex] = false
        ani.audioSwitch[arrIndex] = true
        ani.alpha[arrIndex]  = lerp(ani.alpha[arrIndex],-1,globals.frametime() * ui.get(menu_debug.animSpeed))
        ani.y_array[arrIndex] = lerp(ani.y_array[arrIndex], 0,globals.frametime() * ui.get(menu_debug.animSpeed))
        ani.tableAlpha[arrIndex] = lerp(ani.tableAlpha[arrIndex],-1,globals.frametime() * ui.get(menu_debug.animSpeed))     --Fading out the mini indicator
        ani.glowAlpha[arrIndex] = lerp(ani.glowAlpha[arrIndex],-1,globals.frametime() * ui.get(menu_debug.glowEaseSpeed))   --Fading out self-glow
        if(ani.tableAlpha[arrIndex] <= 0) then
            ani.imgArray[arrIndex] = {img, customImgText}
        end
        if(ani.glowSwitch[arrIndex]) then
            ui.set(menu_debug.SampleSlider, ani.glowAlpha[arrIndex])
        end
        if(ani.glowAlpha[arrIndex] <= 0) then
            ani.glowSwitch[arrIndex] = false 
        end
    end

    local r,g,b,a
    if(ani.glowSwitch[arrIndex]) then
        if(ui.get(menu.IndicatorColorScheme) == "Custom") then
            r,g,b,a = ui.get(menu_custom_color[arrIndex*2])   --We multiply the index by 2 to get our custom color, refer to menu_custom_color table
        else
            r,g,b = rgb[1],rgb[2],rgb[3]
        end
        for i=0, glow_object_manager.m_size do 
            if glow_object_manager.m_glow_object_definitions[i].m_next_free_slot == -2 and glow_object_manager.m_glow_object_definitions[i].m_ent then 
                local glowobject = cast("struct glow_object_definition_t&", glow_object_manager.m_glow_object_definitions[i])
                local glowent = glowobject.m_ent
                if entity.is_alive(entity.get_local_player()) and glowent == lpent then 
                    glowobject.r = r / 255
                    glowobject.g = g / 255
                    glowobject.b = b / 255
                    glowobject.a = ani.glowAlpha[arrIndex] / 255
                    glowobject.m_style = 1
                    glowobject.m_render_when_occluded = true
                    glowobject.m_render_when_unoccluded = false
                end 
            end
        end
    end

    if(ui.get(menu.IndicatorColorScheme) == "Custom") then
        local r,g,b,a = ui.get(menu_custom_color[arrIndex*2])        
        img:draw(center_x, center_y - ani.y_array[arrIndex], math.floor((scr[1]/19.2)+0.5), math.floor((scr[2]/10.8)+0.5), r, g, b, ani.alpha[arrIndex]) 
        local ss = {client.screen_size()}
        customImgText:draw(center_x, center_y - ani.y_array[arrIndex], math.floor((scr[1]/19.2)+0.5), math.floor((scr[2]/10.8)+0.5), 255, 255, 255, ani.alpha[arrIndex])
    else
        img:draw(center_x, center_y - ani.y_array[arrIndex], math.floor((scr[1]/19.2)+0.5), math.floor((scr[2]/10.8)+0.5), 255, 255, 255, ani.alpha[arrIndex]) 
    end

end

local ss1 = {client.screen_size()}

--Credits to Alse, Korean man
local newX, newY = (ss1[1] / 2), (ss1[2] / 2)

local function previewIndicator()   --Movable Indicator Function
    if (ui.get(menu_debug.debugExample)) then
        local x, y = ui.mouse_position()
        local leftClick = client.key_state(0x01)
        local overlap = x > newX and x < newX + 100 and y > newY and y < newY + 100
        if ui.is_menu_open() and leftClick and overlap then 
            newX = x - 50
            newY = y - 50
        end
        if(ui.get(menu_debug.debugExample)) then
            DT_Img:draw(newX, newY, math.floor((ss1[1]/19.2)+0.5), math.floor((ss1[2]/10.8)+0.5), 255, 255, 255, 255)   
        end
    end
    return newX, newY 
end

--Credits to my son, AESI <3
-- Checking if the reference we're looking for exists. This works with custom UI elements added by LUA's so you can prevent any errors from appearing if said lua isnt loaded.
local function setup_func( name )
	local fail = 0
	if name == "fakeduck" then
		refs["fakeduck"] = ReferenceExists("Rage", "Other", "Duck peek assist") and ui.reference("Rage", "Other", "Duck peek assist") or (function() fail = fail + 1 return false end)()
	elseif name == "thirdperson" then
    	refs["thirdperson"] = ReferenceExists("Visuals", "Effects", "Force third person (alive)") and { ui.reference("Visuals", "Effects", "Force third person (alive)") } or (function() fail = fail + 1 return {false, false} end)()
    elseif name == "DT" then
   	 	refs["DT"] = ReferenceExists('RAGE', 'Other', 'Double tap') and {ui.reference('RAGE', 'Other', 'Double tap')} or (function() fail = fail + 1 return {false, false} end)()
    elseif name == "HideShot" then
    	refs["HideShot"]= ReferenceExists('AA', 'Other', 'On shot anti-aim') and {ui.reference('AA', 'Other', 'On shot anti-aim')} or (function() fail = fail + 1 return {false, false} end)()
    elseif name == "quickpeek" then
  		refs["quickpeek"] = ReferenceExists('Rage', 'Other', 'Quick peek assist') and {ui.reference('Rage', 'Other', 'Quick peek assist')} or (function() fail = fail + 1 return {false, false} end)()
    elseif name == "slowwalk" then
        refs["slowwalk"] = ReferenceExists('AA', 'Other', 'Slow motion') and {ui.reference('AA', 'Other', 'Slow motion')} or (function() fail = fail + 1 return {false, false} end)()
    elseif name == "Far Teleport" then
    	refs["Your Own Menu Element"] = ReferenceExists('AA', 'Other', 'Your Own Menu Element') and ui.reference('AA', 'Other', 'Your Own Menu Element') or (function() fail = fail + 1 return false end)()
   	else
   		return error("name not found", 2)
   	end

    return fail == 0
end


-------------Third person exchanging
function thrid_person()
    local entities = entitylib.get_all("CPredictedViewModel")
    for _, entidx in ipairs(entities) do
        
        local vector_origin = vector(entidx:get_origin())
        local view_punch_angle = vector(entitylib.get_local_player():get_prop("m_vecOrigin"))
        local aim_punch_angle = vector(entitylib.get_local_player():get_prop("m_vecOrigin"))
        local camera_angles = vector(client.camera_angles()) -- [[+ (view_punch_angle + aim_punch_angle)]]

        local forward = angle_forward(camera_angles)
        local right = angle_right(view_punch_angle + aim_punch_angle)

        vector_origin = vecotr_ma(vector_origin, 1, right.x, right.y, right.z)
        vector_origin = vecotr_ma(vector_origin, 30, forward.x, forward.y, forward.z)
        return vector_origin
    end
end

local animation = {
    x = 0,
    y = 0,
}
local playerDeath = {
    id = nil,
    origin = {0,0,0},
    zeus = false,
    time_on_zeus_kill = 0,
    knife = false,
    time_on_knife_kill = 0,
}

client.set_event_callback("paint", function()  
    if not entity.is_alive(entity.get_local_player()) or not ui.get(menu_startup.Indicators) then return end

    --The variables below me will return a boolean, add the according one to your reference
	local can_fd, can_th, can_dt, can_hs, can_qt, can_sw, can_ft --can_your-own-var-here,
     = setup_func("fakeduck"), setup_func("thirdperson"), setup_func("DT"), setup_func("HideShot"), setup_func("quickpeek"), setup_func("slowwalk"), setup_func("Far Teleport") --,setup_func("your own name here")
    local colorSchemeStr = tostring(ui.get(menu.IndicatorColorScheme))

    --If you are adding your own indicator, be sure you make a naked text variant, a glow only variant, and your normal one
    if(colorSchemeStr == "Custom") then --If custom is checked, we will read the indicators without the glow
        DT_Text_Img = images.load(readfile(imgsPath[colorSchemeStr]["DT_Text"]))
        HS_Text_Img = images.load(readfile(imgsPath[colorSchemeStr]["HideShot_Text"]))
        Ideal_Text_IMg = images.load(readfile(imgsPath[colorSchemeStr]["Ideal_Text"]))
        FD_Text_Img = images.load(readfile(imgsPath[colorSchemeStr]["FakeDuck_Text"]))
        SW_Text_Img = images.load(readfile(imgsPath[colorSchemeStr]["SlowWalk_Text"]))
        TP_Text_Img = images.load(readfile(imgsPath[colorSchemeStr]["customElement_Text"]))
        Zeus_Text_Img = images.load(readfile(imgsPath[colorSchemeStr]["Zeus_Text"]))
        Knife_Text_Img = images.load(readfile(imgsPath[colorSchemeStr]["Knife_Text"]))
    end
    --If the preset is set to custom, this will also take the fade only
    DT_Img = images.load(readfile(imgsPath[colorSchemeStr]["DT"]))
    HS_Img = images.load(readfile(imgsPath[colorSchemeStr]["HideShot"]))
    Ideal_IMg = images.load(readfile(imgsPath[colorSchemeStr]["Ideal"]))
    FD_Img = images.load(readfile(imgsPath[colorSchemeStr]["FakeDuck"]))
    SW_Img = images.load(readfile(imgsPath[colorSchemeStr]["SlowWalk"]))
    TP_Img = images.load(readfile(imgsPath[colorSchemeStr]["customElement"]))
    Zeus_Img = images.load(readfile(imgsPath[colorSchemeStr]["Zeus"]))
    Knife_Img = images.load(readfile(imgsPath[colorSchemeStr]["Knife"]))

    local vector_origin = thrid_person()
    if(vector_origin == nil) then
        return
    end
    local w2s_pos = vector(renderer.world_to_screen(vector_origin.x, vector_origin.y, vector_origin.z))

    local scx, scy = client.screen_size()
    cut_x = (scx / 2) - 45
    cut_y = scy - 800


    if (ui.get(refs.thirdperson[1]) and ui.get(refs.thirdperson[2])) then
        animation.x = lerp(animation.x, w2s_pos.x , globals.frametime() * 6)
        animation.y = lerp(animation.y, w2s_pos.y, globals.frametime() * 6)
    else
        animation.x = lerp(animation.x, cut_x, globals.frametime() * 6)
        animation.y = lerp(animation.y ,cut_y, globals.frametime() * 6)
    end

    local sx, sy = animation.x, animation.y

    local ss = {client.screen_size()}
    local center_x, center_y = (ss[1] / 2) - 40, (ss[2] / 2) - 90

    if(ui.get(menu_debug.debugPosition)) then
        center_x, center_y = previewIndicator()
    end

    if(ui.get(menu.IndicatorsHud)) then
        displayPerma()
    end

    --indicatorRender() params takes in as follows, (X pos, Y pos, condition needed to activate indicator, Indicator image path, indicator color scheme [checking if default, sigma, or custom], arrayIndex [this HAS to be in order], image of the text only)
    if can_dt then --Added and (not ui.get(refs.quickpeek[2])) for ideal tick lua to not overlap 
        indicatorRender(center_x, center_y,(ui.get(refs.DT[2]) and (not ui.get(refs.quickpeek[2]))), DT_Img, glowColorScheme[colorSchemeStr]["DT"],1,DT_Text_Img)
	end    
    if can_hs then
        indicatorRender(center_x, center_y,ui.get(refs.HideShot[2]), HS_Img, glowColorScheme[colorSchemeStr]["HideShot"],2,HS_Text_Img)
	end    
    if can_qt then
        indicatorRender(center_x, center_y,ui.get(refs.quickpeek[2]), Ideal_IMg, glowColorScheme[colorSchemeStr]["Ideal"],3,Ideal_Text_IMg)
	end
	if can_fd then
        indicatorRender(center_x, center_y,ui.get(refs.fakeduck), FD_Img, glowColorScheme[colorSchemeStr]["FakeDuck"],4,FD_Text_Img)
	end
    if can_sw then
        indicatorRender(center_x, center_y,ui.get(refs.slowwalk[2]), SW_Img, glowColorScheme[colorSchemeStr]["SlowWalk"],5,SW_Text_Img)
	end
	if can_ft then --Custom LUA scripts
        indicatorRender(center_x, center_y, ui.get(refs["Your Own Menu Element"]), TP_Img, glowColorScheme[colorSchemeStr]["customColorPreset"],6,TP_Text_Img)
    end
    

    --An example of being able to use the indicators for other conditions, here we are looking to see if the zeus/knife kills happened less than 1 second ago
    if(ui.get(menu.IndicatorsZeus)) then
        if(playerDeath.zeus == true) then
            local xPos, yPos = renderer.world_to_screen(playerDeath.origin[1], playerDeath.origin[2],playerDeath.origin[3])
            if(xPos ~= nil) then
                indicatorRender(xPos - 60, yPos - 120, (globals.realtime() - playerDeath.time_on_zeus_kill) < 1 , Zeus_Img, glowColorScheme[colorSchemeStr]["Zeus"],7,Zeus_Text_Img)
            end
        end
    end
    if(ui.get(menu.IndicatorsKnife)) then
        if(playerDeath.knife == true) then
            local xPos, yPos = renderer.world_to_screen(playerDeath.origin[1], playerDeath.origin[2],playerDeath.origin[3])
            if(xPos ~= nil) then
                indicatorRender(xPos - 60, yPos - 120, (globals.realtime() - playerDeath.time_on_knife_kill) < 1 , Knife_Img, glowColorScheme[colorSchemeStr]["Knife"],8,Knife_Text_Img)
            end
        end
    end
end)


--This doesn't need an explanation honestly
client.set_event_callback("player_death", function(e)  
    if (not e.attacker == entity.get_local_player()) and (e.userid ~=  entity.get_local_player()) then return end
    local victim_entindex   = client.userid_to_entindex(e.userid)
    if(e.weapon == "taser") then
        local x, y, z = entity.get_prop(victim_entindex, "m_vecOrigin")
        playerDeath.id = e.userid
        playerDeath.time_on_zeus_kill = globals.realtime()
        playerDeath.origin = {x,y,z}
        playerDeath.zeus = true
    end
    if(string.find(e.weapon, "knife"))then
        local x, y, z = entity.get_prop(victim_entindex, "m_vecOrigin")
        playerDeath.id = e.userid
        playerDeath.time_on_knife_kill = globals.realtime()
        playerDeath.origin = {x,y,z}
        playerDeath.knife = true
    end

end)

--UI Elements
client.set_event_callback("paint_ui", function()  

    if(ui.get(menu_startup.Indicators)) then
        for k in pairs(menu) do
            ui.set_visible(menu[k], true)     
        end
        if(ui.get(menu.JutsuSounds)) then 
            ui.set_visible(menu.JutsuSoundsSlider, true) 
            ui.set_visible(menu.JutsuSoundsSelect, true) 
        else 
            ui.set_visible(menu.JutsuSoundsSlider, false) 
            ui.set_visible(menu.JutsuSoundsSelect, false) 
        end 
    else
        for k in pairs(menu) do
             ui.set_visible(menu[k], false)
        end
    end

    if(ui.get(menu.IndicatorColorScheme) == "Custom") then
        for k in pairs(menu_custom_color) do
            ui.set_visible(menu_custom_color[k], true)
        end
        ui.set_visible(menu.colorSeperator, true)
    else
        for k in pairs(menu_custom_color) do
            ui.set_visible(menu_custom_color[k], false)
        end
        ui.set_visible(menu.colorSeperator, false)
    end

    if(ui.get(menu.debugToggle)) then
        for k in pairs(menu_debug) do
            ui.set_visible(menu_debug[k], true)
        end
        if(ui.get(menu_debug.debugPosition)) then 
            ui.set_visible(menu_debug.debugExample, true) 
        else 
            ui.set_visible(menu_debug.debugExample, false) 
        end 
    else
        for k in pairs(menu_debug) do
            ui.set_visible(menu_debug[k], false)
        end
    end
end)