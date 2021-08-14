
local cam = nil
local continuousFadeOutNetwork = false
local needAskQuestions, needRegister
local firstSpawn, disableAttack = true, true

function f(n)
	n = n + 0.00000
	return n
end

function setCamHeight(height)
	local pos = GetEntityCoords(PlayerPedId())
	SetCamCoord(cam,vector3(pos.x,pos.y,f(height)))
end

local function StartFade()
	DoScreenFadeOut(500)
	while IsScreenFadingOut() do
		Citizen.Wait(1)
	end
end

local function EndFade()
	ShutdownLoadingScreen()
	DoScreenFadeIn(500)
	while IsScreenFadingIn() do
		Citizen.Wait(1)
	end
end

function DisalbeAttack()
	DisableControlAction(0, 19, true) -- INPUT_CHARACTER_WHEEL 
	DisableControlAction(0, 45, true)
	DisableControlAction(0, 24, true) -- Attack
	DisableControlAction(0, 257, true) -- Attack 2
	DisableControlAction(0, 25, true) -- Right click
	DisableControlAction(0, 68, true) -- Vehicle Attack
	DisableControlAction(0, 69, true) -- Vehicle Attack
	DisableControlAction(0, 70, true) -- Vehicle Attack
	DisableControlAction(0, 92, true) -- Vehicle Passengers Attack
	DisableControlAction(0, 346, true) -- Vehicle Melee
	DisableControlAction(0, 347, true) -- Vehicle Melee
	DisableControlAction(0, 264, true) -- Disable melee
	DisableControlAction(0, 257, true) -- Disable melee
	DisableControlAction(0, 140, true) -- Disable melee
	DisableControlAction(0, 141, true) -- Disable melee
	DisableControlAction(0, 142, true) -- Disable melee
	DisableControlAction(0, 143, true) -- Disable melee
	DisableControlAction(0, 263, true) -- Melee Attack 1
	if disableAttack then
		SetTimeout(0, function ()
			DisalbeAttack()
		end)
	end
end

AddEventHandler('playerSpawned', function()
	if not firstSpawn then return end
	firstSpawn = false
	StartUpLoading()
end)

function showLoadingPromt(label, time)
    Citizen.CreateThread(function()
        BeginTextCommandBusyString(tostring(label))
        EndTextCommandBusyString(3)
        Citizen.Wait(time)
        RemoveLoadingPrompt()
    end)
end

function ReadToPlay()
	disableAttack = false
	CameraLoadToGround()
	SetEntityInvincible(PlayerPedId(),false)
	SetEntityVisible(PlayerPedId(),true)
	FreezeEntityPosition(PlayerPedId(),false)
	SetPedDiesInWater(PlayerPedId(),true)
	DisplayRadar(true)
	KillCamera()
	TriggerEvent('es_admin:freezePlayer', false)
	TriggerEvent('esx:restoreLoadout')
	TriggerEvent('streetlabel:changeLoadStatus', true)
	TriggerEvent('esx_voice:changeLoadStatus', true)
	TriggerEvent("sr_mumblevoip:StartVoice")
	TriggerEvent('sr:triggerLoadingScreen')
	TriggerEvent("sr_manager:StartScanThread")
	TriggerEvent('PlayerLoadedToGround')
	TriggerServerEvent('esx_rack:loaded')
end

function StartUpLoading()
	Citizen.CreateThread(function()
		DisalbeAttack()
		CreateCameraOnTop()
		SetEntityInvincible(PlayerPedId(),true)
		SetEntityVisible(PlayerPedId(),true)
		FreezeEntityPosition(PlayerPedId(),true)
		SetPedDiesInWater(PlayerPedId(),false)
		DisplayRadar(false)
		ShutdownLoadingScreen()
		ShutdownLoadingScreenNui()
		DoScreenFadeIn(500)
		showLoadingPromt("PCARD_JOIN_GAME", 500000)
		TriggerEvent('es_admin:freezePlayer', true)
		while needRegister == nil do
			Wait(5000)
		end
		if needRegister then
			Wait(10000)
			showLoadingPromt("PCARD_JOIN_GAME", 0)
			SetTimeout(1000,function()
				TriggerCreateCharacter()
			end)
		elseif needAskQuestions then
			Wait(10000)
			showLoadingPromt("PCARD_JOIN_GAME", 0)
			TriggerEvent("antirpquestion:notMade")
		else
			Wait(10000)
			showLoadingPromt("PCARD_JOIN_GAME", 0)
			CreateCameraOnTop()
			EndFade()
			ReadToPlay()
		end
	end)
