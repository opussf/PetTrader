#!/usr/bin/env lua
require "wowTest"

test.outFileName = "testOut.xml"
test.coberturaFileName = "../coverage.xml"
test.coverageReportPercent = true

ParseTOC( "../src/PetTrader.toc" )

function test.before()
	chatLog = {}
	PT.OnLoad()
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
	assertEquals(string.char(204)..string.char(179)..string.char(10), PT.charStream)
end
function test.test_build_character_stream_1species_2pets()
	PT.myPetIDs = {
		[383] = {
			{ 25, 4, }, 	 -- 25 << 3 + 4 (204)
			{ 22, 3, }, } }  -- 179
	PT.myPetIndexes = { 383 }
	PT.BuildCharStream()
	assertEquals(string.char(204)..string.char(179)..string.char(255), PT.charStream)
end
function test.test_build_character_stream_1species_1pet()
	PT.myPetIDs = {
		[383] = {
			{ 22, 3, }, } }  -- 179
	PT.myPetIndexes = { 383 }
	PT.BuildCharStream()
	assertEquals(string.char(179)..string.char(255)..string.char(255), PT.charStream)
end
function test.test_build_character_stream_1species_0pets()
	PT.myPetIDs = {
		[383] = { } }
	PT.myPetIndexes = { 383 }
	PT.BuildCharStream()
	assertEquals(string.char(255)..string.char(255)..string.char(255), PT.charStream)
end
function test.test_build_character_stream_2species_0pets()
	PT.myPetIDs = {
		[383] = { },
		[392] = { }, }
	PT.myPetIndexes = { 392, 383 }
	PT.BuildCharStream()
	assertEquals(string.char(255)..string.char(255)..string.char(255)..string.char(255)..string.char(255)..string.char(255), PT.charStream)
end
function test.test_build_character_stream_2species_1pet()
	PT.myPetIDs = {
		[383] = { { 25, 4 }, },
		[392] = { }, }
	PT.myPetIndexes = { 392, 383 }
	PT.BuildCharStream()
	assertEquals(string.char(255)..string.char(255)..string.char(255)..string.char(204)..string.char(255)..string.char(255), PT.charStream)
end
function test.test_send_message()
end


test.run()