-- By xaneh#6591

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('qb-multicharacter:server:disconnect')
AddEventHandler('qb-multicharacter:server:disconnect', function()
    local src = source

    DropPlayer(src, "You have disconnected from Qbus Roleplay")
end)

RegisterServerEvent('qb-multicharacter:server:loadUserData')
AddEventHandler('qb-multicharacter:server:loadUserData', function(cData)
    local src = source
    if ESX.GetPlayerData.Login(src, cData.citizenid) then
        print('^2[qb-core]^7 '..GetPlayerName(src)..' (Citizen ID: '..cData.citizenid..') has succesfully loaded!')
        ESX.GetPlayerFromId.Refresh(src)
        loadHouseData()
		--TriggerEvent('ESX:Server:OnPlayerLoaded') -- ÇALIŞMAZ
        --TriggerClientEvent('ESX:Client:OnPlayerLoaded', src) -- ÇALIŞMAZ
        
        TriggerClientEvent('apartments:client:setupSpawnUI', src, cData)
        TriggerEvent("qb-log:server:sendLog", cData.citizenid, "characterloaded", {})
        TriggerEvent("qb-log:server:CreateLog", "joinleave", "Loaded", "green", "**".. GetPlayerName(src) .. "** ("..cData.citizenid.." | "..src..") loaded..")
	end
end)

RegisterServerEvent('qb-multicharacter:server:createCharacter')
AddEventHandler('qb-multicharacter:server:createCharacter', function(data)
    local src = source
    local newData = {}
    newData.cid = data.cid
    newData.charinfo = data
    --ESX.Player.CreateCharacter(src, data)  -- ÇALIŞMAZ
    if ESX.GetPlayerData.Login(src, false, newData) then
        print('^2[qb-core]^7 '..GetPlayerName(src)..' has succesfully loaded!')
        ESX.GetPlayerFromId.Refresh(src)
        loadHouseData()

        TriggerClientEvent("qb-multicharacter:client:closeNUI", src)
        TriggerClientEvent('apartments:client:setupSpawnUI', src, newData)
        GiveStarterItems(src)
	end
end)

RegisterServerEvent('qb-multicharacter:server:deleteCharacter')
AddEventHandler('qb-multicharacter:server:deleteCharacter', function(citizenid)
    local src = source
    ESX.GetPlayerData.DeleteCharacter(src, citizenid)
end)

ESX.CreateCallback("qb-multicharacter:server:GetUserCharacters", function(source, cb)
    local steamId = GetPlayerIdentifier(source, 0)

    exports['ghmattimysql']:execute('SELECT * FROM players WHERE steam = @steam', {['@steam'] = steamId}, function(result)
        cb(result)
    end)
end)

ESX.CreateCallback("qb-multicharacter:server:GetServerLogs", function(source, cb)
    exports['ghmattimysql']:execute('SELECT * FROM server_logs', function(result)
        cb(result)
    end)
end)

ESX.CreateCallback("test:yeet", function(source, cb)
    local steamId = GetPlayerIdentifiers(source)[1]
    local plyChars = {}
    
    exports['ghmattimysql']:execute('SELECT * FROM players WHERE steam = @steam', {['@steam'] = steamId}, function(result)
        for i = 1, (#result), 1 do
            result[i].charinfo = json.decode(result[i].charinfo)
            result[i].money = json.decode(result[i].money)
            result[i].job = json.decode(result[i].job)

            table.insert(plyChars, result[i])
        end
        cb(plyChars)
    end)
end)

ESX.GetPlayerFromId.Add("char", "Donner le menu personnage  au joueur", {{name="id", help="ID du joueur"}, false, function(source, args)
    ESX.GetPlayerData.Logout(source)
    TriggerClientEvent('qb-multicharacter:client:chooseChar', source)
end, "admin")

ESX.GetPlayerFromId.Add("closeNUI", "Geef een item aan een speler", {{name="id", help="Speler ID"},{name="item", help="Naam van het item (geen label)"}, {name="amount", help="Aantal items"}}, false, function(source, args)
    TriggerClientEvent('qb-multicharacter:client:closeNUI', source)
end)

ESX.CreateCallback("qb-multicharacter:server:getSkin", function(source, cb, cid)
    local src = source

    ESX.ExecuteSql(false, "SELECT * FROM `playerskins` WHERE `citizenid` = '"..cid.."' AND `active` = 1", function(result)
        if result[1] ~= nil then
            cb(result[1].model, result[1].skin)
        else
            cb(nil)
        end
    end)
end)

function loadHouseData()
    local HouseGarages = {}
    local Houses = {}
	ESX.ExecuteSql(false, "SELECT * FROM `houselocations`", function(result)
		if result[1] ~= nil then
			for k, v in pairs(result) do
				local owned = false
				if tonumber(v.owned) == 1 then
					owned = true
				end
				local garage = v.garage ~= nil and json.decode(v.garage) or {}
				Houses[v.name] = {
					coords = json.decode(v.coords),
					owned = v.owned,
					price = v.price,
					locked = true,
					adress = v.label, 
					tier = v.tier,
					garage = garage,
					decorations = {},
				}
				HouseGarages[v.name] = {
					label = v.label,
					takeVehicle = garage,
				}
			end
		end
		TriggerClientEvent("qb-garages:client:houseGarageConfig", -1, HouseGarages)
		TriggerClientEvent("qb-houses:client:setHouseConfig", -1, Houses)
	end)
end