end

function CreateCameraOnTop()
	if not DoesCamExist(cam) then
		cam = CreateCam("DEFAULT_SCRIPTED_CAMERA",false)
	end

	local pos = GetEntityCoords(PlayerPedId())
	SetCamCoord(cam,vector3(pos.x,pos.y,f(1000)))
	SetCamRot(cam,-f(90),f(0),f(0),2)
	SetCamActive(cam,true)
	StopCamPointing(cam)
	RenderScriptCams(true,true,0,0,0,0)
end

function CameraLoadToGround()
	if not DoesCamExist(cam) then
		cam = CreateCam("DEFAULT_SCRIPTED_CAMERA",false)
	end

	local altura = 1000
	local pos = GetEntityCoords(PlayerPedId())
	SetCamCoord(cam,vector3(pos.x,pos.y,f(1000)))
	while altura > (pos.z - 5.0) do
		if altura <= 300 then
			altura = altura - 6
		elseif altura >= 301 and altura <= 700 then
			altura = altura - 4
		else
			altura = altura - 2
		end
		setCamHeight(altura)
		Citizen.Wait(10)
	end
end

function KillCamera()
	if not DoesCamExist(cam) then
		cam = CreateCam("DEFAULT_SCRIPTED_CAMERA",false)
	end

	SetCamActive(cam,false)
	StopCamPointing(cam)
	RenderScriptCams(0,0,0,0,0,0)
	SetFocusEntity(PlayerPedId())
end

function CreateCharacterCamera()
	if not DoesCamExist(cam) then
		cam = CreateCam("DEFAULT_SCRIPTED_CAMERA",false)
	end

	SetCamCoord(cam,vector3(402.6,-997.2,-98.3))
	SetCamRot(cam,f(0),f(0),f(358),15)
	SetCamActive(cam,true)
	RenderScriptCams(true,true,20000000000000000000000000,0,0,0)
end

RegisterNetEvent('registerForm')
AddEventHandler('registerForm', function(bool)
	needRegister = bool
end)

RegisterNetEvent('askQuestions')
AddEventHandler('askQuestions', function(bool)
	needAskQuestions = bool
end)

RegisterNetEvent("sr_loadingsystem:AskQuestions")
AddEventHandler("sr_loadingsystem:AskQuestions", function()
	needAskQuestions = true
	StartUpLoading()
end)

RegisterNetEvent("sr_loadingsystem:AskQuestionsSuccess")
AddEventHandler("sr_loadingsystem:AskQuestionsSuccess", function()
	needAskQuestions = false
	ReadToPlay()
end)

local isInCharacterMode = false
local currentCharacterMode = { sex = 0, dad = 0, mom = 0, skin_md_weight = 0, face_md_weight = 0.0, eye_color = 0, eyebrows_5 = 0, eyebrows_6 = 0, nose_1 = 0, nose_2 = 0, nose_3 = 0, nose_4 = 0, nose_5 = 0, nose_6 = 0, cheeks_1 = 0, cheeks_2 = 0, cheeks_3 = 0, lip_thickness = 0, jaw_1 = 0, jaw_2 = 0, chin_1 = 0, chin_2 = 0, chin_3 = 0, chin_4 = 0, neck_thickness = 0, hair_1 = 4, hair_2 = 0, hair_color_1 = 0, hair_color_2 = 0, eyebrows_1 = 0, eyebrows_1 = 10, eyebrows_3 = 0, eyebrows_4 = 0, beard_1 = -1, beard_2 = 10, beard_3 = 0, beard_4 = 0, chest_1 = -1, chest_1 = 10, chest_3 = 0, blush_1 = -1, blush_2 = 10, blush_3 = 0, lipstick_1 = -1, lipstick_2 = 10, lipstick_3 = 0, lipstick_4 = 0, blemishes_1 = -1, blemishes_2 = 10, age_1 = -1, age_2 = 10, complexion_1 = -1, complexion_2 = 10, sun_1 = -1, sun_2 = 10, moles_1 = -1, moles_2 = 10, makeup_1 = -1 , makeup_2 = 10, makeup_3 = 0 , makeup_4 = 0 }
local characterNome = ""
local characterSobrenome = ""

