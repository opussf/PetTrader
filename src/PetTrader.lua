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
end
function PT.CHAT_MSG_PARTY(_, text, playerName)
	print(playerName.." send:"..text)
	PT.ScanPets()
end
PT.CHAT_MSG_PARTY_LEADER = PT.CHAT_MSG_PARTY
PT.CHAT_MSG_SAY = PT.CHAT_MSG_PARTY
function PT.CHAT_MSG_ADDON(_, prefix, msg, distType, sender)
	print( prefix, msg, distType, sender )
	PT.theirPetIDs = PT.theirPetIDs or {}
	if prefix == PT.commPrefix then
		PT.theirPetIDs[sender] = PT.theirPetIDs[sender] or {packets={}}
		local packetIndex, packetTotal = string.byte( msg, 1, 2 )
		local packet = string.sub( msg, 3 )
		PT.theirPetIDs[sender].packets[packetIndex] = packet
		-- look to see if all packets have arrived from that user
		local haveAllPackets = true
		for packetIndex = 1, packetTotal do
			haveAllPackets = haveAllPackets and PT.theirPetIDs[sender].packets[packetIndex]
		end
		if haveAllPackets then
			PT.ProcessPackets(sender)
		end
	end
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
	local numPets, numOwned = C_PetJournal.GetNumPets()

	for petIndex = 1, numPets do
		local petID, speciesID, _, _, level, _, _, petName, _, _, _, _, _, _, _, isTradeable = C_PetJournal.GetPetInfoByIndex(petIndex)
        PT.myPetIDs[speciesID] = PT.myPetIDs[speciesID] or {}
		if(petID) then
			local rarity = select(5, C_PetJournal.GetPetStats(petID))
			-- print(speciesID, petName, rarity, isTradeable)
			table.insert(PT.myPetIDs[speciesID], {level, rarity})
		end
	end
	PT_myPetIDS = PT.myPetIDs -- save this for debugging

    PT.BuildCharStream()
	PT.SendPackets()

	-- reset values
	PT.RestorePetFilters()
end
function PT.PairsByKeys( t, f )
	local a = {}
	for n in pairs( t ) do table.insert( a, n ) end
	table.sort( a, f )
	local i = 0
	local iter = function()
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end
function PT.BuildCharStream()
	local streamTable = {}
	local speciesIDCount = 0

	for speciesID, _ in PT.PairsByKeys(PT.myPetIDs) do
		local count = #PT.myPetIDs[speciesID]
		speciesIDCount = bit.lshift( speciesID, 3) + count -- shift 3 for a bit of expansion
		streamTable[#streamTable+1] = string.char( bit.rshift( speciesIDCount, 8 ) )..
				string.char( bit.band( speciesIDCount, 255 ) )

		for c = 1, count do
			streamTable[#streamTable+1] = string.char(
					bit.lshift( PT.myPetIDs[speciesID][c][1], 3) +
					PT.myPetIDs[speciesID][c][2] )
		end
	end

	PT.charStream = table.concat(streamTable)
	-- 0 = Deflate, 2 = OptimizeForSize
	PT.compressStream = C_EncodingUtil.CompressString( PT.charStream, 0, 2 )

	PT_charStream = PT.charStream
	PT_compressStream = PT.compressStream
	PT_compressStream_size = string.len(PT.compressStream)

	local packetSize = 245
	local packetCount = math.ceil( string.len(PT.compressStream) / packetSize )
	PT.packets = {}
	for i = 1, string.len(PT.compressStream), packetSize do
		PT.packets[#PT.packets+1] = string.sub( PT.compressStream, i, i + packetSize - 1)
	end
	PT_packets = PT.packets
end
function PT.SendPackets()
	if not C_ChatInfo.IsAddonMessagePrefixRegistered(PT.commPrefix) then
		C_ChatInfo.RegisterAddonMessagePrefix(PT.commPrefix)
	end

	local packetCount = #PT.packets
	for i, packet in ipairs( PT.packets ) do
		C_ChatInfo.SendAddonMessage(
				PT.commPrefix,
				string.char(i)..string.char(packetCount)..packet,
				"GUILD" )
	end
end
-- Process
function PT.ProcessPackets(sender)
	local compressedStream = table.concat(PT.theirPetIDs[sender].packets)
	PT.theirPetIDs[sender].packets = nil
	local theirPets = PT.theirPetIDs[sender]
	local bitstream = C_EncodingUtil.DecompressString(compressedStream, 0)
	print("Hello: "..bitstream)
	local bitstreamLen = string.len(bitstream)
	local i = 1  -- start with the first char

	while i < bitstreamLen do
		local speciesID, count = string.byte(bitstream, i, i+1)
		local v = speciesID*256 + count
		print(v)
		count = v & 0x07  -- low 3 bits
		speciesID = v >> 3
		print( "speciesID: "..speciesID.." has: "..count )
		theirPets[speciesID] = {}
		for p = 1, count do
			local levelCount = string.byte(bitstream, i+1+p)
			theirPets[speciesID][2] = levelCount & 0x07 -- low 3 bits
			theirPets[speciesID][1] = levelCount >> 3
		end
		i = i + 2 + count
	end

end

-- Name = "DecompressString",
-- 			Type = "Function",
-- 			MayReturnNothing = true,
-- 			SecretArguments = "AllowedWhenUntainted",

-- 			Arguments =
-- 			{
-- 				{ Name = "source", Type = "stringView", Nilable = false },
-- 				{ Name = "method", Type = "CompressionMethod", Nilable = false, Default = "Deflate" },
-- 			},

-- 			Returns =
-- 			{
-- 				{ Name = "output", Type = "string", Nilable = false },
-- 			},