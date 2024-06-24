--[[
    MTA:SA IPL Map Loader

    by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn)
]]

local resourceName = getResourceName(resource)
local outputGUIWindow = nil

local function convertObjectsToFormat(objects, outputFormat, fileName)
    local str = ""
    if outputFormat == "lua" then
        local realTime = getRealTime()
        local timestampStr = string.format("%02d/%02d/%04d at %02d:%02d:%02d", realTime.monthday, realTime.month+1, realTime.year+1900, realTime.hour, realTime.minute, realTime.second)
        str = str .. ("-- Map '%s' converted on %s using %s\n"):format(fileName, timestampStr, "MTA:SA " .. resourceName)
        str = str .. "local objects = {\n"
        for i=1, #objects do
            local object = objects[i]
            local modelID, modelName, interiorID, x, y, z, rx, ry, rz = unpack(object)
            str = str .. ("    {%d, %f, %f, %f, %f, %f, %f, %d}, -- %s\n"):format(modelID, x, y, z, rx, ry, rz, interiorID, modelName)
        end
        str = str .. "}\n"
        str = str .. "for i=1, #objects do\n"
        str = str .. "    local object = objects[i]\n"
        str = str .. "    local modelID, x, y, z, rx, ry, rz, interiorID = unpack(object)\n"
        str = str .. "    local object = createObject(modelID, x, y, z, rx, ry, rz)\n"
        str = str .. "    if object then setElementInterior(object, interiorID) end\n"
        str = str .. "end\n"
    elseif outputFormat == "map" then
        -- MTA:SA XML Map Format
        str = str .. '<map edf:definitions="editor_main">\n'
        for i=1, #objects do
            local object = objects[i]
            local modelID, modelName, interiorID, x, y, z, rx, ry, rz = unpack(object)
            str = str .. ('    <object id="%d (%d - %s)" model="%d" interior="%d" posX="%f" posY="%f" posZ="%f" rotX="%f" rotY="%f" rotZ="%f" breakable="false" alpha="255" dimension="0" scale="1" doublesided="false" collisions="true" frozen="false"/>\n'):format(i, modelID, modelName, modelID, interiorID, x, y, z, rx, ry, rz)
        end
        str = str .. '</map>\n'
    end
    return str
end

local function cmdConvertIPL(cmd, fileName, outputFormat)
    if not fileName or not (outputFormat == "lua" or outputFormat == "map") then
        outputChatBox("Usage: /"..cmd.." <fileName> <lua|map>")
        return
    end
    local filePath = IPL_FOLDER_NAME .. "/" .. fileName
    if not fileExists(filePath) then
        outputChatBox("File not found: "..filePath, 255, 0, 0)
        return
    end
    local objects, failReason = getObjectsFromIPLFile(filePath)
    if not objects then
        outputChatBox("Failed to load IPL file: "..failReason, 255, 0, 0)
        return
    end
    local outputMapText, failReason2 = convertObjectsToFormat(objects, outputFormat, fileName)
    if not outputMapText then
        outputChatBox("Failed to convert IPL file: "..failReason2, 255, 0, 0)
        return
    end

    if outputGUIWindow and isElement(outputGUIWindow) then
        destroyElement(outputGUIWindow)
    end
    outputGUIWindow = guiCreateWindow(0.5, 0.5, 0.4, 0.4, ("IPL Converter - %s (%s)"):format(fileName, outputFormat), true)
    local outputMemo = guiCreateMemo(0.05, 0.05, 0.9, 0.8, "", true, outputGUIWindow)
    guiMemoSetReadOnly(outputMemo, true)
    local copyBtn = guiCreateButton(0.05, 0.87, 0.45, 0.1, "Copy to clipboard", true, outputGUIWindow)
    guiSetProperty(copyBtn, "NormalTextColour", "FF00FF00")
    local closeBtn = guiCreateButton(0.5, 0.87, 0.45, 0.1, "Close", true, outputGUIWindow)
    guiSetInputMode("no_binds_when_editing")
    showCursor(true)

    addEventHandler("onClientGUIClick", outputGUIWindow, function(btn)
        if btn ~= "left" then return end
        if source == copyBtn then
            setClipboard(guiGetText(outputMemo))
        elseif source == closeBtn then
            destroyElement(outputGUIWindow)
            outputGUIWindow = nil

            guiSetInputMode("allow_binds")
            showCursor(false)
        end
    end)

    guiSetText(outputMemo, outputMapText)
end
addCommandHandler(CONVERT_IPL_CMD, cmdConvertIPL, false)

