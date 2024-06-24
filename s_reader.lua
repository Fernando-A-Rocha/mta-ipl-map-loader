--[[
    MTA:SA IPL Map Loader

    by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn)
]]

local iplFiles = {}

local function stringEndsWith(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end

if pathIsDirectory(IPL_FOLDER_NAME) then
    for _, fileName in pairs(pathListDir(IPL_FOLDER_NAME)) do
        if stringEndsWith(fileName, ".ipl") then
            iplFiles[#iplFiles + 1] = IPL_FOLDER_NAME.."/"..fileName
        end
    end
end

addEventHandler("onPlayerResourceStart", root, function(res)
    if res ~= resource then
        return
    end
    triggerClientEvent(source, "ipl_map_loader:client:init", source, iplFiles)
end)
