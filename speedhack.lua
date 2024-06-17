local memory = require 'memory'
local vkeys = require 'vkeys'
local imgui = require "imgui"
local inicfg = require 'inicfg'
local directIni = 'shSet.ini'
local ini = inicfg.load(inicfg.load({
    main = {
        boost = 1.5,
        tractionLost = 0.7,
        key = 18
    },
}, directIni))
inicfg.save(ini, directIni)
local VehicleStats = {}

local window = imgui.ImBool(false)
local cfgBoost = imgui.ImFloat(ini.main.boost)
local cfgTractionLost = imgui.ImFloat(ini.main.tractionLost)
local activeKey = ini.main.key

local Active = false
local boost = 1
local setKey = false


function main()
    while not isSampAvailable() do wait(0) end
    style()
    sampRegisterChatCommand("sh", function()
        window.v = not window.v
    end)
    while true do
        wait(0)
        imgui.Process = window.v
        if isCharInAnyCar(PLAYER_PED) and not sampIsCursorActive() then
            if wasKeyPressed(tonumber("0x"..fromDec(activeKey, 16))) then
                if memory.getint8(GetVehicleHeader() * 0xE0 + 0xC2B9DC + 0x76, false) > 0 then
                    active = not active
                    printString(active and 'SH by Marino ~G~ON' or 'SH by Marino ~R~OFF', 1000)
                    if active then
                        GetDefaultSettings()
                        memory.setfloat(GetVehicleHeader() * 0xE0 + 0xC2B9DC + 0xA4, VehicleStats[GetVehicleHeader()][3] + cfgTractionLost.v, false)
                    end
                    if not active then
                        boost = 1
                        SetDefaultSettings()
                    end
                end
            end
            if active then
                if boost < 30 then
                    boost = boost + 0.1
                end
                if getCarSpeed(storeCarCharIsInNoSave(PLAYER_PED)) < 10 then boost = 1 end
                memory.setfloat(GetVehicleHeader() * 0xE0 + 0xC2B9DC + 0x7C, VehicleStats[GetVehicleHeader()][1]*boost*cfgBoost.v, false)
                memory.setfloat(GetVehicleHeader() * 0xE0 + 0xC2B9DC + 0x80, VehicleStats[GetVehicleHeader()][2]*boost, false)
            end
        end
    end
end

function imgui.OnDrawFrame()
    if window.v then
        local sw, sh = getScreenResolution()
		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(500, 100), imgui.Cond.FirstUseEver)
        imgui.Begin("Settings", window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
        if imgui.SliderFloat("Boost speed", cfgBoost, 0.001, 3) then
            ini.main.boost = cfgBoost.v
            inicfg.save(ini, directIni)
        end
        if imgui.SliderFloat("Traction Loss", cfgTractionLost, 0.001, 3) then
            ini.main.tractionLost = cfgTractionLost.v
            inicfg.save(ini, directIni)
        end
        if imgui.Button(setKey and "Save Key" or "Change Key") then
            setKey = not setKey
            lockPlayerControl(setKey)
        end
        imgui.SameLine()
        imgui.Text("Activeted Key: "..vkeys.id_to_name(activeKey))
        if setKey then
            for k, i in pairs(vkeys) do
                if isKeyJustPressed(vkeys[k]) then
                    ini.main.key = vkeys[k]
                    activeKey = vkeys[k]
                    inicfg.save(ini, directIni)
                end
            end
        end
        imgui.End()
    end
end

function GetVehicleHeader()
	local value = 0
	local car = storeCarCharIsInNoSave(playerPed)
	if car then
		value = getCarModel(car)
		value = memory.getint32(value * 0x4 + 0xA9B0C8, false)
		value = memory.getint16(value + 0x4A, false)
	end
	return value
end

function GetDefaultSettings()
    local VehicleSettings = GetVehicleHeader()
    if VehicleStats[VehicleSettings] == nil then
        VehicleStats[VehicleSettings] = {
        memory.getfloat(VehicleSettings * 0xE0 + 0xC2B9DC + 0x7C, false), -- Engine Aceleration
        memory.getfloat(VehicleSettings * 0xE0 + 0xC2B9DC + 0x80, false), -- Engine Inertia
        memory.getfloat(VehicleSettings * 0xE0 + 0xC2B9DC + 0xA4, false) -- Traction Loss
        }
    end
end

function SetDefaultSettings()
    local VehicleSettings = GetVehicleHeader()
    memory.setfloat(VehicleSettings * 0xE0 + 0xC2B9DC + 0x7C, VehicleStats[VehicleSettings][1], false) -- 12 Engine Aceleration
	memory.setfloat(VehicleSettings * 0xE0 + 0xC2B9DC + 0x80, VehicleStats[VehicleSettings][2], false) -- 13 Engine Inertia
    memory.setfloat(VehicleSettings * 0xE0 + 0xC2B9DC + 0xA4, VehicleStats[VehicleSettings][3], false)
end

function fromDec(input, base)
    local hexstr = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local s = ''
    while input > 0 do
        local mod = math.fmod(input, base)
        s = string.sub(hexstr, mod + 1, mod + 1) .. s
        input = math.floor(input / base)
    end
    if s == '' then
        s = '0'
    end
    return s
end

function style()
    imgui.SwitchContext()
	style = imgui.GetStyle()
    colors = style.Colors
    clr = imgui.Col
    ImVec4 = imgui.ImVec4
    ImVec2 = imgui.ImVec2
    
	style.WindowRounding = 2.0
    style.WindowTitleAlign = ImVec2(0.5, 0.5)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 2.0
    style.ItemSpacing = ImVec2(5.0, 4.0)
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0
	colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1.00)
    colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1.00)
    colors[clr.WindowBg] = ImVec4(0.11, 0.15, 0.17, 1.00)
    colors[clr.ChildWindowBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border] = ImVec4(1, 1, 1, 0.5)
    colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.FrameBgHovered] = ImVec4(0.12, 0.20, 0.28, 1.00)
    colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1.00)
    colors[clr.TitleBg] = ImVec4(0.09, 0.12, 0.14, 0.65)
    colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.TitleBgActive] = ImVec4(0.08, 0.10, 0.12, 1.00)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[clr.ScrollbarGrab] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1.00)
    colors[clr.Button] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.ButtonHovered] = ImVec4(0.52, 0.2, 0.92, 1.00)
    colors[clr.ButtonActive] = ImVec4(0.60, 0.2, 1.00, 1.00)
    colors[clr.ComboBg] = ImVec4(0.20, 0.20, 0.20, 0.70)
    colors[clr.CheckMark] = ImVec4(0.52, 0.2, 0.92, 1.00)
    colors[clr.SliderGrab] = ImVec4(0.52, 0.2, 0.92, 1.00)
    colors[clr.SliderGrabActive] = ImVec4(0.60, 0.2, 1.00, 1.00)
    colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.TextSelectedBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
end