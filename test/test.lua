#!/usr/bin/env lua
require "wowTest"

test.outFileName = "testOut.xml"
test.coberturaFileName = "../coverage.xml"
test.coverageReportPercent = true

ParseTOC( "../src/PetTrader.toc" )

function test.before()
	chatLog = {}
	PT.theirPetIDs = nil
	PT.OnLoad()
	PT.PLAYER_ENTERING_WORLD()
end
function test.after()
end

function test.test_onLoad()
	PT.OnLoad()
end
function test.make_PT_data()
	PT.myPetIDs = {
		[383] = {
			{ 25, 4, },
			{ 22, 3, }, },
		[1533] = {
			{ 16, 4, }, },
		[1537] = {
			{ 1, 3, }, },
		[3097] = { },
		[3101] = {
			{ 16, 4, }, },
		[3113] = { },
		[3117] = { },
		[3121] = {
			{ 6, 3, }, },
		[392] = {
			{ 15, 4, },
			{ 7, 4, },
			{ 7, 4, }, },
	}
	PT.myPetIndexes = { 383, 1537, 1533, 3097, 3101, 3113, 3117, 3121, 392 }
end
function test.test_build_character_stream_1species_3pets()
	PT.myPetIDs = {
		[383] = {
			{ 25, 4, },  -- 25 << 3 + 4 (204)
			{ 22, 3, },  -- 179
			{ 1, 2} }, } -- 10
	PT.myPetIndexes = { 383 }
	PT.BuildCharStream()
	assertEquals(string.char(11)..string.char(251)..string.char(204)..string.char(179)..string.char(10), PT.charStream)
end
function test.test_build_character_stream_1species_2pets()
	PT.myPetIDs = {
		[383] = {
			{ 25, 4, }, 	 -- 25 << 3 + 4 (204)
			{ 22, 3, }, } }  -- 179
	PT.myPetIndexes = { 383 }
	PT.BuildCharStream()
	assertEquals(string.char(11)..string.char(250)..string.char(204)..string.char(179), PT.charStream)
end
function test.test_build_character_stream_1species_1pet()
	PT.myPetIDs = {
		[383] = {
			{ 22, 3, }, } }  -- 179
	PT.myPetIndexes = { 383 }
	PT.BuildCharStream()
	assertEquals(string.char(11)..string.char(249)..string.char(179), PT.charStream)
end
function test.test_build_character_stream_1species_0pets()
	PT.myPetIDs = {
		[383] = { } }
	PT.myPetIndexes = { 383 }
	PT.BuildCharStream()
	assertEquals(string.char(11)..string.char(248), PT.charStream)
end
function test.test_build_character_stream_2species_0pets()
	PT.myPetIDs = {
		[383] = { },
		[392] = { }, }
	PT.myPetIndexes = { 392, 383 }
	PT.BuildCharStream()
	assertEquals(string.char(12)..string.char(64)..string.char(11)..string.char(248), PT.charStream)
end
function test.test_build_character_stream_2species_1pet()
	PT.myPetIDs = {
		[383] = { { 25, 4 }, },
		[392] = { }, }
	PT.myPetIndexes = { 392, 383 }
	PT.BuildCharStream()
	assertEquals(string.char(12)..string.char(64)..string.char(11)..string.char(249)..string.char(204), PT.charStream)
end
function test.test_send_message()
	PT.myPetIDs = {
		[383] = { { 25, 4 }, },
		[392] = { }, }
	PT.myPetIndexes = { 392, 383 }
	PT.BuildCharStream()
	PT.SendPackets()
	assertEquals("PT1", chatLog[1].prefix)
	assertEquals(string.char(1)..string.char(1)..string.char(12)..string.char(64)..string.char(11)..string.char(249)..string.char(204),
			chatLog[1].msg)
end
function test.notest_get_message_2species_1pet_adds_sender_table()
	PT.myPetIndexes = { 392, 383 }
	local msg = string.char(1)..string.char(1)..string.char(255)..string.char(255)..string.char(255)..string.char(204)..string.char(255)..string.char(255)
	PT.CHAT_MSG_ADDON(nil, "PT1", msg, "GUILD", "Frank-Hyjal")
	assertTrue(PT.theirPetIDs["Frank-Hyjal"])
end
function test.notest_get_message_2species_1pet_decodes_data()
	PT.myPetIndexes = { 392, 383 }
	local msg = string.char(1)..string.char(1)..string.char(255)..string.char(255)..string.char(255)..string.char(204)..string.char(255)..string.char(255)
	PT.CHAT_MSG_ADDON(nil, "PT1", msg, "GUILD", "Frank-Hyjal")

	assertEquals(25, PT.theirPetIDs["Frank-Hyjal"][383][1])
	assertEquals( 4, PT.theirPetIDs["Frank-Hyjal"][383][2])
end
function test.notest_get_message_2species_1pet_multi_packet_outoforder_incomplete()
	PT.myPetIndexes = { 392, 383 }
	local msg = string.char(2)..string.char(2)..string.char(255)..string.char(255)..string.char(255)..string.char(204)..string.char(255)..string.char(255)
	PT.CHAT_MSG_ADDON(nil, "PT1", msg, "GUILD", "Frank-Hyjal")

	assertIsNil(PT.theirPetIDs["Frank-Hyjal"].packets[1])
	assertTrue(PT.theirPetIDs["Frank-Hyjal"].packets[2])
end
function test.notest_get_message_2species_1pet_multi_packet_outoforder_complete()
	PT.myPetIndexes = { 392, 383 }
	local msg = string.char(2)..string.char(2)..string.char(204)..string.char(255)..string.char(255)
	PT.CHAT_MSG_ADDON(nil, "PT1", msg, "GUILD", "Frank-Hyjal")
	msg = string.char(1)..string.char(2)..string.char(255)..string.char(255)..string.char(255)
	PT.CHAT_MSG_ADDON(nil, "PT1", msg, "GUILD", "Frank-Hyjal")
	test.dump(PT.theirPetIDs)

	assertTrue(PT.theirPetIDs["Frank-Hyjal"].packets[1])
	assertTrue(PT.theirPetIDs["Frank-Hyjal"].packets[2])
end




test.run()