RegisterNetEvent('showRegisterForm')
AddEventHandler('showRegisterForm', function ()
	lastcoord = GetEntityCoords(PlayerPedId())
	needRegister = true
	StartUpLoading()
end)

function TriggerCreateCharacter()
	CreateCameraOnTop()
	isInCharacterMode = true
	StartFade()
	continuousFadeOutNetwork = true
	FadeOutNet()
	changeGender("mp_m_freemode_01")
	refreshDefaultCharacter()
	TaskUpdateSkinOptions()
	TaskUpdateFaceOptions()
	TaskUpdateHeadOptions()
	LoadInterior(94722)
	while IsInteriorReady(94722) ~= 1 or HasModelLoaded(model) do
		Wait(100)
	end
	TriggerEvent('es_admin:teleportUser', 402.55,-996.37,-100.01)
	SetEntityHeading(PlayerPedId(),f(0))
	CreateCharacterCamera()
	Citizen.Wait(1000)
	SetNuiFocus(isInCharacterMode,isInCharacterMode)
	SendNUIMessage({ CharacterMode = isInCharacterMode, CharacterMode2 = not isInCharacterMode, CharacterMode3 = not isInCharacterMode })
	EndFade()
end

function refreshDefaultCharacter()
	SetPedDefaultComponentVariation(PlayerPedId())
	ClearAllPedProps(PlayerPedId())
    ClearPedDecorations(PlayerPedId())
	if GetEntityModel(PlayerPedId()) == GetHashKey("mp_m_freemode_01") then
		SetPedComponentVariation(PlayerPedId(),1,-1,0,2) -- mask
		SetPedComponentVariation(PlayerPedId(),3,15,0,2) -- torso
		SetPedComponentVariation(PlayerPedId(),4,61,0,2) -- leg
		SetPedComponentVariation(PlayerPedId(),5,-1,0,2) -- bag 
		SetPedComponentVariation(PlayerPedId(),6,16,0,2) -- shoes
		SetPedComponentVariation(PlayerPedId(),7,-1,0,2) -- neck
		SetPedComponentVariation(PlayerPedId(),8,15,0,2) -- undershirt
		SetPedComponentVariation(PlayerPedId(),9,-1,0,2) -- vest
		SetPedComponentVariation(PlayerPedId(),10,-1,0,2) -- badge
		SetPedComponentVariation(PlayerPedId(),11,15,0,2) -- jacket
		SetPedPropIndex(PlayerPedId(),2,-1,0,2) -- ear
		SetPedPropIndex(PlayerPedId(),6,-1,0,2) -- watch
		SetPedPropIndex(PlayerPedId(),7,-1,0,2) -- bracelet
	else
		SetPedComponentVariation(PlayerPedId(),1,-1,0,2) -- mask
		SetPedComponentVariation(PlayerPedId(),3,15,0,2) -- torso
		SetPedComponentVariation(PlayerPedId(),4,15,0,2) -- leg
		SetPedComponentVariation(PlayerPedId(),5,-1,0,2) -- parachute 
		SetPedComponentVariation(PlayerPedId(),6,5,0,2) -- shoes
		SetPedComponentVariation(PlayerPedId(),7,-1,0,2) -- accesory
		SetPedComponentVariation(PlayerPedId(),8,7,0,2) -- undershirt
		SetPedComponentVariation(PlayerPedId(),9,-1,0,2) -- kevlar
		SetPedComponentVariation(PlayerPedId(),10,-1,0,2) -- badge
		SetPedComponentVariation(PlayerPedId(),11,5,0,2) -- torso 2
		SetPedPropIndex(PlayerPedId(),2,-1,0,2) -- ear
		SetPedPropIndex(PlayerPedId(),6,-1,0,2) -- watch
		SetPedPropIndex(PlayerPedId(),7,-1,0,2) -- bracelet
	end
