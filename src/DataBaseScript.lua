--[[
DataBaseScript by Rickoff
tes3mp 0.8.0
script version 0.3
---------------------------
DESCRIPTION :
Create a database
---------------------------
INSTALLATION:
Save the file as DataBaseScript.lua inside your server/scripts/custom folder.
Edits to customScripts.lua
DataBaseScript = require("custom.DataBaseScript")

armorType
0 = Helmet
1 = Cuirass
2 = L. Pauldron
3 = R. Pauldron
4 = Greaves
5 = Boots
6 = L. Gauntlet
7 = R. Gauntlet
8 = Shield
9 = L. Bracer
10 = R. Bracer

partBodyType = index
0 = Head
1 = Hair
2 = Neck
3 = Cuirass
4 = Groin
5 = Skirt
6 = Right Hand
7 = Left Hand
8 = Right Wrist
9 = Left Wrist
10 = Shield
11 = Right Forearm
12 = Left Forearm
13 = Right Upper Arm
14 = Left Upper Arm
15 = Right Foot
16 = Left Foot
17 = Right Ankle
18 = Left Ankle
19 = Right Knee
20 = Left Knee
21 = Right Upper Leg
22 = Left Upper Leg
23 = Right Pauldron
24 = Left Pauldron
25 = Weapon
26 = Tail

partBodyCloth
MP_Head = 0,
MP_Hair = 1,
MP_Neck = 2,
MP_Chest = 3,
MP_Groin = 4,
MP_Hand = 5,
MP_Wrist = 6,
MP_Forearm = 7,
MP_Upperarm = 8,
MP_Foot = 9,
MP_Ankle = 10,
MP_Knee = 11,
MP_Upperleg = 12,
MP_Clavicle = 13,
MP_Tail = 14
]]
local config = {}
config.files = {"Starwind.omwaddon"}

local DataBaseCellContent = {}
local DataBaseListCell = {}
local DataBaseStaticContent = {}
local DataBaseCreatureContent = {}
local DataBase = {}

local DataArmor = {}
local DataWeapon = {}
local DataSpell = {}
local DataActivator = {}
local DataAlchemy = {}
local DataApparatus = {}
local DataBody = {}
local DataBook = {}
local DataClothing = {}
local DataContainer = {}
local DataCreature = {}
local DataDial = {}
local DataInfo = {}
local DataNpc = {}
local DataLight = {}
local DataIngredient = {}
local DataLeveledItem = {}
local DataMisc = {}
local DataAppa = {}
local DataLock = {}
local DataProb = {}
local DataRepa = {}
local DataEnch = {}
local DataLevc = {}
local DataGmst = {}
local DataBirt = {}

local TopicList = {}

local DataBaseScript = {}

