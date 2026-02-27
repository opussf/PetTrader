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
function test.test_build_character_stream()
	PT.myPetIDS = {
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
	PT.BuildCharStream()
	print(PT.charStream)
end


test.run()