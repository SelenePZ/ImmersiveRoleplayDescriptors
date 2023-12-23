PlaceableScenes = PlaceableScenes or {}
PlaceableScenes.Exclamations = PlaceableScenes.Exclamations or {
    ["RPDescriptors.ExclamationRed"] = {r=255, g=0, b=0},
    ["RPDescriptors.ExclamationOrange"] = {r=255, g=165, b=0},
    ["RPDescriptors.ExclamationYellow"] = {r=255, g=255, b=0},
    ["RPDescriptors.ExclamationGreen"] = {r=0, g=255, b=0},
    ["RPDescriptors.ExclamationBlue"] = {r=0, g=0, b=255},
    ["RPDescriptors.ExclamationPink"] = {r=255, g=105, b=180},
    ["RPDescriptors.ExclamationPurple"] = {r=128, g=0, b=128},
    ["RPDescriptors.ExclamationWhite"] = {r=255, g=255, b=255},
    ["RPDescriptors.ExclamationGrey"] = {r=128, g=128, b=128},
    ["RPDescriptors.ExclamationBlack"] = {r=0, g=0, b=0}
}
PlaceableScenes.Questions = PlaceableScenes.Questions or {
    ["RPDescriptors.QuestionRed"] = {r=255, g=0, b=0},
    ["RPDescriptors.QuestionOrange"] = {r=255, g=165, b=0},
    ["RPDescriptors.QuestionYellow"] = {r=255, g=255, b=0},
    ["RPDescriptors.QuestionGreen"] = {r=0, g=255, b=0},
    ["RPDescriptors.QuestionBlue"] = {r=0, g=0, b=255},
    ["RPDescriptors.QuestionPink"] = {r=255, g=105, b=180},
    ["RPDescriptors.QuestionPurple"] = {r=128, g=0, b=128},
    ["RPDescriptors.QuestionWhite"] = {r=255, g=255, b=255},
    ["RPDescriptors.QuestionGrey"] = {r=128, g=128, b=128},
    ["RPDescriptors.QuestionBlack"] = {r=0, g=0, b=0}
}

function PlaceableScenes.OnFillWorldObjectContextMenu(playerIndex, context, worldObjects, test)
    for i,v in ipairs(worldObjects) do
        if instanceof(v, "IsoWorldInventoryObject") and (PlaceableScenes.Exclamations[v:getItem():getFullType()] or PlaceableScenes.Questions[v:getItem():getFullType()]) then
            local readOption = context:addOptionOnTop(getText("ContextMenu_IRPD_InvestigateScene"), v:getItem(), ISInventoryPaneContextMenu.onWriteSomething, false, playerIndex)
            readOption.iconTexture = getTexture("media/ui/Search_Icon_Off.png");
        end
    end

    PlaceableScenes.CreateScenesSubMenu(playerIndex, context, worldObjects, test, getText("ContextMenu_IRPD_CreateExclamation"), PlaceableScenes.Exclamations, "RPDescriptors.ExclamationWhite")
    PlaceableScenes.CreateScenesSubMenu(playerIndex, context, worldObjects, test, getText("ContextMenu_IRPD_CreateInvestigation"), PlaceableScenes.Questions, "RPDescriptors.QuestionWhite")
end

function PlaceableScenes.CreateScenesSubMenu(playerIndex, context, worldObjects, test, title, items, topLevelItemName)
    local createOption = context:addOption(title, worldobjects, nil);
    local topLevelItem = getScriptManager():FindItem(topLevelItemName)
    createOption.iconTexture = topLevelItem and topLevelItem:getNormalTexture() or nil
    local exclamationSubMenu = context:getNew(context);
    context:addSubMenu(createOption, exclamationSubMenu);

    for k,v in pairs(items) do
        local scriptItem = getScriptManager():FindItem(k)
        local name = scriptItem and scriptItem:getDisplayName() or k
        local option = exclamationSubMenu:addOption(name, worldobjects, PlaceableScenes.onCreateScene, true, playerIndex, k);
        option.iconTexture = scriptItem and scriptItem:getNormalTexture() or nil
    end
end

function PlaceableScenes.OnFillInventoryObjectContextMenu(player, context, items)
    local testItem = nil
    local sceneItem = nil
    for i,v in ipairs(items) do
        if not instanceof(v, "InventoryItem") then
            testItem = v.items[1]
        else 
            testItem = v
        end
        if PlaceableScenes.Exclamations[testItem:getFullType()] or PlaceableScenes.Questions[testItem:getFullType()] then
            sceneItem = testItem
            break
        end
    end
    if sceneItem then
        local sceneOptionsSubMenu = context:getNew(context)

        if sceneItem:getWorldItem() ~= nil then
            context:removeOptionByName(getText("ContextMenu_IRPD_Grab"))
            context:removeOptionByName(getText("ContextMenu_IRPD_Equip_Primary"))
            context:removeOptionByName(getText("ContextMenu_IRPD_Equip_Secondary"))
            local placeOption = context:getOptionFromName(getText("ContextMenu_IRPD_PlaceItemOnGround"))
            if placeOption then
                placeOption.name = getText("ContextMenu_MoveScene")
            end

            sceneOptionsSubMenu:addOption(getText("ContextMenu_IRPD_PickupSceneForEdit"), {sceneItem}, ISInventoryPaneContextMenu.onGrabItems, player)
        else
            local placeOption = context:getOptionFromName(getText("ContextMenu_IRPD_PlaceItemOnGround"))
            if placeOption then
                placeOption.name = getText("ContextMenu_IRPD_PlaceScene")
            end

            sceneOptionsSubMenu:addOption(getText("ContextMenu_IRPD_EditScene"), sceneItem, PlaceableScenes.onEditScene, true, player)
        end

        local readOption = nil
        for _,option in ipairs(context.options) do
            if option.onSelect == ISInventoryPaneContextMenu.onWriteSomething then
                readOption = option
                break
            end
        end
        if readOption then
            readOption.name = getText("ContextMenu_IRPD_InvestigateScene")
            readOption.iconTexture = getTexture("media/ui/Search_Icon_Off.png");
        end

        local sceneOptions = context:addOption(getText("ContextMenu_IRPD_SceneOptions"), sceneItem, nil)
        context:addSubMenu(sceneOptions, sceneOptionsSubMenu)
        
        sceneOptionsSubMenu:addOption(getText("ContextMenu_IRPD_DeleteScene"), sceneItem, PlaceableScenes.onDeleteScene, player)
    end
