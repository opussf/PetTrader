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


test.run()