DataBaseScript.CreateJsonDataBase = function(eventStatus)

	for x, file in pairs(config.files) do

		local records = (espParser.getRecordsByName(file, "CELL"))
		local dataTypes = {
			Unique = {
				{"NAME", "s", "name"}, --cell description
				{"DATA", {
					{"i", "flags"},
					{"i", "gridX"},
					{"i", "gridY"}
				}},
				{"INTV", "i", "water"}, --water height stored in a int (didn't know about this one until I checked the openmw source, no idea why theres 2 of them)
				{"WHGT", "f", "water"}, --water height stored in a float
				{"AMBI", {
					{"i", "ambientColor"},
					{"i", "sunlightColor"},
					{"i", "fogColor"},
					{"f", "fogDensity"}
				}},
				{"RGNN", "s", "region"}, --the region name like "Azura's Coast" used for weather and stuff
				{"NAM5", "i", "mapColor"},
				{"NAM0", "i", "refNumCounter"} --when you add a new object to the cell in the editor it gets this refNum then this variable is incremented 
			},
			Multi = {
				{"NAME", "s", "refId"},
				{"XSCL", "f", "scale"},
				{"DELE", "i", "deleted"}, --rip my boi
				{"DNAM", "s", "destCell"}, --the name of the cell the door takes you too
				{"FLTV", "i", "lockLevel"}, --door lock level
				{"KNAM", "s", "key"}, --key refId
				{"TNAM", "s", "trap"}, --trap spell refId
				{"UNAM", "B", "referenceBlocked"},
				{"ANAM", "s", "owner"}, --the npc owner or the item
				{"BNAM", "s", "globalVariable"}, -- Global variable for use in scripts?
				{"INTV", "i", "charge"}, --current charge?
				{"NAM9", "i", "goldValue"}, --https://github.com/OpenMW/openmw/blob/dcd381049c3b7f9779c91b2f6b0f1142aff44c4a/components/esm/cellref.cpp#L163
				{"XSOL", "s", "soul"},
				{"CNAM", "s", "faction"}, --faction who owns the item
				{"INDX", "i", "factionRank"}, --what rank you need to be in the faction to pick it up without stealing?
				{"XCHG", "i", "enchantmentCharge"}, --max charge?
				{"DODT", {
					{"f", "posX"},
					{"f", "posY"},
					{"f", "posZ"},
					{"f", "rotX"},
					{"f", "rotY"},
					{"f", "rotZ"}
				}, "doorDest"}, --the position the door takes you too
				{"DATA", {
					{"f", "posX"},
					{"f", "posY"},
					{"f", "posZ"},
					{"f", "rotX"},
					{"f", "rotY"},
					{"f", "rotZ"}
				}, "location"} --the position of the object
			}
		}
		
		for _, record in pairs(records) do
			local cell = {}
			
			for _, dType in pairs(dataTypes.Unique) do
				local tempData = record:getSubRecordsByName(dType[1])[1]
				if tempData ~= nil then
					if type(dType[2]) == "table" then
						local stream = espParser.Stream:create( tempData.data )
						for _, ddType in pairs(dType[2]) do
							cell[ ddType[2] ] = struct.unpack( ddType[1], stream:read(4) )
						end
					else
						cell[ dType[3] ] = struct.unpack( dType[2], tempData.data )
					end
				end
			end			
			cell.objects = {}
			local currentIndex = nil
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "FRMR" then
					currentIndex = struct.unpack( "i", subrecord.data ).."-0"
					cell.objects[currentIndex] = {}
					cell.objects[currentIndex].refNum = currentIndex
					cell.objects[currentIndex].scale = 1 --just a default
				end
					
				for _, dType in pairs(dataTypes.Multi) do
					if subrecord.name == dType[1] and currentIndex ~= nil then --if its a subrecord in dataTypes.Multi
						if type(dType[2]) == "table" then --there are several values in this data
							local stream = espParser.Stream:create( subrecord.data )
							for _, ddType in pairs(dType[2]) do --go thrue every value that we want out of this data
								if dType[3] ~= nil then --store the values in a table
									if cell.objects[currentIndex][ dType[3] ] == nil then
										cell.objects[currentIndex][ dType[3] ] = {}
									end
									cell.objects[currentIndex][ dType[3] ][ ddType[2] ] = struct.unpack( ddType[1], stream:read(4) )
								else --store the values directly in the cell
									cell.objects[currentIndex][ ddType[2] ] = struct.unpack( ddType[1], lenTable[ ddType[1] ] )
								end
							end
						else -- theres only one value in the data
							cell.objects[currentIndex][ dType[3] ] = struct.unpack( dType[2], subrecord.data )
						end
					end
				end
			end
			local jsonCellName = cell.name
			local checkString = string.find(cell.name, ":")
			if checkString then
				jsonCellName = string.gsub(cell.name, ":", ";")
			end	
			tes3mp.LogMessage(enumerations.log.ERROR, jsonCellName)
			DataBaseListCell[jsonCellName] = true	
			if not DataBaseCellContent[jsonCellName] then
				DataBaseCellContent[jsonCellName] = cell.objects

			else
				if cell.objects then
					for index, slot in pairs(cell.objects) do
						DataBaseCellContent[jsonCellName][index] = cell.objects[index]
					end
				end
			end

			jsonInterface.save("custom/Starwind/Cell/"..jsonCellName..".json", DataBaseCellContent[jsonCellName])
		end	
		jsonInterface.save("custom/Starwind/CellName.json", DataBaseListCell)
	end
	tes3mp.StopServer(0)
end

--[[	
	for x, file in pairs(config.files) do

		for _,record in pairs(espParser.getRecordsByName(file, "GMST")) do
			tableGMST = {
				id = "",
				floatVar = "",
				intVar = "",
				stringVar = ""

			}
			--gamesetting = { "baseId", "id", "intVar", "floatVar", "stringVar" }	
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableGMST.id = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "FLTV" then
					tableGMST.floatVar = struct.unpack("f", subrecord.data)
				end
				if subrecord.name == "INTV" then
					tableGMST.intVar = struct.unpack("i", subrecord.data)
				end
				if subrecord.name == "STRV" then
					tableGMST.stringVar = struct.unpack("s", subrecord.data)
				end				
			end
			DataGmst[string.lower(tableGMST.id)] = tableGMST
		end	
		jsonInterface.save("custom/Ecarlate/DataGmst.json", DataGmst)
		
		for _,record in pairs(espParser.getRecordsByName(file, "LEVC")) do
			tableLeveledNpc = {
				baseId = "",
				flags = "",
				chance = "",
				count = "",
				name = "",
				objects = {}
			}
			local itemList = {refId = "", PClevel = ""}			
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableLeveledNpc.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "DATA" then
					tableLeveledNpc.flags = struct.unpack( "I", string.sub(subrecord.data, 1, 1+4) )
				end				
				if subrecord.name == "NNAM" then
					tableLeveledNpc.chance = struct.unpack("B", string.sub(subrecord.data, 1, 1+1) )
				end	
				if subrecord.name == "INDX" then
					tableLeveledNpc.count = struct.unpack("I", string.sub(subrecord.data, 1, 1+4) )
				end	
				if subrecord.name == "CNAM" then
					itemList.refId = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "INTV" then
					itemList.PClevel = struct.unpack("H", string.sub(subrecord.data, 1, 1+2) )
				end	
				if itemList.refId ~= "" and itemList.PClevel ~= "" then
					table.insert(tableLeveledNpc.objects, itemList)
					itemList = {refId = "", PClevel = ""}
				end
			end
			DataLevc[string.lower(tableLeveledNpc.baseId)] = tableLeveledNpc
		end	
		jsonInterface.save("custom/Ecarlate/DataLevc.json", DataLevc)
		
		for _,record in pairs(espParser.getRecordsByName(file, "ENCH")) do
			local tableEnch= {
				baseId = "",
				subtype = "",
				cost = "",
				charge = "",
				flags = "",
				effects = {}
			}				
			for _, subrecord in pairs(record.subRecords) do
				local enchantList = {}
				if subrecord.name == "NAME" then
					tableEnch.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "ENDT" then
					tableEnch.subtype = struct.unpack( "I", string.sub(subrecord.data, 1, 1+4) )
					tableEnch.cost = struct.unpack( "I", string.sub(subrecord.data, 5, 5+4) )	
					tableEnch.charge = struct.unpack( "I", string.sub(subrecord.data, 9, 9+4) )	
					tableEnch.flags = struct.unpack( "I", string.sub(subrecord.data, 9, 9+4) )						
				end				
				if subrecord.name == "ENAM" then
					enchantList.id = struct.unpack( "H", string.sub(subrecord.data, 1, 1+2) )	
					enchantList.skill = struct.unpack( "b", string.sub(subrecord.data, 3, 3+1) )
					enchantList.attribute = struct.unpack( "b", string.sub(subrecord.data, 4, 4+1) )
					enchantList.rangeType = struct.unpack( "I", string.sub(subrecord.data, 5, 5+4) )
					enchantList.area = struct.unpack( "I", string.sub(subrecord.data, 9, 9+4) )	
					enchantList.duration = struct.unpack( "I", string.sub(subrecord.data, 13, 13+4) )
					enchantList.magnitudeMin = struct.unpack( "I", string.sub(subrecord.data, 17, 17+4) )
					enchantList.magnitudeMax = struct.unpack( "I", string.sub(subrecord.data, 21, 21+4) )		
					table.insert(tableEnch.effects, enchantList)
				end		
			end
			DataEnch[string.lower(tableEnch.baseId)] = tableEnch
		end	
		jsonInterface.save("custom/Ecarlate/DataEnch.json", DataEnch)	
		
		for _,record in pairs(espParser.getRecordsByName(file, "REPA")) do
			tableRepa = {
				baseId = "",
				model = "",
				name = "",
				weight = "",
				value = "",
				uses = "",				
				quality = "",
				icon = "",				
				script = ""
			}		
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableRepa.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableRepa.model = struct.unpack("s", subrecord.data)
				end				
				if subrecord.name == "FNAM" then
					tableRepa.name = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "RIDT" then
					tableRepa.weight = struct.unpack("f", string.sub(subrecord.data, 1, 1+4) )
					tableRepa.value = struct.unpack("I", string.sub(subrecord.data, 5, 5+4) )	
					tableRepa.uses = struct.unpack("I", string.sub(subrecord.data, 9, 9+4) )
					tableRepa.quality = struct.unpack("f", string.sub(subrecord.data, 13, 13+4) )					
				end					
				if subrecord.name == "ITEX" then
					tableRepa.icon = struct.unpack("s", subrecord.data)
				end					
				if subrecord.name == "SCRI" then
					tableRepa.script = struct.unpack("s", subrecord.data)
				end									
			end
			DataRepa[string.lower(tableRepa.baseId)] = tableRepa
		end	
		jsonInterface.save("custom/Ecarlate/DataRepa.json", DataRepa)
		
		for _,record in pairs(espParser.getRecordsByName(file, "PROB")) do
			tableProb = {
				baseId = "",
				model = "",
				name = "",
				weight = "",
				value = "",
				quality = "",
				uses = "",
				script = "",
				icon = ""
			}		
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableProb.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableProb.model = struct.unpack("s", subrecord.data)
				end				
				if subrecord.name == "FNAM" then
					tableProb.name = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "PBDT" then
					tableProb.weight = struct.unpack("f", string.sub(subrecord.data, 1, 1+4) )
					tableProb.value = struct.unpack("I", string.sub(subrecord.data, 5, 5+4) )	
					tableProb.quality = struct.unpack("f", string.sub(subrecord.data, 9, 9+4) )
					tableProb.uses = struct.unpack("I", string.sub(subrecord.data, 13, 13+4) )					
				end					
				if subrecord.name == "SCRI" then
					tableProb.script = struct.unpack("s", subrecord.data)
				end					
				if subrecord.name == "ITEX" then
					tableProb.icon = struct.unpack("s", subrecord.data)
				end					
			end
			DataProb[string.lower(tableProb.baseId)] = tableProb
		end	
		jsonInterface.save("custom/Ecarlate/DataProb.json", DataProb)

		for _,record in pairs(espParser.getRecordsByName(file, "LOCK")) do
			tableLock = {
				baseId = "",
				model = "",
				name = "",
				weight = "",
				value = "",
				quality = "",
				uses = "",
				script = "",
				icon = ""
			}		
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableLock.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableLock.model = struct.unpack("s", subrecord.data)
				end				
				if subrecord.name == "FNAM" then
					tableLock.name = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "LKDT" then
					tableLock.weight = struct.unpack("f", string.sub(subrecord.data, 1, 1+4) )
					tableLock.value = struct.unpack("I", string.sub(subrecord.data, 5, 5+4) )	
					tableLock.quality = struct.unpack("f", string.sub(subrecord.data, 9, 9+4) )
					tableLock.uses = struct.unpack("I", string.sub(subrecord.data, 13, 13+4) )					
				end					
				if subrecord.name == "SCRI" then
					tableLock.script = struct.unpack("s", subrecord.data)
				end					
				if subrecord.name == "ITEX" then
					tableLock.icon = struct.unpack("s", subrecord.data)
				end					
			end
			DataLock[string.lower(tableLock.baseId)] = tableLock
		end	
		jsonInterface.save("custom/Ecarlate/DataLock.json", DataLock)
		
		for _,record in pairs(espParser.getRecordsByName(file, "APPA")) do
			tableAppa = {
				baseId = "",
				model = "",
				name = "",
				script = "",
				subtype = "",
				quality = "",
				weight = "",
				value = "",
				icon = ""
			}		
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableAppa.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableAppa.model = struct.unpack("s", subrecord.data)
				end				
				if subrecord.name == "FNAM" then
					tableAppa.name = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "SCRI" then
					tableAppa.script = struct.unpack("s", subrecord.data)
				end					
				if subrecord.name == "AADT" then
					tableAppa.subtype = struct.unpack("I", string.sub(subrecord.data, 1, 1+4) )
					tableAppa.quality = struct.unpack("f", string.sub(subrecord.data, 5, 5+4) )	
					tableAppa.weight = struct.unpack("f", string.sub(subrecord.data, 9, 9+4) )
					tableAppa.value = struct.unpack("I", string.sub(subrecord.data, 13, 13+4) )					
				end	
				if subrecord.name == "ITEX" then
					tableAppa.icon = struct.unpack("s", subrecord.data)
				end	
			end
			DataAppa[string.lower(tableAppa.baseId)] = tableAppa
		end	
		jsonInterface.save("custom/Ecarlate/DataAppa.json", DataAppa)

		for _,record in pairs(espParser.getRecordsByName(file, "MISC")) do
			tableMisc = {
				baseId = "",
				model = "",
				name = "",
				weight = "",
				value = "",
				script = "",
				icon = ""
			}		
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableMisc.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableMisc.model = struct.unpack("s", subrecord.data)
				end				
				if subrecord.name == "FNAM" then
					tableMisc.name = struct.unpack("s", subrecord.data)
				end				
				if subrecord.name == "MCDT" then
					tableMisc.weight = struct.unpack("F", string.sub(subrecord.data, 1, 1+4) )
					tableMisc.value = struct.unpack("I", string.sub(subrecord.data, 5, 5+4) )					
				end	
				if subrecord.name == "SCRI" then
					tableMisc.script = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "ITEX" then
					tableMisc.icon = struct.unpack("s", subrecord.data)
				end	
			end
			DataMisc[string.lower(tableMisc.baseId)] = tableMisc
		end	
		jsonInterface.save("custom/Ecarlate/DataMisc.json", DataMisc)
		
		for _,record in pairs(espParser.getRecordsByName(file, "LEVI")) do
			tableLeveledItem = {
				baseId = "",
				flags = "",
				chance = "",
				count = "",
				objects = {}
			}
			local itemList = {refId = "", PClevel = ""}			
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableLeveledItem.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "DATA" then
					tableLeveledItem.flags = struct.unpack( "I", string.sub(subrecord.data, 1, 1+4) )
				end				
				if subrecord.name == "NNAM" then
					tableLeveledItem.chance = struct.unpack("B", string.sub(subrecord.data, 1, 1+1) )
				end	
				if subrecord.name == "INDX" then
					tableLeveledItem.count = struct.unpack("I", string.sub(subrecord.data, 1, 1+4) )
				end	
				if subrecord.name == "INAM" then
					itemList.refId = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "INTV" then
					itemList.PClevel = struct.unpack("H", string.sub(subrecord.data, 1, 1+2) )
				end	
				if itemList.refId ~= "" and itemList.PClevel ~= "" then
					table.insert(tableLeveledItem.objects, itemList)
					itemList = {refId = "", PClevel = ""}
				end
			end
			DataLeveledItem[string.lower(tableLeveledItem.baseId)] = tableLeveledItem
		end	
		jsonInterface.save("custom/Ecarlate/DataLeveledItem.json", DataLeveledItem)

		for _,record in pairs(espParser.getRecordsByName(file, "INGR")) do
			tableIngredient = {
				baseId = "",
				model = "",					
				name = "",	
				weight = "",
				value = "",
				effects = {},
				script = "",
				icon = ""				
			}
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableIngredient.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableIngredient.model = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "FNAM" then
					tableIngredient.name = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "IRDT" then
					tableIngredient.weight = struct.unpack("f", subrecord.data, 1, 1+4)
					tableIngredient.value = struct.unpack("I", subrecord.data, 5, 5+4)
					local count = 9
					for x = 1, 4 do
						local effects = {index = "", skill = "", attribute = ""}
						effects.index = struct.unpack("i", subrecord.data, count, count+4)
						count = count + 4
						effects.skill = struct.unpack("i", subrecord.data, count, count+4)
						count = count + 4
						effects.attribute = struct.unpack("i", subrecord.data, count, count+4)
						count = count + 4
						table.insert(tableIngredient.effects, effects)
					end					
				end					
				if subrecord.name == "SCRI" then
					tableIngredient.script = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "ITEX" then
					tableIngredient.icon = struct.unpack("s", subrecord.data)
				end					
			end
			DataIngredient[string.lower(tableIngredient.baseId)] = tableIngredient
		end	
		jsonInterface.save("custom/Ecarlate/DataIngredient.json", DataIngredient)

		for _,record in pairs(espParser.getRecordsByName(file, "LIGH")) do
			tableLight = {
				baseId = "",
				model = "",					
				name = "",	
				icon = "",
				weight = "",
				value = "",
				times = "",
				radius = "",
				color = "",				
				flags = "",
				sound = "",
				script = ""				
			}
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableLight.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableLight.model = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "FNAM" then
					tableLight.name = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "ITEX" then
					tableLight.icon = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "LHDT" then
					tableLight.weight = struct.unpack("f", subrecord.data, 1, 1+4)
					tableLight.value = struct.unpack("I", subrecord.data, 5, 5+4)
					tableLight.times = struct.unpack("i", subrecord.data, 9, 9+4)
					tableLight.radius = struct.unpack("I", subrecord.data, 13, 13+4)
					tableLight.color = struct.unpack("I", subrecord.data, 17, 17+4)
					tableLight.flags = struct.unpack("I", subrecord.data, 21, 21+4)					
				end	
				if subrecord.name == "SNAM" then
					tableLight.sound = struct.unpack("s", subrecord.data)
				end					
				if subrecord.name == "SCRI" then
					tableLight.script = struct.unpack("s", subrecord.data)
				end				
			end
			DataLight[string.lower(tableLight.baseId)] = tableLight
		end	
		jsonInterface.save("custom/Ecarlate/DataLight.json", DataLight)

		local Npc = jsonInterface.load("custom/Ecarlate/DataNpc.json")	
		for _,record in pairs(espParser.getRecordsByName(file, "NPC_")) do
			tableNpc = {
				baseId = "",
				inventoryBaseId = "",
				model = "",						
				name = "",
				gender = "",				
				race = "",
				class = "",
				faction = "",
				head  = "",
				hair = "",
				script = "",
				level = "",	
				attributes = {},
				skills = {},	
				health = "",
				magicka = "",
				fatigue = "",				
				disposition = "",
				reputation = "",
				rank = "",
				gold = "",
				flags = "",
				bloodType = "",
				items = {},
				spells = {},
				aiHello = "",
				aiFight = "",
				aiFlee = "",
				aiAlarm = "",
				aiServices = "",
				scale =  "",
				autoCalc = ""
			}
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableNpc.baseId = struct.unpack("s", subrecord.data)
					tableNpc.inventoryBaseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableNpc.model = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "FNAM" then
					tableNpc.name = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "RNAM" then
					tableNpc.race = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "CNAM" then
					tableNpc.class = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "ANAM" then
					tableNpc.faction = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "BNAM" then
					tableNpc.head = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "KNAM" then
					tableNpc.hair = struct.unpack("s", subrecord.data)
				end					
				if subrecord.name == "SCRI" then
					tableNpc.script = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "NPDT" then
					if Npc[string.lower(tableNpc.baseId)].flags >= 24 then
						tableNpc.level = struct.unpack( "H", string.sub(subrecord.data, 1, 1+2))
						tableNpc.disposition = struct.unpack( "B", string.sub(subrecord.data, 3, 3+1))
						tableNpc.reputation = struct.unpack( "B", string.sub(subrecord.data, 4, 4+1))
						tableNpc.rank = struct.unpack( "B", string.sub(subrecord.data, 5, 5+1))
						tableNpc.gold = struct.unpack( "I", string.sub(subrecord.data, 9, 9+4))	
						tableNpc.autoCalc = 1
					else
						tableNpc.level = struct.unpack( "H", string.sub(subrecord.data, 1, 1+2))
						tableNpc.attributes.strength = struct.unpack( "B", string.sub(subrecord.data, 3, 3+1))
						tableNpc.attributes.intelligence = struct.unpack( "B", string.sub(subrecord.data, 4, 4+1))
						tableNpc.attributes.willpower = struct.unpack( "B", string.sub(subrecord.data, 5, 5+1))
						tableNpc.attributes.agility = struct.unpack( "B", string.sub(subrecord.data, 6, 6+1))
						tableNpc.attributes.speed = struct.unpack( "B", string.sub(subrecord.data, 7, 7+1))
						tableNpc.attributes.endurance = struct.unpack( "B", string.sub(subrecord.data, 8, 8+1))
						tableNpc.attributes.personality = struct.unpack( "B", string.sub(subrecord.data, 9, 9+1))
						tableNpc.attributes.luck = struct.unpack( "B", string.sub(subrecord.data, 10, 10+1))
						tableNpc.skills.block = struct.unpack( "B", string.sub(subrecord.data, 11, 11+1))
						tableNpc.skills.armorer = struct.unpack( "B", string.sub(subrecord.data, 12, 12+1))
						tableNpc.skills.mediumarmor = struct.unpack( "B", string.sub(subrecord.data, 13, 13+1))
						tableNpc.skills.heavyarmor = struct.unpack( "B", string.sub(subrecord.data, 14, 14+1))
						tableNpc.skills.bluntweapon = struct.unpack( "B", string.sub(subrecord.data, 15, 15+1))
						tableNpc.skills.longblade = struct.unpack( "B", string.sub(subrecord.data, 16, 16+1))
						tableNpc.skills.axe = struct.unpack( "B", string.sub(subrecord.data, 17, 17+1))
						tableNpc.skills.spear =  struct.unpack( "B", string.sub(subrecord.data, 18, 18+1))
						tableNpc.skills.athletics = struct.unpack( "B", string.sub(subrecord.data, 19, 19+1))
						tableNpc.skills.enchant = struct.unpack( "B", string.sub(subrecord.data, 20, 20+1))
						tableNpc.skills.destruction = struct.unpack( "B", string.sub(subrecord.data, 21, 21+1))
						tableNpc.skills.alteration = struct.unpack( "B", string.sub(subrecord.data, 22, 22+1))
						tableNpc.skills.illusion = struct.unpack( "B", string.sub(subrecord.data, 23, 23+1))
						tableNpc.skills.conjuration = struct.unpack( "B", string.sub(subrecord.data, 24, 24+1))
						tableNpc.skills.mysticism = struct.unpack( "B", string.sub(subrecord.data, 25, 25+1))
						tableNpc.skills.restoration = struct.unpack( "B", string.sub(subrecord.data, 26, 26+1))
						tableNpc.skills.alchemy = struct.unpack( "B", string.sub(subrecord.data, 27, 27+1))
						tableNpc.skills.unarmored = struct.unpack( "B", string.sub(subrecord.data, 28, 28+1))
						tableNpc.skills.security = struct.unpack( "B", string.sub(subrecord.data, 29, 29+1))
						tableNpc.skills.sneak = struct.unpack( "B", string.sub(subrecord.data, 30, 30+1))
						tableNpc.skills.acrobatics = struct.unpack( "B", string.sub(subrecord.data, 31, 31+1))
						tableNpc.skills.lightarmor = struct.unpack( "B", string.sub(subrecord.data, 32, 32+1)) 
						tableNpc.skills.shortblade = struct.unpack( "B", string.sub(subrecord.data, 33, 33+1))
						tableNpc.skills.marksman = struct.unpack( "B", string.sub(subrecord.data, 34, 34+1))
						tableNpc.skills.mercantile = struct.unpack( "B", string.sub(subrecord.data, 35, 35+1))
						tableNpc.skills.speechcraft = struct.unpack( "B", string.sub(subrecord.data, 36, 36+1))
						tableNpc.skills.handtohand = struct.unpack( "B", string.sub(subrecord.data, 37, 37+1))
						tableNpc.health = struct.unpack( "H", string.sub(subrecord.data, 39, 39+2)) 
						tableNpc.magicka = struct.unpack( "H", string.sub(subrecord.data, 41, 41+2))
						tableNpc.fatigue = struct.unpack( "H", string.sub(subrecord.data, 43, 43+2)) 
						tableNpc.disposition = struct.unpack( "B", string.sub(subrecord.data, 45, 45+1))
						tableNpc.reputation = struct.unpack( "B", string.sub(subrecord.data, 46, 46+1))
						tableNpc.rank = struct.unpack( "B", string.sub(subrecord.data, 47, 47+1))
						tableNpc.gold = struct.unpack( "I", string.sub(subrecord.data, 49, 49+4))
						tableNpc.autoCalc = 0						
					end
				end	
				if subrecord.name == "FLAG" then
					tableNpc.flags = struct.unpack( "I", string.sub(subrecord.data, 1, 1+4))
					if (tableNpc.flags % 2 == 0) then
						tableNpc.gender = 1
					else
						tableNpc.gender = 0					
					end
					if tableNpc.flags >= 1024 and tableNpc.flags < 2048 then
						tableNpc.bloodType = "skeleton"
					elseif tableNpc.flags >= 2048 then
						tableNpc.bloodType = "metalsparks"
					end
				end	
				if subrecord.name == "NPCO" then
					local item = {id = "", count = ""}
					item.count = struct.unpack( "i", string.sub(subrecord.data, 1, 1+4))		
					item.id = struct.unpack( "s", string.sub(subrecord.data, 5))
					table.insert(tableNpc.items, item)
				end	
				if subrecord.name == "NPCS" then
					local spell = {refId = ""}
					spell.refId = struct.unpack( "s", string.sub(subrecord.data, 1))
					table.insert(tableNpc.spells, spell)					
				end	
				if subrecord.name == "AIDT" then
					tableNpc.aiHello = struct.unpack( "b", string.sub(subrecord.data, 1, 1+1))					
					tableNpc.aiFight = struct.unpack( "b", string.sub(subrecord.data, 3, 3+1))	
					tableNpc.aiFlee = struct.unpack( "b", string.sub(subrecord.data, 4, 4+1))	
					tableNpc.aiAlarm = struct.unpack( "b", string.sub(subrecord.data, 5, 5+1))	
					tableNpc.aiServices = struct.unpack( "I", string.sub(subrecord.data, 9, 9+4))						
				end								
			end
			if tableNpc.scale == "" then tableNpc.scale = 1 end
			DataNpc[string.lower(tableNpc.baseId)] = tableNpc
		end	
		jsonInterface.save("custom/Ecarlate/DataNpc.json", DataNpc)	

		for _,record in pairs(espParser.getRecordsByName(file, "INFO")) do
			local code = ""
			tableInfo = {
				baseId = "",
				previousId = "",				
				nextId = "",
				dialType = "",
				disposition = "",
				rank = "",
				gender = "",
				pcRank = "",
				actor = "",
				race = "",
				class = "",
				faction = "",
				cell = "",
				pcFaction = "",
				sound = "",
				repText = "",
				variable = {},
				resultText = "",
				questName = "",
				questFinished = "",
				questRestart = ""	
			}
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "INAM" then
					tableInfo.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "PNAM" then
					tableInfo.previousId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "NNAM" then
					tableInfo.nextId = struct.unpack("s", subrecord.data)
				end				
				if subrecord.name == "DATA" then
					tableInfo.dialType = struct.unpack( "b", string.sub(subrecord.data, 1, 1+1))
					tableInfo.disposition = struct.unpack( "I", string.sub(subrecord.data, 4, 4+4))
					tableInfo.rank = struct.unpack( "b", string.sub(subrecord.data, 8, 8+1))	
					tableInfo.gender = struct.unpack( "b", string.sub(subrecord.data, 9, 9+1))
					tableInfo.pcRank = struct.unpack( "b", string.sub(subrecord.data, 10, 10+1))					
				end	
				if subrecord.name == "ONAM" then
					tableInfo.actor = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "RNAM" then
					tableInfo.race = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "CNAM" then
					tableInfo.class = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "FNAM" then
					tableInfo.faction = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "ANAM" then
					tableInfo.cell = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "DNAM" then
					tableInfo.pcFaction = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "SNAM" then
					tableInfo.sound = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "NAME" then
					tableInfo.repText = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "SCVR" then
					tableInfo.variable[struct.unpack("s", subrecord.data)] = ""
					code = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "INTV" then
					tableInfo.variable[code] = struct.unpack("I", string.sub(subrecord.data, 1, 1+4))
				end	
				if subrecord.name == "FLTV" then
					tableInfo.variable[code] = struct.unpack("I", string.sub(subrecord.data, 1, 1+4))
				end		
				if subrecord.name == "BNAM" then
					tableInfo.resultText = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "QSTN" then
					tableInfo.questName = true
				elseif subrecord.name == "QSTF" then
					tableInfo.questFinished = true
				elseif subrecord.name == "QSTR" then
					tableInfo.questRestart = true
				end					
			end
			DataInfo[string.lower(tableInfo.baseId)] = tableInfo
		end	
		jsonInterface.save("custom/Ecarlate/DataInfo.json", DataInfo)

		for _,record in pairs(espParser.getRecordsByName(file, "DIAL")) do
			tableDial = {
				baseId = "",
				subtype = ""
			}
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableDial.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "DATA" then
					tableDial.subtype = struct.unpack( "b", string.sub(subrecord.data, 1, 1+1) )
				end					
			end
			DataDial[string.lower(tableDial.baseId)] = tableDial
		end	
		jsonInterface.save("custom/Ecarlate/DataDial.json", DataDial)

		for _,record in pairs(espParser.getRecordsByName(file, "CREA")) do
			tableCreature = {
				baseId = "",
				name = "",
				model = "",				
				script = "",
				scale = "",
				objects = {},
				bloodType = "",
				subtype = "",
				level = "",
				health = "",
				magicka = "",
				fatigue = "",
				soulValue = "",
				damageChop = {min = "", max = ""},
				damageSlash = {min = "", max = ""},
				damageThrust = {min = "", max = ""},
				aiFight = "",
				aiFlee = "",
				aiAlarm = "",
				aiServices = "",
				flags = ""
			}
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableCreature.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableCreature.model = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "FNAM" then
					tableCreature.name = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "SCRI" then
					tableCreature.script = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "XSCL" then
					tableCreature.scale = struct.unpack("f", subrecord.data) or 1
				end	
				if subrecord.name == "NPCO" then
					local item = {refId = "", count = ""}
					item.count = struct.unpack( "i", string.sub(subrecord.data, 1, 1+4))		
					item.refId = struct.unpack( "s", string.sub(subrecord.data, 5))
					table.insert(tableCreature.objects, item)
				end					
				if subrecord.name == "FLAG" then		
					if struct.unpack("I", subrecord.data) > 1024 and struct.unpack("I", subrecord.data) < 2048 then
						tableCreature.flags = struct.unpack("I", subrecord.data) - 1024
						tableCreature.bloodType = 1024
					elseif struct.unpack("I", subrecord.data) > 2048 then
						tableCreature.flags = struct.unpack("I", subrecord.data) - 2048
						tableCreature.bloodType = 2048
					else
						tableCreature.flags = struct.unpack("I", subrecord.data)
					end
				end					
				if subrecord.name == "NPDT" then
					tableCreature.subtype = struct.unpack( "i", string.sub(subrecord.data, 1, 1+4))	
					tableCreature.level = struct.unpack( "i", string.sub(subrecord.data, 5, 5+4))
					--tableCreature.attribute = struct.unpack( "i", string.sub(subrecord.data, 9, 9+4))	
					--tableCreature.attribute = struct.unpack( "i", string.sub(subrecord.data, 13, 9+4))	
					--tableCreature.attribute = struct.unpack( "i", string.sub(subrecord.data, 17, 9+4))	
					--tableCreature.attribute = struct.unpack( "i", string.sub(subrecord.data, 21, 9+4))	
					--tableCreature.attribute = struct.unpack( "i", string.sub(subrecord.data, 25, 9+4))	
					--tableCreature.attribute = struct.unpack( "i", string.sub(subrecord.data, 29, 9+4))	
					--tableCreature.attribute = struct.unpack( "i", string.sub(subrecord.data, 33, 9+4))	
					--tableCreature.attribute = struct.unpack( "i", string.sub(subrecord.data, 37, 9+4))						
					tableCreature.health = struct.unpack( "i", string.sub(subrecord.data, 41, 41+4))
					tableCreature.magicka = struct.unpack( "i", string.sub(subrecord.data, 45, 45+4))
					tableCreature.fatigue = struct.unpack( "i", string.sub(subrecord.data, 49, 49+4))
					tableCreature.soulValue = struct.unpack( "i", string.sub(subrecord.data, 53, 53+4))
					--tableCreature.combat = struct.unpack( "i", string.sub(subrecord.data, 57, 57+4))	
					--tableCreature.magic = struct.unpack( "i", string.sub(subrecord.data, 61, 61+4))	
					--tableCreature.stealth = struct.unpack( "i", string.sub(subrecord.data, 65, 65+4))						
					tableCreature.damageChop.min = struct.unpack( "i", string.sub(subrecord.data, 69, 69+4))
					tableCreature.damageChop.max = struct.unpack( "i", string.sub(subrecord.data, 73, 73+4))
					tableCreature.damageSlash.min = struct.unpack( "i", string.sub(subrecord.data, 77, 77+4))	
					tableCreature.damageSlash.max = struct.unpack( "i", string.sub(subrecord.data, 81, 81+4))
					tableCreature.damageThrust.min = struct.unpack( "i", string.sub(subrecord.data, 85, 85+4))	
					tableCreature.damageThrust.max = struct.unpack( "i", string.sub(subrecord.data, 89, 89+4))
					--tableCreature.gold = struct.unpack( "i", string.sub(subrecord.data, 93, 93+4))					
				end	
				if subrecord.name == "AIDT" then
					tableCreature.aiFight = struct.unpack( "b", string.sub(subrecord.data, 3, 3+1))	
					tableCreature.aiFlee = struct.unpack( "b", string.sub(subrecord.data, 4, 4+1))	
					tableCreature.aiAlarm = struct.unpack( "b", string.sub(subrecord.data, 5, 5+1))	
					tableCreature.aiServices = struct.unpack( "I", string.sub(subrecord.data, 9, 9+4))						
				end					
			end
			if tableCreature.scale == "" then tableCreature.scale = 1 end
			DataCreature[string.lower(tableCreature.baseId)] = tableCreature
		end	
		jsonInterface.save("custom/Ecarlate/DataCreature.json", DataCreature)
		
		for _,record in pairs(espParser.getRecordsByName(file, "CONT")) do
			tableContainer = {
				baseId = "",
				name = "",
				model = "",				
				script = "",
				weight = "",
				flags = "",
				objects = {}
			}
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableContainer.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableContainer.model = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "FNAM" then
					tableContainer.name = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "SCRI" then
					tableContainer.script = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "CNDT" then
					tableContainer.weight = struct.unpack("f", subrecord.data)
				end	
				if subrecord.name == "FLAG" then
					tableContainer.flags = struct.unpack("i", subrecord.data)
				end	
				if subrecord.name == "NPCO" then
					local item = {refId = "", count =  ""}
					item.count = struct.unpack("i", subrecord.data, 1, 1+4)
					item.refId = struct.unpack("s", subrecord.data, 5)					
					table.insert(tableContainer.objects, item)
				end				
			end
			DataContainer[string.lower(tableContainer.baseId)] = tableContainer
		end	
		jsonInterface.save("custom/Ecarlate/DataContainer.json", DataContainer)
		
		for _,record in pairs(espParser.getRecordsByName(file, "CLOT")) do
			tableClothing = {
				baseId = "",
				name = "",
				model = "",	
				icon = "",				
				script = "",
				enchantmentId = "",
				enchantmentCharge = "",
				subtype = "",
				weight = "",
				value = ""
			}
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableClothing.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableClothing.model = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "FNAM" then
					tableClothing.name = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "SCRI" then
					tableClothing.script = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "ITEX" then
					tableClothing.icon = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "ENAM" then
					tableClothing.enchantmentId = struct.unpack("s", subrecord.data)
				end					
				if subrecord.name == "CTDT" then
					tableClothing.subtype = struct.unpack( "i", string.sub(subrecord.data, 1, 1+4))	
					tableClothing.weight = struct.unpack( "f", string.sub(subrecord.data, 5, 5+4))	
					tableClothing.value = struct.unpack( "h", string.sub(subrecord.data, 9, 9+2))
					tableClothing.enchantmentCharge = struct.unpack( "h", string.sub(subrecord.data, 11, 11+2))						
				end					
			end
			DataClothing[string.lower(tableClothing.baseId)] = tableClothing
		end	
		jsonInterface.save("custom/MoonHand/DataClothing.json", DataClothing)
		
		for _,record in pairs(espParser.getRecordsByName(file, "BOOK")) do
			tableBook = {
				baseId = "",
				name = "",				
				script = "",
				icon = "",
				model = "",
				enchantmentId = "",
				enchantmentCharge = "",
				text = "",
				weight = "",
				value = "",
				scrollState = "",
				skillId = ""	
			}
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableBook.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableBook.model = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "FNAM" then
					tableBook.name = struct.unpack("s", subrecord.data)
				end		
				if subrecord.name == "SCRI" then
					tableBook.script = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "ITEX" then
					tableBook.icon = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "TEXT" then
					tableBook.text = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "ENAM" then
					tableBook.enchantmentId = struct.unpack("s", subrecord.data)
				end					
				if subrecord.name == "BKDT" then
					tableBook.weight = struct.unpack( "f", string.sub(subrecord.data, 1, 1+4))	
					tableBook.value = struct.unpack( "i", string.sub(subrecord.data, 5, 5+4))	
					tableBook.scrollState = struct.unpack( "i", string.sub(subrecord.data, 9, 9+4))
					tableBook.skillId = struct.unpack( "i", string.sub(subrecord.data, 13, 13+4))	
					tableBook.enchantmentCharge = struct.unpack( "i", string.sub(subrecord.data, 17, 17+4))						
				end					
			end
			DataBook[string.lower(tableBook.baseId)] = tableBook
		end	
		jsonInterface.save("custom/MoonHand/DataBook.json", DataBook)
		
		for _,record in pairs(espParser.getRecordsByName(file, "BODY")) do
			tableBody = {
				baseId = "",
				subtype = "",
				part = "",
				model = "",
				race = "",
				vampireState = "",
				flags = ""			
			}
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableBody.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableBody.model = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "FNAM" then
					tableBody.race = struct.unpack("s", subrecord.data)
				end					
				if subrecord.name == "BYDT" then
					tableBody.subtype = struct.unpack( "b", string.sub(subrecord.data, 1, 1+1))	
					tableBody.vampireState = struct.unpack( "b", string.sub(subrecord.data, 2, 2+1))	
					tableBody.flags = struct.unpack( "b", string.sub(subrecord.data, 3, 3+1))
					tableBody.part = struct.unpack( "b", string.sub(subrecord.data, 4, 4+1))						
				end					
			end
			DataBody[string.lower(tableBody.baseId)] = tableBody
		end	
		jsonInterface.save("custom/MoonHand/DataBody.json", DataBody)
		
		for _,record in pairs(espParser.getRecordsByName(file, "APPA")) do
			tableApparatus = {
				baseId = "",
				name = "",
				model = "",
				icon = "",
				script = "",
				subtype = "",
				weight = "",
				value = "",
				quality = ""
			}
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					tableApparatus.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "FNAM" then
					tableApparatus.name = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "MODL" then
					tableApparatus.model = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "SCRI" then
					tableApparatus.script = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "ITEX" then
					tableApparatus.icon = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "AADT" then
					tableApparatus.subtype = struct.unpack( "I", string.sub(subrecord.data, 1, 1+4))
					tableApparatus.quality = struct.unpack( "f", string.sub(subrecord.data, 5, 5+4))					
					tableApparatus.weight = struct.unpack( "f", string.sub(subrecord.data, 9, 9+4))
					tableApparatus.value = struct.unpack( "I", string.sub(subrecord.data, 13, 13+4))					
				end					
			end
			DataApparatus[string.lower(tableApparatus.baseId)] = tableApparatus
		end	
		jsonInterface.save("custom/MoonHand/DataApparatus.json", DataApparatus)

		for _,record in pairs(espParser.getRecordsByName(file, "ALCH")) do
			tableAlchemy = {
				baseId = "",
				name = "",
				model = "",
				icon = "",
				script = "",
				weight = "",
				value = "",
				autoCalc = "",
				effects = {}
			}
			for _, subrecord in pairs(record.subRecords) do
				local enchantList = {}
				if subrecord.name == "NAME" then
					tableAlchemy.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "FNAM" then
					tableAlchemy.name = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "MODL" then
					tableAlchemy.model = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "SCRI" then
					tableAlchemy.script = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "TEXT" then
					tableAlchemy.icon = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "ALDT" then
					tableAlchemy.weight = struct.unpack( "f", string.sub(subrecord.data, 1, 1+4))
					tableAlchemy.value = struct.unpack( "I", string.sub(subrecord.data, 5, 5+4))
					tableAlchemy.autoCalc = struct.unpack( "I", string.sub(subrecord.data, 9, 9+4))					
				end	
				if subrecord.name == "ENAM" then
					enchantList.id = struct.unpack( "H", string.sub(subrecord.data, 1, 1+2) )	
					enchantList.skill = struct.unpack( "b", string.sub(subrecord.data, 3, 3+1) )
					enchantList.attribute = struct.unpack( "b", string.sub(subrecord.data, 4, 4+1) )
					enchantList.rangeType = struct.unpack( "I", string.sub(subrecord.data, 5, 5+4) )
					enchantList.area = struct.unpack( "I", string.sub(subrecord.data, 9, 9+4) )	
					enchantList.duration = struct.unpack( "I", string.sub(subrecord.data, 13, 13+4) )
					enchantList.magnitudeMin = struct.unpack( "I", string.sub(subrecord.data, 17, 17+4) )
					enchantList.magnitudeMax = struct.unpack( "I", string.sub(subrecord.data, 21, 21+4) )	
					table.insert(tableAlchemy.effects, enchantList)
				end					
			end
			DataAlchemy[string.lower(tableAlchemy.baseId)] = tableAlchemy
		end	
		jsonInterface.save("custom/Ecarlate/DataAlchemy.json", DataAlchemy)
	
		for _,record in pairs(espParser.getRecordsByName(file, "ACTI")) do
			tableActivator = {
				baseId = "",
				name = "",
				model = "",
				script = ""
			}
			for _, subrecord in pairs(record.subRecords) do
				local enchantList = {}
				if subrecord.name == "NAME" then
					tableActivator.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "FNAM" then
					tableActivator.name = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "MODL" then
					tableActivator.model = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "SCRI" then
					tableActivator.script = struct.unpack("s", subrecord.data)
				end							
			end
			DataActivator[string.lower(tableActivator.baseId)] = tableActivator
		end	
		jsonInterface.save("custom/Ecarlate/DataActivator.json", DataActivator)

		for _,record in pairs(espParser.getRecordsByName(file, "SPEL")) do
			tableSpell = {
				baseId = "",
				name = "",
				subtype = "",
				cost = "",
				flags = "",
				effects = {}
			}
			for _, subrecord in pairs(record.subRecords) do
				local enchantList = {}
				if subrecord.name == "NAME" then
					tableSpell.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "FNAM" then
					tableSpell.name = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "SPDT" then
					tableSpell.subtype = struct.unpack( "I", string.sub(subrecord.data, 1, 1+4))
					tableSpell.cost = struct.unpack( "I", string.sub(subrecord.data, 5, 5+4))	
					tableSpell.flags = struct.unpack( "I", string.sub(subrecord.data, 9, 9+4))
				end	
				if subrecord.name == "ENAM" then
					enchantList.id = struct.unpack( "H", string.sub(subrecord.data, 1, 1+2) )	
					enchantList.skill = struct.unpack( "b", string.sub(subrecord.data, 3, 3+1) )
					enchantList.attribute = struct.unpack( "b", string.sub(subrecord.data, 4, 4+1) )
					enchantList.rangeType = struct.unpack( "I", string.sub(subrecord.data, 5, 5+4) )
					enchantList.area = struct.unpack( "I", string.sub(subrecord.data, 9, 9+4) )	
					enchantList.duration = struct.unpack( "I", string.sub(subrecord.data, 13, 13+4) )
					enchantList.magnitudeMin = struct.unpack( "I", string.sub(subrecord.data, 17, 17+4) )
					enchantList.magnitudeMax = struct.unpack( "I", string.sub(subrecord.data, 21, 21+4) )	
					table.insert(tableSpell.effects, enchantList)
				end					
			end
			DataSpell[string.lower(tableSpell.baseId)] = tableSpell
		end	
		jsonInterface.save("custom/MoonHand/DataSpell.json", DataSpell)

		for _,record in pairs(espParser.getRecordsByName(file, "WEAP")) do
			tableWeap = {
				baseId = "",
				model = "",		
				name = "",
				subtype = "",
				weight = "",
				value = "",
				health = "",
				speed = "",
				reach = "",
				damageChop = { min = "", max = "" },
				damageSlash = { min = "", max = "" },
				damageThrust = { min = "", max = "" },
				flags = "",
				enchantmentCharge = "",
				icon = "",
				enchantmentId = "",
				script = ""				
			}
			for _, subrecord in pairs(record.subRecords) do
				local enchantList = {}
				if subrecord.name == "NAME" then
					tableWeap.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableWeap.model = struct.unpack("s", subrecord.data)
				end					
				if subrecord.name == "FNAM" then
					tableWeap.name = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "ITEX" then
					tableWeap.icon = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "ENAM" then
					tableWeap.enchantmentId = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "SCRI" then
					tableWeap.script = struct.unpack("s", subrecord.data)
				end				
				if subrecord.name == "WPDT" then
					tableWeap.weight = struct.unpack( "f", string.sub(subrecord.data, 1, 1+4))
					tableWeap.value = struct.unpack( "I", string.sub(subrecord.data, 5, 5+4))
					tableWeap.subtype = struct.unpack( "H", string.sub(subrecord.data, 9, 9+2))	
					tableWeap.health = struct.unpack( "H", string.sub(subrecord.data, 11, 11+2))
					tableWeap.speed = struct.unpack( "f", string.sub(subrecord.data, 13, 13+4))	
					tableWeap.reach = struct.unpack( "f", string.sub(subrecord.data, 17, 17+4))							
 					tableWeap.enchantmentCharge = struct.unpack("H", string.sub(subrecord.data, 21, 21+2))	
					tableWeap.damageChop.min = struct.unpack("B", string.sub(subrecord.data, 23, 23+1))
					tableWeap.damageChop.max = struct.unpack( "B", string.sub(subrecord.data, 24, 24+1))
					tableWeap.damageSlash.min = struct.unpack( "B", string.sub(subrecord.data, 25, 25+1))
					tableWeap.damageSlash.max = struct.unpack( "B", string.sub(subrecord.data, 26, 26+1))
					tableWeap.damageThrust.min = struct.unpack( "B", string.sub(subrecord.data, 27, 27+1))
					tableWeap.damageThrust.max = struct.unpack( "B", string.sub(subrecord.data, 28, 28+1))
					tableWeap.flags = struct.unpack( "I", string.sub(subrecord.data, 29, 29+4))						
				end						
			end
			DataWeapon[string.lower(tableWeap.baseId)] = tableWeap
		end	
		jsonInterface.save("custom/MoonHand/DataWeapon.json", DataWeapon)

		for _,record in pairs(espParser.getRecordsByName(file, "ARMO")) do
			tableArmor = {
				baseId = "",
				model = "",		
				name = "",
				script = "",
				subtype = "",
				weight = "",
				value = "",
				health = "",
				enchantmentCharge = "",
				armorRating = "",
				icon = "",
				enchantmentId = ""
			}
			for _, subrecord in pairs(record.subRecords) do
				local enchantList = {}
				if subrecord.name == "NAME" then
					tableArmor.baseId = struct.unpack("s", subrecord.data)
				end
				if subrecord.name == "MODL" then
					tableArmor.model = struct.unpack("s", subrecord.data)
				end					
				if subrecord.name == "FNAM" then
					tableArmor.name = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "SCRI" then
					tableArmor.script = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "AODT" then
					tableArmor.subtype = struct.unpack( "I", string.sub(subrecord.data, 1, 1+4))
					tableArmor.weight = struct.unpack( "f", string.sub(subrecord.data, 5, 5+4))
					tableArmor.value = struct.unpack( "I", string.sub(subrecord.data, 9, 9+4))	
					tableArmor.health = struct.unpack( "I", string.sub(subrecord.data, 13, 13+4))	
 					tableArmor.enchantmentCharge = struct.unpack( "I", string.sub(subrecord.data, 17, 17+4))	
					tableArmor.armorRating = struct.unpack( "I", string.sub(subrecord.data, 21, 21+4))	
				end	
				if subrecord.name == "ITEX" then
					tableArmor.icon = struct.unpack("s", subrecord.data)
				end	
				if subrecord.name == "ENAM" then
					tableArmor.enchantmentId = struct.unpack("s", subrecord.data)
				end					
			end
			DataArmor[string.lower(tableArmor.baseId)] = tableArmor
		end	
		jsonInterface.save("custom/MoonHand/DataArmor.json", DataArmor)
	end
	
	for x, file in pairs(config.files) do
		for _,record in pairs(espParser.getRecordsByName(file, "MGEF")) do
			local effect = ""
			local school = ""
			local cost = ""
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "INDX" then
					effect = struct.unpack( "I", string.sub(subrecord.data, 1, 1+4) )	
				elseif subrecord.name == "MEDT" then
					school = struct.unpack("I", string.sub(subrecord.data, 1, 1+4) )	
					cost = struct.unpack("f", string.sub(subrecord.data, 5, 5+4) )						
				end	
			end
			if school == 0 then
				school = "Alteration"
			elseif school == 1 then
				school = "Conjuration"
			elseif school == 2 then
				school = "Destruction"			
			elseif school == 3 then
				school = "Illusion"			
			elseif school == 4 then
				school = "Mysticism"			
			elseif school == 5 then
				school = "Restoration"			
			end
			DataBaseCreatureContent[effect] = {effect = effect, school = school, cost = cost}
		end			
	end
	table.sort(DataBaseCreatureContent, function(a, b) return a.effect<b.effect end)
	jsonInterface.save("custom/CellDataBaseGrass/SchoolData.json", DataBaseCreatureContent)	
	
	for x, file in pairs(config.files) do
		for _,record in pairs(espParser.getRecordsByName(file, "STAT")) do
			local refId = ""
			local model = ""
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					refId = struct.unpack("s", subrecord.data)
				elseif subrecord.name == "MODL" then
					model = struct.unpack("s", subrecord.data)
				end	
			end
			DataBaseCreatureContent[string.lower(refId)] = {name = refId, model = model}
		end	
	end
	jsonInterface.save("custom/CellDataBaseGrass/StaticData.json", DataBaseCreatureContent)	
	
	for x, file in pairs(config.files) do
		local records = (espParser.getRecordsByName(file, "CELL"))
		local dataTypes = {
			Unique = {
				{"NAME", "s", "name"}, --cell description
				{"DATA", {
					{"i", "flags"},
					{"i", "gridX"},
					{"i", "gridY"}
				}},
				{"INTV", "i", "water"}, --water height stored in a int (didn't know about this one until I checked the openmw source, no idea why theres 2 of them)
				{"WHGT", "f", "water"}, --water height stored in a float
				{"AMBI", {
					{"i", "ambientColor"},
					{"i", "sunlightColor"},
					{"i", "fogColor"},
					{"f", "fogDensity"}
				}},
				{"RGNN", "s", "region"}, --the region name like "Azura's Coast" used for weather and stuff
				{"NAM5", "i", "mapColor"},
				{"NAM0", "i", "refNumCounter"} --when you add a new object to the cell in the editor it gets this refNum then this variable is incremented 
			},
			Multi = {
				{"NAME", "s", "refId"},
				{"XSCL", "f", "scale"},
				{"DELE", "i", "deleted"}, --rip my boi
				{"DNAM", "s", "destCell"}, --the name of the cell the door takes you too
				{"FLTV", "i", "lockLevel"}, --door lock level
				{"KNAM", "s", "key"}, --key refId
				{"TNAM", "s", "trap"}, --trap spell refId
				{"UNAM", "B", "referenceBlocked"},
				{"ANAM", "s", "owner"}, --the npc owner or the item
				{"BNAM", "s", "globalVariable"}, -- Global variable for use in scripts?
				{"INTV", "i", "charge"}, --current charge?
				{"NAM9", "i", "goldValue"}, --https://github.com/OpenMW/openmw/blob/dcd381049c3b7f9779c91b2f6b0f1142aff44c4a/components/esm/cellref.cpp#L163
				{"XSOL", "s", "soul"},
				{"CNAM", "s", "faction"}, --faction who owns the item
				{"INDX", "i", "factionRank"}, --what rank you need to be in the faction to pick it up without stealing?
				{"XCHG", "i", "enchantmentCharge"}, --max charge?
				{"DODT", {
					{"f", "XPos"},
					{"f", "YPos"},
					{"f", "ZPos"},
					{"f", "XRot"},
					{"f", "YRot"},
					{"f", "ZRot"}
				}, "doorDest"}, --the position the door takes you too
				{"DATA", {
					{"f", "XPos"},
					{"f", "YPos"},
					{"f", "ZPos"},
					{"f", "XRot"},
					{"f", "YRot"},
					{"f", "ZRot"}
				}, "pos"} --the position of the object
			}
		}
		
		for _, record in pairs(records) do
			local cell = {}
			
			for _, dType in pairs(dataTypes.Unique) do
				local tempData = record:getSubRecordsByName(dType[1])[1]
				if tempData ~= nil then
					if type(dType[2]) == "table" then
						local stream = espParser.Stream:create( tempData.data )
						for _, ddType in pairs(dType[2]) do
							cell[ ddType[2] ] = struct.unpack( ddType[1], stream:read(4) )
						end
					else
						cell[ dType[3] ] = struct.unpack( dType[2], tempData.data )
					end
				end
			end
			if string.find(string.lower(cell.name), "longsanglot") then
				cell.isExterior = false
			else
			
				if cell.region ~= nil or cell.name == "" then --its a external cell
					cell.isExterior = true
					cell.name = cell.gridX .. ", " .. cell.gridY
				else --its a internal cell
					cell.isExterior = false
				end	
			end
			
			cell.objects = {}
			local currentIndex = nil
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "FRMR" then
					currentIndex = struct.unpack( "i", subrecord.data )
					cell.objects[currentIndex] = {}
					cell.objects[currentIndex].refNum = currentIndex
					cell.objects[currentIndex].scale = 1 --just a default
				end
					
				for _, dType in pairs(dataTypes.Multi) do
					if subrecord.name == dType[1] and currentIndex ~= nil then --if its a subrecord in dataTypes.Multi
						if type(dType[2]) == "table" then --there are several values in this data
							local stream = espParser.Stream:create( subrecord.data )
							for _, ddType in pairs(dType[2]) do --go thrue every value that we want out of this data
								if dType[3] ~= nil then --store the values in a table
									if cell.objects[currentIndex][ dType[3] ] == nil then
										cell.objects[currentIndex][ dType[3] ] = {}
									end
									cell.objects[currentIndex][ dType[3] ][ ddType[2] ] = struct.unpack( ddType[1], stream:read(4) )
								else --store the values directly in the cell
									cell.objects[currentIndex][ ddType[2] ] = struct.unpack( ddType[1], lenTable[ ddType[1] ] )
								end
							end
						else -- theres only one value in the data
							cell.objects[currentIndex][ dType[3] ] = struct.unpack( dType[2], subrecord.data )
						end
					end
				end
			end
			local jsonCellName = cell.name
			local checkString = string.find(cell.name, ":")
			if checkString then
				jsonCellName = string.gsub(cell.name, ":", ";")
			end	
			jsonCellName = Normalize.stripChars(jsonCellName)		
			if not DataBaseCellContent[jsonCellName] then
				DataBaseCellContent[jsonCellName] = cell

			else
				if cell.objects then
					for index, slot in pairs(cell.objects) do
						DataBaseCellContent[jsonCellName].objects[index] = cell.objects[index]
					end
				end
			end

			tes3mp.LogMessage(enumerations.log.ERROR, jsonCellName)
			jsonInterface.save("custom/Ecarlate/Cell/"..jsonCellName..".json", DataBaseCellContent[jsonCellName])

			DataBaseListCell[jsonCellName] = true
		end			
	end
	jsonInterface.save("custom/Ecarlate/CellDataList.json", DataBaseListCell)	
	
	for x, file in pairs(config.files) do
		for _,record in pairs(espParser.getRecordsByName(file, "BODY")) do	

			local id, index

			for _,subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					id = struct.unpack("s", subrecord.data)			
				--elseif subrecord.name == "INDX" then
					--index = struct.unpack("b",subrecord.data)			
				end
			end

			local headType			
			if string.find(id, "hair") then 
				headType = "hair"
			elseif string.find(id, "head") then 
				headType = "head"
			end
			
			local raceType			
			if string.find(id, "wood elf") then
				raceType = "wood elf"
			elseif string.find(id, "argonian") then
				raceType = "argonian"		
			elseif string.find(id, "breton") then
				raceType = "breton"		
			elseif string.find(id, "dark elf") then
				raceType = "dark elf"		
			elseif string.find(id, "high elf") then
				raceType = "high elf"		
			elseif string.find(id, "imperial") then
				raceType = "imperial"		
			elseif string.find(id, "khajiit") then
				raceType = "khajiit"		
			elseif string.find(id, "nord") then
				raceType = "nord"
			elseif string.find(id, "orc") then
				raceType = "orc"
			elseif string.find(id, "redguard") then
				raceType = "redguard"		
			end
			
			if headType == "head" then
				if DataBase.Head[raceType] then
					table.insert(DataBase.Head[raceType], id)
				else
					DataBase.Head[raceType] = {}
					table.insert(DataBase.Head[raceType], id)
				end
			elseif headType == "hair" then
				if DataBase.Hair[raceType] then
					table.insert(DataBase.Hair[raceType], id)
				else
					DataBase.Hair[raceType] = {}
					table.insert(DataBase.Hair[raceType], id)
				end
			end

			jsonInterface.save("custom/CellDataBaseGrass/CellDataBaseHairHead.json", DataBase)	
		end
	end
	
	for x, file in pairs(config.files) do
		for _,record in pairs(espParser.getRecordsByName(file, "STAT")) do
			local refId = ""
			local model = ""
			for _, subrecord in pairs(record.subRecords) do
				if subrecord.name == "NAME" then
					refId = struct.unpack("s", subrecord.data)
				elseif subrecord.name == "MODL" then
					model = struct.unpack("s", subrecord.data)
				end	
				if string.find(refId, "rock") then
					DataBaseCreatureContent[string.lower(refId)] = {model = model, name = "Rock", value = 0, weight = 0}
				elseif string.find(refId, "tree") then
					DataBaseCreatureContent[string.lower(refId)] = {model = model, name = "Tree", value = 0, weight = 0}
				end
			end
		end	
	end
	jsonInterface.save("custom/CellDataBaseGrass/CellDataBaseMisc.json", DataBaseCreatureContent)	
]]

customEventHooks.registerHandler("OnServerPostInit", DataBaseScript.CreateJsonDataBase)

return DataBaseScript