end

function PlaceableScenes.onCreateScene(worldobjects, editable, player, type)
    local playerObj = getSpecificPlayer(player)
    local item = playerObj:getInventory():AddItem(type)
    local fontHgt = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
    local height = 110 + (15 * fontHgt);
    local modal = ISUICreateScene:new(0, 0, 350, height, nil, PlaceableScenes.onCreateSceneClick, playerObj, item, item:seePage(1), item:getName(), 15, editable, item:getPageToWrite());
    modal:initialise();
    modal:addToUIManager();
    if JoypadState.players[player+1] then
        setJoypadFocus(player, modal)
    end
end

function PlaceableScenes.onEditScene(item, editable, player)
    local playerObj = getSpecificPlayer(player)
    local fontHgt = getTextManager():getFontFromEnum(UIFont.Small):getLineHeight()
    local height = 110 + (15 * fontHgt);
    local modal = ISUICreateScene:new(0, 0, 350, height, nil, PlaceableScenes.onCreateSceneClick, playerObj, item, item:seePage(1), item:getName(), 15, editable, item:getPageToWrite());
    modal:initialise();
    modal:addToUIManager();
    if JoypadState.players[player+1] then
        setJoypadFocus(player, modal)
    end
end

function PlaceableScenes:onCreateSceneClick(button)
    if button.internal == "OK" then
        for i,v in ipairs(button.parent.newPage) do
            button.parent.notebook:addPage(i,v);
        end
        local title = button.parent.title:getText()
        button.parent.notebook:setName(title);
        button.parent.notebook:setCustomName(true);

        local player = getSpecificPlayer(button.parent.playerNum)
        local x = player:getX()
        local y = player:getY()
        local z = player:getZ()
        ISLogSystem.sendLog(player, "tracking", "[" .. player:getUsername() .. "][" .. player:getDescriptor():getForename() .. "][".. player:getDescriptor():getSurname() .."][CreateScene][" .. x .. "," .. y .. "," .. z .. "] " .. title .. "," .. tostring(button.parent.notebook:seePage(1)))

        ISInventoryPaneContextMenu.onPlaceItemOnGround({button.parent.notebook}, player)
    end
end

function PlaceableScenes.onDeleteScene(item, player)
    local width = 350;
	local x = getPlayerScreenLeft(player) + (getPlayerScreenWidth(player) - width) / 2
	local height = 120;
	local y = getPlayerScreenTop(player) + (getPlayerScreenHeight(player) - height) / 2
	local modal = ISModalDialog:new(x,y, width, height, getText("IGUI_IRPD_ConfirmDeleteScene"), true, item, PlaceableScenes.onDeleteSceneConfirm, player);
	modal:initialise()
	modal:addToUIManager()
	if JoypadState.players[player+1] then
		modal.prevFocus = JoypadState.players[player+1].focus
		setJoypadFocus(player, modal)
	end
end

function PlaceableScenes.onDeleteSceneConfirm(target, button)
	if button.internal == "YES" then
        local player = getSpecificPlayer(button.player)
        local x = player:getX()
        local y = player:getY()
        local z = player:getZ()
        ISLogSystem.sendLog(player, "tracking", "[" .. player:getUsername() .. "][" .. player:getDescriptor():getForename() .. "][".. player:getDescriptor():getSurname() .."][DeleteScene][" .. x .. "," .. y .. "," .. z .. "] " .. target:getName())
		ISRemoveItemTool.removeItem(target, button.player)
	end
end

function PlaceableScenes.OnPlayerUpdate(player)
    if not player:isLocalPlayer() then
        return
    end

    local x = math.floor(player:getX())
    local y = math.floor(player:getY())
    local z = math.floor(player:getZ())
    local range = 2
    for xo=-range, range do
        for yo=-range, range do
            local square = getSquare(x + xo, y + yo, z)
            if square then
                local worldObjects = square:getWorldObjects()
                for i=0,worldObjects:size()-1 do
                    local object = worldObjects:get(i)
                    local item = object:getItem()
                    local sceneItemType = PlaceableScenes.Exclamations[item:getFullType()] or PlaceableScenes.Questions[item:getFullType()]
                    if sceneItemType then
                        local objectModData = object:getModData()
                        local nowms = getTimestampMs()
                        local lastSceneHaloMs = objectModData.lastSceneHaloMs or 0
                        if nowms - lastSceneHaloMs > 50 then
                            if player:isFacingObject(object, 0.8) then
                                player:setHaloNote("[img=Question_On]  " .. item:getName(), sceneItemType.r, sceneItemType.g, sceneItemType.b, 50)
                                objectModData.lastSceneHaloMs = nowms
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(PlaceableScenes.OnFillWorldObjectContextMenu)
Events.OnFillInventoryObjectContextMenu.Add(PlaceableScenes.OnFillInventoryObjectContextMenu)
Events.OnPlayerUpdate.Add(PlaceableScenes.OnPlayerUpdate)