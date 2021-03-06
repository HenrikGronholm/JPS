--[[
	JPS - WoW Protected Lua DPS AddOn
	Copyright (C) 2011 Jp Ganis

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
]]--

--------------------------
-- LOCALIZATION
--------------------------
local L = MyLocalizationTable

----------------------
-- Find TANK
----------------------

function jps.targetIsRaidBoss(target)
	if target == nil then target = "target" end
	if not jps.UnitExists(target) then return false end
	if UnitLevel(target) == -1 and UnitPlayerControlled(target) == false then
		return true
	end
	return false
end

function jps.playerInLFR()
	local dungeon = jps.getInstanceInfo()
	if dungeon.difficulty == "lfr25" then return true end
	return false
end

function jps.findMeAggroTank(targetUnit)
	local allTanks = jps.findTanksInRaid()
	local highestThreat = 0
	local aggroTank = "player"
	for _, possibleTankUnit in pairs(allTanks) do
		local unitThreat = UnitThreatSituation(possibleTankUnit, targetUnit)
		if unitThreat and unitThreat > highestThreat then
			highestThreat = unitThreat
			aggroTank = possibleTankUnit
		end
	end
	if aggroTank == "player" and jps.tableLength(allTanks) > 0 and targetUnit ~= nil then --yeah nobody is tanking our target :):D so just return just "a" tank
		return jps.findMeAggroTank()
	end
	if jps.Debug then write("found Aggro Tank: "..aggroTank) end
	return aggroTank
end

function jps.unitGotAggro(unit)
	if unit == nil then unit = "player" end
	if UnitThreatSituation(unit) == 3 then return true end
	return false
end

function jps.findMeATank()
	local allTanks = jps.findTanksInRaid()
	if jps.tableLength(allTanks) == 0 then
		if jps.UnitExists("focus") then return "focus" end
	else
		return allTanks[1]
	end
	return "player"
end

function jps.findTanksInRaid()
	local myTanks = {}
	for unitName,_ in pairs(jps.RaidStatus) do
		local foundTank = false
		if UnitGroupRolesAssigned(unitName) == "TANK" then
			table.insert(myTanks, unitName);
			foundTank = true
		end
		if foundTank == false and jps.buff("bear form",unitName) then
			table.insert(myTanks, unitName);
			foundTank = true
		end
		if foundTank == false and jps.buff("blood presence",unitName) then
			table.insert(myTanks, unitName);
			foundTank = true
		end
		if foundTank == false and jps.buff("righteous fury",unitName) then
			table.insert(myTanks, unitName);
			foundTank = true
		end
	end
	return myTanks
end

-----------------------
-- RAID ENEMY COUNT
-----------------------
-- jps.RaidTarget[unittarget_guid] = { ["unit"] = unittarget, ["hpct"] = hpct_enemy, ["count"] = countTargets + 1 }

-- COUNT ENEMY ONLY WHEN THEY DO DAMAGE TO inRange FRIENDLIES
function jps.RaidEnemyCount()
	local enemycount = 0
	local targetcount = 0
	for unit,index in pairs(jps.EnemyTable) do
		enemycount = enemycount + 1
	end
	for tar_unit,tar_index in pairs(jps.RaidTarget) do
		targetcount = targetcount + 1
	end
	return enemycount,targetcount
end

-- ENEMY UNIT with LOWEST HEALTH
function jps.LowestInRaidTarget()
local mytarget = nil
local lowestHP = 1
	for unit,index in pairs(jps.RaidTarget) do
		local unit_Hpct = index.hpct
		if unit_Hpct < lowestHP then
			lowestHP = unit_Hpct
			mytarget = index.unit
		end
	end
return mytarget
end

-- ENEMY MOST TARGETED
function jps.RaidTargetUnit()
	local maxTargets = 0
	local enemyWithMostTargets = "target"
	for enemyGuid, enemyName in pairs(jps.RaidTarget) do
		if enemyName["count"] > maxTargets then
			maxTargets = enemyName["count"]
			enemyWithMostTargets = enemyName.unit
		end
	end
	return enemyWithMostTargets
end

-- ENEMY TARGETING THE PLAYER
-- jps.EnemyTable[enemyGuid] = { ["friend"] = enemyFriend } -- TABLE OF ENEMY GUID TARGETING FRIEND NAME
-- jps.RaidTarget[unittarget_guid] = { ["unit"] = unittarget, ["hpct"] = hpct_enemy, ["count"] = countTargets + 1 }
function jps.IstargetMe()
	local enemy_guid = nil
	for unit,index in pairs(jps.EnemyTable) do
		if index.friend == GetUnitName("player") then
			enemy_guid = unit
		end
	end
	for unit, index in pairs(jps.RaidTarget) do
		if (unit == enemy_guid) then
			return index.unit -- return "raid1target"
		end
	end
	return nil
end

diffTable = {}
diffTable[0] = "none"
diffTable[1] = "normal5"
diffTable[2] = "heroic5"
diffTable[3] = "normal10"
diffTable[4] = "normal25"
diffTable[5] = "heroic10"
diffTable[6] = "heroic25"
diffTable[7] = "lfr25"
diffTable[8] = "challenge"
diffTable[9] = "normal40"
diffTable[10] = "none"
diffTable[11] = "normal3"
diffTable[12] = "heroic3"

-- load instance info , we should read instance name & check if we fight an encounter
jps.instance = {}
function jps.getInstanceInfo()
	local name, instanceType , difficultyID = GetInstanceInfo()
	local targetName = UnitName("target")

	jps.instance["instance"] = name
	jps.instance["enemy"] = targetName
	jps.instance["difficulty"] = diffTable[difficultyID]

	return jps.instance
end