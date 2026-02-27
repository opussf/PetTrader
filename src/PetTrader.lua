PT_SLUG, PT = ...
PT.MSG_ADDONNAME = C_AddOns.GetAddOnMetadata( PT_SLUG, "Title" )
PT.MSG_VERSION   = C_AddOns.GetAddOnMetadata( PT_SLUG, "Version" )
PT.MSG_AUTHOR    = C_AddOns.GetAddOnMetadata( PT_SLUG, "Author" )
PT.commPrefix = "PT1"

function PT:OnLoad()
	SLASH_PT1 = "/PT"
	SlashCmdList["PT"] = PT.Command
	PetTraderEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	PetTraderEventFrame:RegisterEvent("CHAT_MSG_SAY")
	PetTraderEventFrame:RegisterEvent("CHAT_MSG_PARTY")
	PetTraderEventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
	PetTraderEventFrame:RegisterEvent("CHAT_MSG_ADDON")
end
function PT:PLAYER_ENTERING_WORLD()
	PetTraderEventFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	PT.myName = UnitName("player")
	print("Hello "..PT.myName)
end
function PT.CHAT_MSG_PARTY(_, text, playerName)
	print(playerName.." send:"..text)
	PT.ScanPets()
end
PT.CHAT_MSG_PARTY_LEADER = PT.CHAT_MSG_PARTY
PT.CHAT_MSG_SAY = PT.CHAT_MSG_PARTY
function PT.CHAT_MSG_ADDON(_, prefix, message, distType, sender)
	print( prefix, message, distType, sender )
end

-------
function PT.SavePetFilters()
	-- save current values
	PT.previousFilterText = C_PetJournal.GetSearchFilter()
	PT.collectedFilter = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED)
	PT.notCollectedFilter = C_PetJournal.IsFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED)

	PT.previousSources = {}
	for sourceNum = 1, C_PetJournal.GetNumPetSources() do
		PT.previousSources[sourceNum] = C_PetJournal.IsPetSourceChecked(sourceNum)
	end

	PT.previousTypes = {}
	for typeNum = 1, C_PetJournal.GetNumPetTypes() do
		PT.previousTypes[typeNum] = C_PetJournal.IsPetTypeChecked(typeNum)
	end
end
function PT.RestorePetFilters()
	-- restore
	C_PetJournal.SetSearchFilter(PT.previousFilterText)
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED,PT.collectedFilter)
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED,PT.notCollectedFilter)

	for sourceNum,_ in ipairs(PT.previousSources) do
		C_PetJournal.SetPetSourceChecked(sourceNum, PT.previousSources[sourceNum])
	end
	for typeNum,_ in ipairs(PT.previousTypes) do
		C_PetJournal.SetPetTypeFilter(typeNum, PT.previousTypes[typeNum])
	end
end
function PT.ScanPets()
	-- save values
	PT.SavePetFilters()
	-- set needed values
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_COLLECTED,true)
	C_PetJournal.SetFilterChecked(LE_PET_JOURNAL_FILTER_NOT_COLLECTED,true)
	C_PetJournal.SetAllPetSourcesChecked(true)
	C_PetJournal.SetAllPetTypesChecked(true)
	C_PetJournal.SetSearchFilter("")

    -- get the speciesID for each petIndex
	PT.myPetIDs = {}
    PT.myPetIndexes = {}
	local numPets, numOwned = C_PetJournal.GetNumPets()

	for petIndex = 1, numPets do
		local petID, speciesID, _, _, level, _, _, petName, _, _, _, _, _, _, _, isTradeable = C_PetJournal.GetPetInfoByIndex(petIndex)
        PT.myPetIDs[speciesID] = PT.myPetIDs[speciesID] or {}
		if(petID) then
			local rarity = select(5, C_PetJournal.GetPetStats(petID))
			-- print(speciesID, petName, rarity, isTradeable)
			table.insert(PT.myPetIDs[speciesID], {level, rarity})
            table.insert(PT.myPetIndexes, speciesID)
		end
	end
	PT_myPetIDS = PT.myPetIDs -- save this for debugging
    -- sort(PT.myPetIndexes)
    PT_myPetIndexes = PT.myPetIndexes

    PT.BuildCharStream()
	PT.SendPackets()

	-- reset values
	PT.RestorePetFilters()
end
function PT.BuildCharStream()
	local streamTable = {}

	for index, speciesID in ipairs(PT.myPetIndexes) do
		-- store a 1 if the number of pets is > 0, store a 0 otherwise
		for count = 1, 3 do
			streamTable[#streamTable+1] = (PT.myPetIDs[speciesID][count]
					and string.char( bit.lshift( (PT.myPetIDs[speciesID][count][1] or 0), 3)
									           + (PT.myPetIDs[speciesID][count][2] or 0) )
					or string.char(255))
		end
	end
	PT.charStream = table.concat(streamTable)
	-- 0 = Deflate, 2 = OptimizeForSize
	PT.compressStream = C_EncodingUtil.CompressString( PT.charStream, 0, 2 )

	PT_charStream = PT.charStream
	PT_compressStream = PT.compressStream
	PT_compressStream_size = string.len(PT.compressStream)

	local packetSize = 250
	local packetCount = math.ceil( string.len(PT.compressStream) / packetSize )
	PT.packets = {}
	for i = 1, string.len(PT.compressStream), packetSize do
		PT.packets[#PT.packets+1] = string.sub( PT.compressStream, i, i + packetSize - 1)
	end
	PT_packets = PT.packets
end
function PT.SendPackets()
	local packetCount = #PT.packets
	for i, packet in ipairs( PT.packets ) do
		C_ChatInfo.SendAddonMessage(
				PT.commPrefix,
				string.char(i).."|"..string.char(packetCount)..packet,
				"SAY" )
	end
end


-- C_EncodingUtil.CompressString( string.char(0)..string.char(0)..string.char(0))
-- C_EncodingUtil.EncodeBase64( string.char(0)..string.char(0)..string.char(0))

-- C_EncodingUtil.CompressString(C_EncodingUtil.EncodeBase64( string.char(0)..string.char(0)..string.char(0)))