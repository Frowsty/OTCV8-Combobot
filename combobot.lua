--[[
Author: Frosty (Discord: Frosty#0186)

Description: The reason for making this script is to hopefully teach aspiring scripters in the otcv8 community. Since releasing scripts that had the code hidden wasn't very
             popular amongst some people I chose to turn it into a script that goes through everything bit by bit. Hopefully some can appreaciate the effort I have put into
             writing the explanations for every thing that is being done in this script and for making it in the first place. It has taken quite some time to make it work.
             I hope to see more coders out there releasing their scripts to we can grow the community and help eachother more.

License: Copyright (C) 2020 - Frosty

         Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
         to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
         and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

         The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

         THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
         FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
         WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

-- Everything is in a function that is being called in the bottom of the script. Not sure why I did it like this... I guess I just like the way it looks.
-- It doesn't change anything to the script itself just the aesthetic of the code.
function comboBotScript()
  -- Here we make sure to initialize all storage variables that are being used in the script
  if not storage.defaultTabCombo then
    storage.defaultTabCombo = "Main"
  end
  if not storage.comboLeader then
    storage.comboLeader = "Name"
  end
  if not storage.comboUE then
    storage.comboUE = "Spell"
  end
  if not storage.comboRune then
    storage.comboRune = "RuneID"
  end
  if not storage.sendHotkey then
    storage.sendHotkey = "F10"
  end
  if not storage.comboType then
    storage.comboType = "ue"
  end
  if storage.defaultTabCombo then
    setDefaultTab(storage.defaultTabCombo)
  end
  -- Just a title with separators, same as we did before in the script to indicate leader options
  addSeparator()
  addLabel("combobot", "COMBOBOT")
  addSeparator()
  -- Here we allow the user to set a default tab. This requires a restart to the script in order to take action
  addLabel("setDefaultTabCombo", "Tab Name:")
  addTextEdit("defaultTabValueCombo", storage.defaultTabCombo or "Main", function(widget, text)
    storage.defaultTabCombo = text
  end)

  -- This is where we close the channel window, we have to open it in the first place because the client cannot find channels it has not discovered yet
  -- This function will always run but only do anything if we set the shouldCloseWindow variable to true and that is only done if we have opened the channel window to begin with
  -- The macro itself looks for the channel window by going using modules to access the game_console module where we then can access the channelsWindow variable
  -- using this variable we can find the cancel button within the window and execute the onClick function that the cancel button has
  local shouldCloseWindow = false
  local firstInvitee = true
  local isInComboTeam = false
  macro(10, function()
    if shouldCloseWindow then
      local channelsWindow = modules.game_console.channelsWindow
      if channelsWindow then
        local child = channelsWindow:getChildById("buttonCancel")
        if child then
          child:onClick()
          shouldCloseWindow = false
          isInComboTeam = true
        end
      end
    end
  end)

  function matchPos(x, y, z, dest)
    if dest then
      return x == dest.x and y == dest.y and z == dest.z
    end
    return true
  end

  -- This is the main switch for the whole macro
  local mainSwitch = macro(1000, "Enable ComboBot", function() end)
  -- A little side not to make sure that you're connected to the server in order to make use of Follow Leader
  addLabel("id3", 'Follow Leader REQUIRES "Connect to server"')
  -- This is the follow leader switch, it will not be toggleable if we don't have a websocket (BotServer connection)
  local followMacro = macro(10, "Follow Leader", function(m) if not BotServer._websocket then m.setOff() end end)

  -- This is a label to indicate the current server status (If you're connected or disconnected)
  local serverStatus = addLabel("serverStatusText", "Server Status: Disconnected")
  macro(10, function() 
    if BotServer._websocket then 
      serverStatus:setText("Server Status: Connected")
      serverStatus:setColor("green")
    else 
        serverStatus:setText("Server Status: Disconnected")
        serverStatus:setColor("red")
    end
  end)

  -- This is where we initialize our botserver and add a listener to it
  -- This part of the script is specifically for the follow leader
  -- We make sure that there's an accessKey since this is the channelID we will use for the server
  -- If we can establish that there is an accessKey and we haven't already created a websocket we will initialize the BotServer
  -- Once we have initialized the BotServer we add a listener to listen for the message "followPos" if the server receives a message
  -- containing the id "followPos" we make sure that we have enabled the macro "Follow Leader" and that our position is not already the position that was sent to us
  -- If we can make sure that we're not already at the position we we're send we make use of the autoWalk function which will automatically find a path for use to use
  -- We then reset the followPosition variable to listen for new position from the leader
  -- We also make sure to give an error message if we already have a server running
  local followPosition = nil
  local startFollowServer = addButton("button4", "Connect to server", function()
    if storage.accessKey and not BotServer._websocket then
      BotServer.init(name(), storage.accessKey)
      --info("Server connection established")
      --info("Server ID: " .. storage.accessKey)
      if BotServer._websocket then
        BotServer.listen("followPos", function(name, message)
          if storage.comboLeader then
            if name:lower() == storage.comboLeader:lower() then
              followPosition = message
            end
          end
          if followMacro.isOn() and followPosition then
            if not matchPos(posx(), posy(), posz(), followPosition) then
              if autoWalk(followPosition, 20, {ignoreNonPathable=true, precision=1, ignoreStairs=false}) then end
              followPosition = nil
            end
          end
        end)
        BotServer.listen("onUse", function(name, message)
          if storage.comboLeader then
            if name:lower() == storage.comboLeader:lower() then
              local tile = g_map.getTile(message.position)
              if tile and followMacro.isOn() then
                use(tile:getTopUseThing())
              end
            end
          end
        end)
        BotServer.listen("onUseWith", function(name, message)
          if storage.comboLeader then
            if name:lower() == storage.comboLeader:lower() then
              local tile = g_map.getTile(message.position)
              if tile and followMacro.isOn() then
                useWith(message.id)
              end
            end
          end
        end)
      end
    else
      error("Server already initialized")
    end
  end)
  -- This is where we terminate the connection assuming that we have one. If we don't have one we will also state this to the user
  local terminateFollowServer = addButton("button5", "Disconnect from Server", function()
    if BotServer._websocket then
      BotServer.terminate()
      --info("Disconnected from server!")
    else
      error("Not connected to any server!")
    end
  end)

  -- Here we add seaparator and a title text to let the users of this script know that this is settings only the leader should change
  -- We add labels to indicate if Allow Follow is on. If Allow Follow is on we simply state in the label that it is on. We can change this text using
  -- a variable that contains addLabel and then accessing the child function called :setText("text here"). We can also change color of the text by doing
  -- :setColor("hex number here") you can also use green/red/yellow/blue or white in setColor but I suggest using hexnumbers instead. Way more accurate
  -- and it supports all colors in the color spectrum. We also use a "always-on" macro to determine if any variable states have changed and change the color accordingly
  -- The first string in addLabel / addButton is just an id, this can be called anything. Try to name it accordingly however I have done some errors naming mine in this script 
  addSeparator()
  addLabel("id4", "LEADER SETTINGS")
  addSeparator()
  local allowFollow = "off"
  local typeText = addLabel("leaderSettings", "Combo Type: UE")
  local followText = addLabel("leaderRecordPos", "Allow Follow: OFF")
  local ueCombo = addButton("ueCombo", "UE Combo", function() storage.comboType = "ue" end)
  local runeCombo = addButton("runeCombo", "RUNE Combo", function() storage.comboType = "rune" end)
  local allowFollowBtn = addButton("followBtn", "Allow Follow", function() if allowFollow == "off" then allowFollow = "on" else allowFollow = "off" end end)
  macro(10, function() 
    if storage.comboType == "ue" then typeText:setColor("#45b1d1") else typeText:setColor("#171717") end
    if allowFollow == "on" then followText:setColor("green") else followText:setColor("red") end
    typeText:setText("Combo Type: " .. storage.comboType:upper())
    followText:setText("Allow Follow: " .. allowFollow:upper())
  end)
  addSeparator()

  -- Here we make the request from the player to join the team
  -- We use some wonky check to make sure a key is entered and that leaders name is set (This could most likely be improved by a lot)
  addButton("combobotInv", "Join Combo Team", function()
    if storage.comboLeader ~= "Name" and storage.accessKey ~= "" then
      talkPrivate(storage.comboLeader, "request invite " .. storage.accessKey)
    else
      error("Request failed. Make sure you entered a key!")
    end
  end)

  -- Here we're creating text fields and labels for the user ot know what each text field input does.
  -- This is where we grab accessKey for combo team, rune ID, UE combo spell and the leaders name from
  -- We save everything to a config file called storage.json, to access variables saved in storage we simply type
  -- storage. and then the name of the variable which in this case is everything from accessKey to comboRune
  addLabel("comboAccessKey", "Access Key (Numbers Only):")
  addTextEdit("comboAccessKeyValue", storage.accessKey or "Access Key", function(widget, text)
    storage.accessKey = text
  end)
  addLabel("sendHotkey", "Command Hotkey:")
  addTextEdit("hotkeyValue", storage.sendHotkey or "Hotkey", function(widget, text)
    storage.sendHotkey = text
  end)
  addLabel("leaderText", "Leader name:")
  addTextEdit("leaderValue", storage.comboLeader or "Name", function(widget, text)
    storage.comboLeader = text
  end)
  addLabel("comboSpell", "UE Spell:")
  addTextEdit("comboUEVal", storage.comboUE or "Spell", function(widget, text)
    storage.comboUE = text
  end)
  addLabel("comboRune", "Rune ID:")
  addTextEdit("comboRuneVal", storage.comboRune or "RuneID", function(widget, text)
    storage.comboRune = text
  end)

  -- This function is quite large. This is where we read for any normal message sent in-game
  -- any message sent in party chat can be picked up here. We make sure the main macro is on (Enable combobot)
  -- If the main macro is on our next mission is to make sure the name of the sender is the same of our comboLeader
  -- To make sure we don't do any capitalization errors we make the whole string lower-case by using :lower() on strings
  -- After we have established that the message is from the leader we make sure that we can find the keywords in the message
  -- We do that by string finding "combo UE" or "combo RUNE" with the lua function called string.find(text, "condition here")
  -- After we can confirm that the message contains a keyword we check if the leader has sent us a targetID to attack (this is a unique ID of a target in the game)
  -- We can check for this since there's only 1 set of numbers in the text from the leader and that would be the targetID so we use string.match to find the numbers
  -- String.match(text, "condition which in this case is all numbers -> %d.*"). If we found a targetID we will make sure we're not already attacking this target
  -- To check if we're attacking the target that was sent to us we check the Id of getAttackingCreature() and match it with targetID that we found in the text
  -- If it's not the same target we make sure to attack the targetID by getting the creature object from targetID by using g_map.getCreatureById(tonumber(targetID))
  -- We use the tonumber lua function because targetID is initially a string that contains only numbers. If we successfully get the target we can then attack it
  -- But if we were already attacking targetID then we simply just skip all other checks and go straight to saying the UE spell
  -- The same principle applies to the rune combo part. Only difference is that if we can't find any monsters what so ever we simply won't use any rune at all
  onTalk(function(name, level, mode, text, channelId, pos)
    if mainSwitch.isOn() then
      if name:lower() == storage.comboLeader:lower() and player:getName():lower() ~= storage.comboLeader:lower() and channelId == 1 then
        if string.find(text, "combo UE") then
          local targetID = string.match(text, "%d.*")
          if targetID then
            if g_game.isAttacking() then
              if g_game.getAttackingCreature():getId() ~= tonumber(targetID) then
                local target = g_map.getCreatureById(tonumber(targetID))
                if target then
                  g_game.attack(target)
                end
              end
            else
              local target = g_map.getCreatureById(tonumber(targetID))
              if target then
                g_game.attack(target)
              end
            end
          end
          say(storage.comboUE)
        end
        if string.find(text, "combo RUNE") then
          local targetID = string.match(text, "%d.*")
          local rune = Item.create(storage.comboRune)
          if targetID and rune then
            if g_game.isAttacking() then
              if g_game.getAttackingCreature():getId() ~= tonumber(targetID) then
                local target = g_map.getCreatureById(tonumber(targetID))
                if target then
                  g_game.attack(target)
                end
              end
            else
              local target = g_map.getCreatureById(tonumber(targetID))
              if target then
                g_game.attack(target)
              end
            end
            g_game.useWith(rune, g_game.getAttackingCreature())
          elseif rune then
            if g_game.isAttacking() then
              g_game.useWith(rune, g_game.getAttackingCreature())
            end
          end
        end
      end
      -- Inside of ontalk we can also detect private messages, using private messages we can detect if someone has requested and invite
      -- If we can find the string "request invite" using string.find(text, "request invite") then we make sure to look for an accessKey
      -- using the string.match function again and just like last time to find numbers in a string we simply input the pattern %d.*
      -- If we were able to match the accessKey with our own we make sure that we can find the player using getCreatureByName
      -- If we can find the player we will invite the player. If the player that requested and invite was the first ever to join the combo team
      -- We will have to open the channels window to grab the party channel and this is when we set the shouldCloseWindow that is being used
      -- further up in the code in order to close the window to true. Once that has been set to true we then set firstInvitee to false since
      -- next person will no longer be the first person we invite to the party.
      -- If for some reason the accessKey was not correct we will simply just reply back to the person who requested and invite that they have the incorrect accessKey
      if mode == 4 then
        if string.find(text, "request invite") then
          local access = string.match(text, "%d.*")
          if access and access == storage.accessKey then
            local minion = getCreatureByName(name)
            if minion then
              g_game.partyInvite(minion:getId())
              if firstInvitee then
                g_game.requestChannels()
                g_game.joinChannel(1)
                shouldCloseWindow = true
                firstInvitee = false
              end
            end
          else
            talkPrivate(name, "Incorrect access key!")
          end
        end
      end
    end
  end)
  -- Whenever the player gets a text message from the server this callback will execute
  -- We're checking for the invited to party message here and then we use regex to find the players name
  -- We know that the players name will be the first ever string in the text that's why we can comfortably check for any group of characters
  -- in the text and pick the first entry in the regex table that is created with the regexMatch function
  -- You can read more on regex at regex101.com or google regex
  onTextMessage(function(mode, text)
    if mainSwitch.isOn() then
      if mode == 20 then
        if string.find(text, "invited you to") then
          local regex = "[a-zA-Z]*"
          local regexData = regexMatch(text, regex)
          if regexData[1][1]:lower() == storage.comboLeader:lower() then
            local leader = getCreatureByName(regexData[1][1])
            if leader then
              g_game.partyJoin(leader:getId())
              g_game.requestChannels()
              g_game.joinChannel(1)
              shouldCloseWindow = true
            end
          end
        end
      end
    end
  end)
  -- This is where we check for keyboard input and if they press the key it will send a message to party channel
  local shouldSend = true
  local partyChannel = 1
  onKeyDown(function(keys)
    if mainSwitch.isOn() then
      if keys == storage.sendHotkey and shouldSend then
        if storage.comboType == "ue" then
          if g_game.isAttacking() then
            talkChannel(partyChannel, "combo UE " .. g_game.getAttackingCreature():getId())
          else
            talkChannel(partyChannel, "combo UE")
          end
          say(storage.comboUE)
        elseif storage.comboType == "rune" then
          if g_game.isAttacking() then
            talkChannel(partyChannel, "combo RUNE " .. g_game.getAttackingCreature():getId())
          else
            talkChannel(partyChannel, "combo RUNE")
          end
        end
        shouldSend = false
      end
    end
  end)
  -- This is resetting shouldSend to make sure the leader isn't accidentally spamming by holding the button down.
  -- That's why we only allow sending a message if shouldSend is true and as soon as the command hotkey is pressed we're setting shouldSend to false
  -- and then re-assigning it to true when the command key is not pressed anymore.
  onKeyUp(function(keys)
    if mainSwitch.isOn() then
      if not shouldSend then
        shouldSend = true
      end
    end
  end)

  -- Here we make sure to only send the leaders position if he's allowing follow, having an open connection with the server
  -- and if he is in the combo team which we assign earlier in the code
  onPlayerPositionChange(function(newPos, oldPos)
    if allowFollow == "on" and BotServer._websocket and isInComboTeam then
      BotServer.send("followPos", newPos)
    end
  end)

  onUse(function(pos, itemId, stackPos, subType)
    if allowFollow == "on" and BotServer._websocket and isInComboTeam then
      BotServer.send("onUse", {position = pos, id = itemId})
    end
  end)
  local useWithList = {3003, 646}
  onUseWith(function(pos, itemId, target, subType)
    info("onUseWith " .. itemId)
    if allowFollow == "on" and BotServer._websocket and isInComboTeam then
      if table.find(useWithList, itemId) then
        BotServer.send("useWith", {position = pos, id = itemId})
      end
    end
  end)
end

-- Since we made the script in a huge function we just call that function here
comboBotScript()