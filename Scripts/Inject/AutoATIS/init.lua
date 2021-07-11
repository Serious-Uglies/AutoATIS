-- Ugly Server Mods - AutoATIS injected module

local ModuleName  	= "AutoATIS"
local MainVersion 	= "1"
local SubVersion 	= "0"
local Build 		= "0100"
local Date			= "2021_05_08"

local base 	    = _G
--local require   = base.require
local io 	    = require('io')  	-- check if io is available in mission environment
local lfs 	    = require('lfs')		-- check if lfs is available in mission environment

local logger         = require('logger')
local AtisStaticsPos = require('ATIS_CombinedPos')
local json           = require('json')


--## MAIN TABLE
AutoATIS             = {}
UglyStartAtis = {}
-----------------------------------------------------------------------------------------
-- Format of injected data
--[[

AtisStaticsPos:
AtisStaticsPos["ATIS Mozdok"] = {} ---Caucasus
AtisStaticsPos["ATIS Mozdok"]["shape_name"] = "UH-1H"
AtisStaticsPos["ATIS Mozdok"]["CountryID"] = 2
AtisStaticsPos["ATIS Mozdok"]["y"] = 835129.25
AtisStaticsPos["ATIS Mozdok"]["x"] = -83958.40625
AtisStaticsPos["ATIS Mozdok"]["CategoryID"] = 3
AtisStaticsPos["ATIS Mozdok"]["heading"] = 4.555309243523
AtisStaticsPos["ATIS Mozdok"]["type"] = "UH-1H"
AtisStaticsPos["ATIS Mozdok"]["name"] = "ATIS Mozdok"
AtisStaticsPos["ATIS Mozdok"]["CoalitionID"] = 2
AtisStaticsPos["ATIS Mozdok"]["dead"] = false


AtisConfigFreq:
  "Abu Al-Duhur 09": {
    "Map-Spezifisch": "Syria",
    "TACAN": "´",
    "I(C)LS": "´",
    "Primär": 136200,
    "Sekundär": 230800,
    "ATIS": 230850,
    "Runway": "09",
    "DCS-AirfieldName": "Abu al-Duhur",
    "MagVar": 5,
    "Comments": "",
    "KI ATC UHF": 250350,
    "KI ATC VHF": 122200,
    "Land": "Syrien"
  }
]]--

-----------------------------------------------------------------------------------------
-- Load ATIS frequencies

local atisFreqConfigFile = "ATIS_Frequencies.json"
--logger.info("Reading: " .. lfs.writedir() .. "Scripts/inject/AutoATIS/" .. atisFreqConfigFile)
local autoAtisFreq = io.open(lfs.writedir() .. "Scripts/inject/AutoATIS/" .. atisFreqConfigFile, "r")

local AtisConfigFreq = nil
local AtisConfigFreqJson = tostring(autoAtisFreq:read("*all"))
--logger.info("AtisConfigFreqJson: " .. AtisConfigFreqJson)  

AtisConfigFreq = json.decode(AtisConfigFreqJson)

--logger.info(ModuleName .. ": IntegratedserializeWithCycles")
local AtisConfigFreqString = logger.IntegratedserializeWithCycles("AtisConfigFreq", AtisConfigFreq)
--logger.info(ModuleName .. ": AtisConfigFreqString:\n" .. AtisConfigFreqString)
autoAtisFreq:close()

-----------------------------------------------------------------------------------------
-- Configuration

local coalitions = {}
coalitions[1] = coalition.side.RED
coalitions[2] = coalition.side.BLUE
--coalitions[3] = coalition.side.NEUTRAL
	

local atisUnits = {}
atisUnits[1] = {}
atisUnits[1]["type"] = "Ka-27" -- Red ATIS unit
atisUnits[1]["CountryID"] = 0 -- Red ATIS country

atisUnits[2] = {}
atisUnits[2]["type"] = "UH-1H" -- Blue ATIS unit
atisUnits[2]["CountryID"] = 2 -- Blue ATIS country

local AutoAtisConf = {}

-----------------------------------------------------------------------------------------
-- Main code

-- add atis to airport
AutoATIS.AddAtis = function (_name, _atisConf)  
    local newAtis=ATIS:New(_name, _atisConf["ATISFreq"], radio.modulation.AM)
--    newAtis:SetRadioRelayUnitName("ATIS " .. _name)
--    newAtis:SetTowerFrequencies({_atisConf["TowerFreqA"], _atisConf["TowerFreqB"]})
    newAtis:SetImperialUnits()
    newAtis:SetSRS("C:\\DCS_DATA\\SRS\\", "male", "en-US")
    newAtis:SetQueueUpdateTime(45)
    if _atisConf["Tacan"] ~= "" then
        newAtis:SetTACAN(_atisConf["Tacan"])
    end
    newAtis:Start()
