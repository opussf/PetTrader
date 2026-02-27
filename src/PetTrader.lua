PT_SLUG, PT = ...
PT.MSG_ADDONNAME = C_AddOns.GetAddOnMetadata( PT_SLUG, "Title" )
PT.MSG_VERSION   = C_AddOns.GetAddOnMetadata( PT_SLUG, "Version" )
PT.MSG_AUTHOR    = C_AddOns.GetAddOnMetadata( PT_SLUG, "Author" )
PT.prefix = "PT1"

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

	PT.myPetIDs = {}
	local numPets, numOwned = C_PetJournal.GetNumPets()

	for petIndex = 1, numPets do
		local petID, speciesID, _, _, level, _, _, petName, _, _, _, _, _, _, _, isTradeable = C_PetJournal.GetPetInfoByIndex(petIndex)
		if(petID) then
			local rarity = select(5, C_PetJournal.GetPetStats(petID))
			-- print(speciesID, petName, rarity, isTradeable)
			PT.myPetIDs[speciesID] = PT.myPetIDs[speciesID] or {}
			table.insert(PT.myPetIDs[speciesID], {level, rarity})
		end
	end
	PT_myPetIDS = PT.myPetIDs -- save this for debugging


	-- reset values
	PT.RestorePetFilters()
end