end

function changeGender(model)
	local mhash = GetHashKey(model)
	while not HasModelLoaded(mhash) do
		RequestModel(mhash)
		Citizen.Wait(10)
	end

	if HasModelLoaded(mhash) then
		SetPlayerModel(PlayerId(),mhash)
		SetPedMaxHealth(PlayerPedId(),200)
		SetEntityHealth(PlayerPedId(),200)
		SetModelAsNoLongerNeeded(mhash)
	end
end

function FadeOutNet()
	if continuousFadeOutNetwork then 
		for _, id in ipairs(GetActivePlayers()) do
			if id ~= PlayerId() then
				NetworkFadeOutEntity(GetPlayerPed(id),false)
			end
		end
		SetTimeout(0, FadeOutNet)
	end
end

RegisterNUICallback('cDoneSave',function(data,cb)
	StartFade()
	isInCharacterMode = false
	SetNuiFocus(isInCharacterMode,isInCharacterMode)
	SendNUIMessage({ CharacterMode = isInCharacterMode, CharacterMode2 = isInCharacterMode, CharacterMode3 = isInCharacterMode })

	local coord = lastcoord or vector3(434.26, -622.37, 28.5)

	TriggerEvent('es_admin:teleportUser', coord.x, coord.y, coord.z - 1)
	SetEntityHeading(PlayerPedId(),f(158.62))
	continuousFadeOutNetwork = false

	for _, id in ipairs(GetActivePlayers()) do
		if id ~= PlayerId() and NetworkIsPlayerActive(id) then
			NetworkFadeInEntity(GetPlayerPed(id),true)
		end
	end

	TriggerEvent('skinchanger:loadSkin', currentCharacterMode)
	
	local relatedTable = Config.DefaultClothes[GetEntityModel(PlayerPedId())]
	local choosenClothe = math.random(1, #relatedTable)
	local cArray = json.decode(relatedTable[choosenClothe])
	for k,v in pairs(cArray) do
		currentCharacterMode[k] = v
		TriggerEvent('skinchanger:change', k, v)
	end

	local sosShirs = {['mask_1'] = -1,['mask_2'] = 0,['bproof_1'] = -1,	['bproof_2'] = 0,	['chain_1'] = -1,['chain_2'] = 0,['bags_1'] = -1,['bags_2'] = 0,['helmet_1'] = -1,	['helmet_2'] = 0,	['glasses_1'] = -1,	['glasses_2'] = 0,	['watches_1'] = -1,	['watches_2'] = 0,	['bracelets_1'] = -1,	['bracelets_2'] = 0} 

	for k,v in pairs(sosShirs) do
		currentCharacterMode[k] = v
		TriggerEvent('skinchanger:change', k, v)
	end

	TriggerServerEvent('esx_skin:save', currentCharacterMode)

	local playerName = characterNome ..'_'.. characterSobrenome
	TriggerServerEvent('esx:updateUserName', { playerName = playerName})
	TriggerServerEvent('es:newName', playerName)

	CreateCameraOnTop()
	EndFade()
	ReadToPlay()
end)

RegisterNUICallback('cChangeHeading',function(data,cb)
	SetEntityHeading(PlayerPedId(),f(data.camRotation)+180)
	cb('ok')
end)

RegisterNUICallback('ChangeGender',function(data,cb)
	currentCharacterMode.sex = tonumber(data.gender)
	if tonumber(data.gender) == 1 then
		changeGender("mp_f_freemode_01")
	else
		changeGender("mp_m_freemode_01")
	end
	refreshDefaultCharacter()
	TaskUpdateSkinOptions()
	TaskUpdateFaceOptions()
	TaskUpdateHeadOptions()
	cb('ok')
end)

RegisterNUICallback('UpdateSkinOptions',function(data,cb)
	currentCharacterMode.dad = data.dad
	currentCharacterMode.mom = data.mom
	currentCharacterMode.skin_md_weight = data.skin_md_weight -- skinColor
	currentCharacterMode.face_md_weight = data.face_md_weight * 100 -- shapeMix
	characterNome = data.characterNome
	characterSobrenome = data.characterSobrenome
	TaskUpdateSkinOptions()
	cb('ok')
end)

function TaskUpdateSkinOptions()
	local data = currentCharacterMode
	local face_weight = 		(data['face_md_weight'] / 100) + 0.0
	SetPedHeadBlendData(PlayerPedId(), data['dad'], data['mom'], 0, data['skin_md_weight'], 0, 0, face_weight, 0, 0, false)
end

RegisterNUICallback('UpdateFaceOptions',function(data,cb)
	currentCharacterMode.eye_color = data.eye_color
	currentCharacterMode.eyebrows_5 = data.eyebrows_5 * 10
	currentCharacterMode.eyebrows_6 = data.eyebrows_6 * 10
	currentCharacterMode.nose_1 = data.nose_1 * 10
	currentCharacterMode.nose_2 = data.nose_2 * 10
	currentCharacterMode.nose_3 = data.nose_3 * 10
	currentCharacterMode.nose_4 = data.nose_4 * 10
	currentCharacterMode.nose_5 = data.nose_5 * 10
	currentCharacterMode.nose_6 = data.nose_6 * 10
	currentCharacterMode.cheeks_1 = data.cheeks_1 * 10
	currentCharacterMode.cheeks_2 = data.cheeks_2 * 10
	currentCharacterMode.cheeks_3 = data.cheeks_3 * 10
	currentCharacterMode.lip_thickness = data.lip_thickness * 10
	currentCharacterMode.jaw_1 = data.jaw_1 * 10
	currentCharacterMode.jaw_2 = data.jaw_2 * 10
	currentCharacterMode.chin_1 = data.chin_1 * 10
	currentCharacterMode.chin_2 = data.chin_2 * 10
	currentCharacterMode.chin_3 = data.chin_3 * 10
	currentCharacterMode.chin_4 = data.chin_4 * 10
	currentCharacterMode.neck_thickness = data.neck_thickness * 10
	TaskUpdateFaceOptions()
	cb('ok')
end)

function TaskUpdateFaceOptions()
	local ped = PlayerPedId()
	local data = currentCharacterMode

	-- Olhos
	SetPedEyeColor(ped,data.eye_color)
	-- Sobrancelha
	SetPedFaceFeature(ped,6,data.eyebrows_5/10)
	SetPedFaceFeature(ped,7,data.eyebrows_6/10)
	-- Nariz
	SetPedFaceFeature(ped,0,data.nose_1/10)
	SetPedFaceFeature(ped,1,data.nose_2/10)
	SetPedFaceFeature(ped,2,data.nose_3/10)
	SetPedFaceFeature(ped,3,data.nose_4/10)
	SetPedFaceFeature(ped,4,data.nose_5/10)
	SetPedFaceFeature(ped,5,data.nose_6/10)
	-- Bochechas
	SetPedFaceFeature(ped,8,data.cheeks_1/10)
	SetPedFaceFeature(ped,9,data.cheeks_2/10)
	SetPedFaceFeature(ped,10,data.cheeks_3/10)
	-- Boca/Mandibula
	SetPedFaceFeature(ped,12,data.lip_thickness/10)
	SetPedFaceFeature(ped,13,data.jaw_1/10)
	SetPedFaceFeature(ped,14,data.jaw_2/10)
	-- Queixo
	SetPedFaceFeature(ped,15,data.chin_1/10)
	SetPedFaceFeature(ped,16,data.chin_2/10)
	SetPedFaceFeature(ped,17,data.chin_3/10)
	SetPedFaceFeature(ped,18,data.chin_4/10)
	-- Pescoço
	SetPedFaceFeature(ped,19,data.neck_thickness/10)
end

RegisterNUICallback('UpdateHeadOptions',function(data,cb)
	currentCharacterMode.hair_1 = data.hair_1
	currentCharacterMode.hair_2 = 0
	currentCharacterMode.hair_color_1 = data.hair_color_1
	currentCharacterMode.hair_color_2 = data.hair_color_2
	currentCharacterMode.eyebrows_1 = data.eyebrows_1
	currentCharacterMode.eyebrows_2 = 10
	currentCharacterMode.eyebrows_3 = data.eyebrows_3
	currentCharacterMode.eyebrows_4 = data.eyebrows_3
	currentCharacterMode.beard_1 = data.beard_1
	currentCharacterMode.beard_2 = 10
	currentCharacterMode.beard_3 = data.beard_3
	currentCharacterMode.beard_4 = data.beard_3
	currentCharacterMode.chest_1 = data.chest_1
	currentCharacterMode.chest_2 = 10
	currentCharacterMode.chest_3 = data.chest_3
	currentCharacterMode.blush_1 = data.blush_1
	currentCharacterMode.blush_2 = 10
	currentCharacterMode.blush_3 = data.blush_3
	currentCharacterMode.lipstick_1 = data.lipstick_1
	currentCharacterMode.lipstick_2 = 10
	currentCharacterMode.lipstick_3 = data.lipstick_3
	currentCharacterMode.lipstick_4 = data.lipstick_3
	currentCharacterMode.blemishes_1 = data.blemishes_1
	currentCharacterMode.blemishes_2 = 10
	currentCharacterMode.age_1 = data.age_1
	currentCharacterMode.age_2 = 10
	currentCharacterMode.complexion_1 = data.complexion_1
	currentCharacterMode.complexion_2 = 10
	currentCharacterMode.sun_1 = data.sun_1
	currentCharacterMode.sun_2 = 10
	currentCharacterMode.moles_1 = data.moles_1
	currentCharacterMode.moles_2 = 10
	currentCharacterMode.makeup_1 = data.makeup_1
	currentCharacterMode.makeup_2 = 10
	currentCharacterMode.makeup_3 = 0
	currentCharacterMode.makeup_4 = 0
	TaskUpdateHeadOptions()
	cb('ok')
end)

function TaskUpdateHeadOptions()
	local ped = PlayerPedId()
	local data = currentCharacterMode

	-- Cabelo
	SetPedComponentVariation(ped,2,data.hair_1,0,0)
	SetPedHairColor(ped,data.hair_color_1,data.hair_color_2)
	-- Sobracelha 
	SetPedHeadOverlay(ped,2,data.eyebrows_1,0.99)
	SetPedHeadOverlayColor(ped,2,1,data.eyebrows_3,data.eyebrows_3)
	-- Barba
	SetPedHeadOverlay(ped,1,data.beard_1,0.99)
	SetPedHeadOverlayColor(ped,1,1,data.beard_3,data.beard_3)
	-- Pelo Corporal
	SetPedHeadOverlay(ped,10,data.chest_1,0.99)
	SetPedHeadOverlayColor(ped,10,1,data.chest_3,data.chest_3)
	-- Blush
	SetPedHeadOverlay(ped,5,data.blush_1,0.99)
	SetPedHeadOverlayColor(ped,5,2,data.blush_3,data.blush_3)
	-- Battom
	SetPedHeadOverlay(ped,8,data.lipstick_1,0.99)
	SetPedHeadOverlayColor(ped,8,2,data.lipstick_3,data.lipstick_3)
	-- Manchas
	SetPedHeadOverlay(ped,0,data.blemishes_1,0.99)
	-- Envelhecimento
	SetPedHeadOverlay(ped,3,data.age_1,0.99)
	-- Aspecto
	SetPedHeadOverlay(ped,6,data.complexion_1,0.99)
	-- Pele
	SetPedHeadOverlay(ped,7,data.sun_1,0.99)
	-- Sardas
	SetPedHeadOverlay(ped,9,data.moles_1,0.99)
	-- Maquiagem
	SetPedHeadOverlay(ped,4,data.makeup_1,0.99)
	SetPedHeadOverlayColor(ped,4,0,0,0)
end