end

-- place unit at predefined position depended of coalition
AutoATIS.CreateAtisObjectForAirbase = function (_name, _coalition)
    local configName = "ATIS " .. _name
    local _conf = AtisStaticsPos[configName]

    if _conf ~= nil then
        local tmpGrp = {}
        tmpGrp["visible"] = true
        tmpGrp["x"] = _conf["x"]
        tmpGrp["y"] = _conf["y"]
        tmpGrp["CountryID"] = atisUnits[_coalition]["CountryID"]
        tmpGrp["CategoryID"] = 1 -- heli hardcoded
        tmpGrp["name"] = _conf["name"]
        tmpGrp["CoalitionID"] = _coalition
        tmpGrp["uncontrolled"] = true
        tmpGrp["tasks"] = {}
        tmpGrp["task"] = "transport"
        tmpGrp["units"] = {}
        tmpGrp["units"][1] = {}
        tmpGrp["units"][1]["x"] = _conf["x"]
        tmpGrp["units"][1]["y"] = _conf["y"]
        tmpGrp["units"][1]["type"] = atisUnits[_coalition]["type"]
        tmpGrp["units"][1]["name"] = _conf["name"]
        tmpGrp["units"][1]["shape_name"] = atisUnits[_coalition]["type"]
        tmpGrp["units"][1]["heading"] = _conf["heading"]

        coalition.addGroup(tmpGrp["CountryID"], tmpGrp["CategoryID"], tmpGrp)
        logger.info("UGLY: Adding group as ATIS to: " .. tostring(_coalition))
    end
end

