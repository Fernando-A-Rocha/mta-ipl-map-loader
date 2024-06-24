--[[
    MTA:SA IPL Map Loader

    by Nando (https://github.com/Fernando-A-Rocha/mta-modloader-reborn)
]]

local DEBUG_MODE = true

addEvent("ipl_map_loader:client:init", true)

local loadedMaps = {}

local function stringRemoveSpaces(str)
    return str:gsub("%s+", "")
end

local identityMatrix = {
	[1] = {1, 0, 0},
	[2] = {0, 1, 0},
	[3] = {0, 0, 1}
}
 
local function QuaternionTo3x3(x,y,z,w)
	local matrix3x3 = {[1] = {}, [2] = {}, [3] = {}}
 
	local symetricalMatrix = {
		[1] = {(-(y*y)-(z*z)), x*y, x*z},
		[2] = {x*y, (-(x*x)-(z*z)), y*z},
		[3] = {x*z, y*z, (-(x*x)-(y*y))} 
	}

	local antiSymetricalMatrix = {
		[1] = {0, -z, y},
		[2] = {z, 0, -x},
		[3] = {-y, x, 0}
	}
 
	for i = 1, 3 do 
		for j = 1, 3 do
			matrix3x3[i][j] = identityMatrix[i][j]+(2*symetricalMatrix[i][j])+(2*w*antiSymetricalMatrix[i][j])
		end
	end
	
	return matrix3x3
end

local function getEulerAnglesFromMatrix(x1,y1,z1,x2,y2,z2,x3,y3,z3)
	local nz1,nz2,nz3
	nz3 = math.sqrt(x2*x2+y2*y2)
	nz1 = -x2*z2/nz3
	nz2 = -y2*z2/nz3
	local vx = nz1*x1+nz2*y1+nz3*z1
	local vz = nz1*x3+nz2*y3+nz3*z3
	return math.deg(math.asin(z2)),-math.deg(math.atan2(vx,vz)),-math.deg(math.atan2(x2,y2))
end

-- Convert a quaternion representation of rotation into Euler angles
local function fromQuaternion(x, y, z, w)
    local matrix = QuaternionTo3x3(x,y,z,w)
	local ox,oy,oz = getEulerAnglesFromMatrix(
		matrix[1][1], matrix[1][2], matrix[1][3], 
		matrix[2][1], matrix[2][2], matrix[2][3],
		matrix[3][1], matrix[3][2], matrix[3][3]
	)

	return ox,oy,oz
end

local function isValidBuildingID(modelID)
    for _, id in pairs(VALID_BUILDING_IDS) do
        if id == modelID then
            return true
        end
    end
    return false
end

function getObjectsFromIPLFile(filePath)
    
    local file = fileOpen(filePath, true)
    if not file then
        return false, "Failed to open file"
    end
    local fileContent = fileGetContents(file, true) -- Verify checksum
    fileClose(file)
    if not fileContent then
        return false, "Failed to read file"
    end

    local lines = split(fileContent, "\n")
    local objects = {}

    local readingObjects = false
    for i=1, #lines do
        while true do
            local line = lines[i]
            line = stringRemoveSpaces(line)

            -- Ignore comments
            if string.sub(line, 1, 1) == "#" then
                break
            end

            -- Check if inst section is starting
            if string.sub(line, 1, 4) == "inst" then
                readingObjects = true
                break
            end

            if readingObjects then

                -- Check if inst section is ending
                if line == "end" then
                    readingObjects = false
                    break
                end

                local objectData = split(line, ",")
                if #objectData < 10 then
                    break
                end

                -- Model ID, Model Name, Interior ID, X, Y, Z, RX, RY, RZ, RW, (LOD optional)
                local modelID = tonumber(objectData[1])
                local modelName = objectData[2]
                local interiorID = tonumber(objectData[3])
                local x = tonumber(objectData[4])
                local y = tonumber(objectData[5])
                local z = tonumber(objectData[6])
                local rx = tonumber(objectData[7])
                local ry = tonumber(objectData[8])
                local rz = tonumber(objectData[9])
                local rw = tonumber(objectData[10])
                -- local lod = objectData[11] and tonumber(objectData[11]) or nil -- TODO ?

                if not modelID or not modelName or not interiorID or not x or not y or not z or not rx or not ry or not rz or not rw then
                    break
                end
                rx, ry, rz = fromQuaternion(rx, ry, rz, rw)
                objects[#objects + 1] = {modelID, modelName, interiorID, x, y, z, rx, ry, rz}
            end

            break
        end
    end

    return objects
end

local function loadIPLMap(filePath)
    if loadedMaps[filePath] then
        return false, "Map already loaded"
    end
    local objects, failReason = getObjectsFromIPLFile(filePath)
    if not objects then
        return false, failReason
    end
    
    local elements = {}
    local countCreatedObjects = 0

    for _, object in pairs(objects) do
        local modelID, modelName, interiorID, x, y, z, rx, ry, rz = unpack(object)
        
        local element = isValidBuildingID(modelID)
            and createBuilding(modelID, x, y, z, rx, ry, rz)
            or createObject(modelID, x, y, z, rx, ry, rz)
        if element then
            elements[#elements + 1] = element
            if getElementType(element) == "object" then
                countCreatedObjects = countCreatedObjects + 1
            end
            if DEBUG_MODE then
                createBlip(x, y, z, 0, 1, 255, 0, 0, 255, 0, 999999)
            end
        end
    end

    if #elements > 0 then
        loadedMaps[filePath] = elements
        if DEBUG_MODE then
            outputDebugString("Loaded map " .. filePath .. ": created " .. countCreatedObjects .. " objects and " .. (#elements - countCreatedObjects) .. " buildings")
        end
    else
        return false, "No buildings created"
    end

    return true
end

local function loadAllIPLs(iplFiles)
    for _, filePath in pairs(iplFiles) do
        local success, failReason = loadIPLMap(filePath)
        if not success then
            outputDebugString("Failed to load IPL map " .. filePath .. ": " .. failReason, 1)
        end
    end
end
addEventHandler("ipl_map_loader:client:init", localPlayer, loadAllIPLs, false)