AutoATIS.injectAtisToMap = function ()
    if AtisStaticsPos ~= nil then -- Data has been injected properly
        logger.info("AtisStaticsPos available - contains no. of elements: " .. tostring(#AtisStaticsPos))

--[[
        for k,v in pairs(AtisStaticsPos) do
            local AtisStaticsPosString = IntegratedserializeWithCycles("AtisStaticsPos - " .. k, AtisStaticsPos[k])
            env.info("AtisStaticsPos - \n" .. AtisStaticsPosString)
        end
]]
    else
        logger.info("AtisStaticsPos not available")
    end

    if AtisConfigFreq ~= nil then -- Data has been injected properly
        logger.info("UGLY: Existing database, using given atis conf.")

        -- Convert to more usable format
        for k,v in pairs(AtisConfigFreq) do
            local nextAirfieldConf = AtisConfigFreq[k]
            
            local nextAirfieldName = AtisConfigFreq[k]["DCS-AirfieldName"]
            logger.info("UGLY: Checking config for: " .. nextAirfieldName)

            local currentAtisConf = AutoAtisConf[nextAirfieldName]
            if currentAtisConf == nil then
                logger.info("UGLY: Adding new config for: " .. nextAirfieldName)

                local airfieldConf = {}

                local atisFreq = 0
                if tonumber(nextAirfieldConf ["ATIS"]) ~= nil then
                    atisFreq = tonumber(nextAirfieldConf ["ATIS"]) / 1000
                end
                local towerAFreq = 0
                if tonumber(nextAirfieldConf ["Primär"]) ~= nil then
                    towerAFreq = tonumber(nextAirfieldConf ["Primär"]) / 1000
                end
                local towerBFreq = 0
                if tonumber(nextAirfieldConf ["Sekundär"]) ~= nil then
                    towerBFreq = tonumber(nextAirfieldConf ["Sekundär"]) / 1000
                end

                local tacanFreq = ""
                if nextAirfieldConf ["TACAN"] ~= nil then
                    tacanFreq = string.gsub(nextAirfieldConf ["TACAN"], "X", "")
                end

                airfieldConf["ATISFreq"] = atisFreq
                logger.info("UGLY: ATISFreq: " .. tostring(atisFreq))
                airfieldConf["TowerFreqA"] = towerAFreq
                logger.info("UGLY: TowerFreqA: " .. tostring(towerAFreq))
                airfieldConf["TowerFreqB"] = towerBFreq
                logger.info("UGLY: TowerFreqB: " .. tostring(towerBFreq))
                airfieldConf["Tacan"] = tacanFreq
                logger.info("UGLY: Tacan: " .. tacanFreq)

                AutoAtisConf[nextAirfieldName] = airfieldConf
            end

            -- TODO: Check for new runway with different ILS
        end

        for k = 1, #coalitions do
            local airbaseMap = coalition.getAirbases(coalitions[k])
            for i=1, #airbaseMap do
                logger.info("UGLY: Adding objects to coalition: " .. coalitions[k])

                if AutoAtisConf[airbaseMap[i]:getName()] ~= nil then
                    logger.info("UGLY: Adding object to airfield: " .. airbaseMap[i]:getName())

--[[                local GroupObject = GROUP:FindByName( "ATIS " .. airbaseMap[i]:getName() )
                    if GroupObject == nil then
                        AutoATIS.CreateAtisObjectForAirbase(airbaseMap[i]:getName(), coalitions[k])
                    else
                        logger.info("UGLY: Group exists - reusing: " .. airbaseMap[i]:getName())
                    end
]]--                    
                    AutoATIS.AddAtis(airbaseMap[i]:getName(), AutoAtisConf[airbaseMap[i]:getName()])
                else
                    logger.info("UGLY: No frequencies for: " .. airbaseMap[i]:getName())
                end
            end
        end
    else
        logger.info("Atis data not injected")
    end
end  
  
--local checkNumber = 0
AutoATIS.startMapAfterMoose = function (argument, time)

--    trigger.action.outText("AutoATIS is waiting for Moose to be loaded...", 2)
    if UglyStartAtis == nil then
        logger.info("AutoATIS is configured to be off...")
        return 0
    else
        logger.info("AutoATIS is configured to be on, so wating for Moose to be loaded...")
    end


    if ENUMS == nil then
--        trigger.action.outText("AutoATIS is waiting for Moose to be loaded...", 1)
        logger.info("AutoATIS is waiting for Moose to be loaded...")
    else
        trigger.action.outText("Moose is loaded - Starting AutoATIS", 5)
        logger.info("Moose is loaded - Starting AutoATIS")
--        logger.info(lfs.writedir() .. "Scripts/inject/AutoATIS/Atis Soundfiles/")

--        ATIS:SetSoundfilesPath(lfs.writedir() .. "Scripts/inject/AutoATIS/Atis Soundfiles/")

        AutoATIS.injectAtisToMap()

        return 0
    end

--    trigger.action.outText("debugTestPrint checkNumber: "..checkNumber, 3)
--    checkNumber = checkNumber + 1

    return time + 5
end

timer.scheduleFunction(AutoATIS.startMapAfterMoose, {}, timer.getTime() + 10)


-----------------------------------------------------------------------------------------
-- Leftovers

--[[
if env.mission.theatre == "Caucasus" then
    local tTbl = {}
    for tName, tData in pairs(CaucasusTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    CaucasusTowns = nil
elseif env.mission.theatre == "Nevada" then
    local tTbl = {}
    for tName, tData in pairs(NevadaTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    NevadaTowns = nil
elseif env.mission.theatre == "Normandy" then
    local tTbl = {}
    for tName, tData in pairs(NormandyTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    NormandyTowns = nil
elseif env.mission.theatre == "PersianGulf" then
    local tTbl = {}
    for tName, tData in pairs(PersianGulfTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    PersianGulfTowns = nil
elseif env.mission.theatre == "TheChannel" then
    local tTbl = {}
    for tName, tData in pairs(TheChannelTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    TheChannelTowns = nil
elseif env.mission.theatre == "Syria" then
    local tTbl = {}
    for tName, tData in pairs(SyriaTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    SyriaTowns = nil
else
    env.error(("AutoATIS, no theater identified: halting everything"))
    return
end
]]--


--[[
AutoATIS.AtisConf = {}
AutoATIS.AtisConf["Batumi"] = {}
AutoATIS.AtisConf["Batumi"]["ATISFreq"] = 260.15
AutoATIS.AtisConf["Batumi"]["TowerFreqA"] = 260.100
AutoATIS.AtisConf["Batumi"]["TowerFreqB"] = 131.100
AutoATIS.AtisConf["Batumi"]["Tacan"] = 16
AutoATIS.AtisConf["Batumi"]["Runway"] = {}
AutoATIS.AtisConf["Batumi"]["Runway"]["9"]["Heading"] = 9
AutoATIS.AtisConf["Batumi"]["Runway"]["9"]["ILS"] = 123.4
AutoATIS.AtisConf["Batumi"]["Runway"]["27"]["Heading"] = 27
AutoATIS.AtisConf["Batumi"]["Runway"]["27"]["ILS"] = 123.5


AtisConfigFreq:
  "Abu Al-Duhur 09": {
    "Map-Spezifisch": "Syria",
    "TACAN": "´",
    "I(C)LS": "´",
    "Primär": 136200,
    "Sekundär": 230800,
    "ATIS": 230850,
    "Runway": "09",
    "DCS-AirfieldName": "Abu al-Duhur",
    "MagVar": 5,
    "Comments": "",
    "KI ATC UHF": 250350,
    "KI ATC VHF": 122200,
    "Land": "Syrien"
  }

]]
