-- ============================================================
-- SPIRIT FRUIT SMART GRINDER & AUTO-COLLECT (24/7 SECURE & CLEAN)
-- REAL-TIME / MULTI-FRUIT / SAFE WEATHER MATCHING
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

print("============================================================")
print("[SmartGrinder] Gestartet im 24/7 Endlos-Modus (Auto-Cleanup & Safe Retry)")
print("[SmartGrinder] JobId:", game.JobId)
print("============================================================")

-- ============================================================
-- KONFIGURATION
-- ============================================================
local WEATHER_ORDER = {
    {weather = "Misty",         mutation = "Dewy"},
    {weather = "Sandstorm",     mutation = "Dusty"},
    {weather = "Blizzard",      mutation = "Frosted"},
    {weather = "Acid-Rain",     mutation = "Radioactive"},
    {weather = "Rainbow",       mutation = "Golden"},
    {weather = "Meteor Shower", mutation = "Cosmic"}
}

local TARGET_COUNT = #WEATHER_ORDER
local FRUIT_COUNT = 4
local WEATHER_UPDATE_INTERVAL = 1.0
local FRUIT_UPDATE_INTERVAL = 0.75
local HOP_CONFIRM_DELAY = 1.5
local TELEPORT_COOLDOWN = 5.0

-- ============================================================
-- STATUS & PERSISTENTE DATEN
-- ============================================================
local autoHopEnabled = true
local teleporting = false

local cachedCurW = "Laden..."
local cachedNextW = "Laden..."
local weatherDataReady = false
local weatherReadError = true

local hopPending = false
local hopPendingSince = 0
local lastTeleportFail = 0

local collectedInstances = {}

local VISITED_FILE = "SmartGrinder_Visited.json"
local visitedServers = {}

pcall(function()
    if isfile and readfile and isfile(VISITED_FILE) then
        local data = HttpService:JSONDecode(readfile(VISITED_FILE))
        if type(data) == "table" then
            visitedServers = data
        end
    end
end)

visitedServers[game.JobId] = os.time()
pcall(function()
    if writefile then
        writefile(VISITED_FILE, HttpService:JSONEncode(visitedServers))
    end
end)

-- ============================================================
-- GUI AUFRÄUMEN & AUFBAU
-- ============================================================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("SpiritGrinderGUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpiritGrinderGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 435)
mainFrame.Position = UDim2.new(0, 25, 0, 80)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 65)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 38)
header.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -20, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🌱 SMART GRINDER <font color='#8888aa'>(24/7 Secure)</font>"
titleLabel.RichText = true
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -20, 1, -48)
contentContainer.Position = UDim2.new(0, 10, 0, 44)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 4)
contentLayout.Parent = contentContainer

local function createRow(name, sizeY, textSize)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.Size = UDim2.new(1, 0, 0, sizeY or 20)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    lbl.TextSize = textSize or 12
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.TextWrapped = true
    lbl.Parent = contentContainer
    return lbl
end

local lblWeather = createRow("LblWeather", 20, 12)
local lblNextWeather = createRow("LblNextWeather", 20, 12)

local div1 = Instance.new("Frame")
div1.Size = UDim2.new(1, 0, 0, 1)
div1.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
div1.BorderSizePixel = 0
div1.Parent = contentContainer

local fruitLabels = {}
for i = 1, FRUIT_COUNT do
    fruitLabels[i] = createRow("Fruit" .. i, 38, 11)
end

local div2 = Instance.new("Frame")
div2.Size = UDim2.new(1, 0, 0, 1)
div2.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
div2.BorderSizePixel = 0
div2.Parent = contentContainer

local lblPhase = createRow("LblPhase", 22, 11)
lblPhase.Font = Enum.Font.GothamBold
lblPhase.TextColor3 = Color3.fromRGB(100, 200, 255)

local lblTarget = createRow("LblTarget", 24, 11)
lblTarget.Font = Enum.Font.GothamBold
lblTarget.TextColor3 = Color3.fromRGB(255, 190, 80)

local lblNeeded = createRow("LblNeeded", 24, 11)
lblNeeded.Font = Enum.Font.GothamBold
lblNeeded.TextColor3 = Color3.fromRGB(80, 255, 120)

local hopButton = Instance.new("TextButton")
hopButton.Size = UDim2.new(1, 0, 0, 30)
hopButton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
hopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hopButton.TextSize = 12
hopButton.Font = Enum.Font.GothamBold
hopButton.Text = "Auto-Hop: AN"
hopButton.Parent = contentContainer

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = hopButton

hopButton.MouseButton1Click:Connect(function()
    autoHopEnabled = not autoHopEnabled
    hopPending = false
    teleporting = false

    if autoHopEnabled then
        hopButton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
        hopButton.Text = "Auto-Hop: AN"
    else
        hopButton.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
        hopButton.Text = "Auto-Hop: AUS (Manuell)"
    end
end)

local function resetUIState(phaseText, targetText, neededText)
    lblPhase.Text = phaseText
    lblTarget.Text = targetText
    lblNeeded.Text = neededText
    for i = 1, FRUIT_COUNT do
        fruitLabels[i].Text = string.format("Frucht %d: Warten...", i)
        fruitLabels[i].TextColor3 = Color3.fromRGB(120, 120, 140)
    end
end

-- ============================================================
-- HILFSFUNKTIONEN
-- ============================================================
local function cleanString(str)
    if str == nil then return "" end
    return tostring(str):lower():gsub("[%s_%-]+", "")
end

local function normalizeMutation(str)
    if str == nil then return "" end
    return tostring(str):lower():gsub("[%s_%-]+", "")
end

local function isValidWeather(weather)
    if weather == nil then return false end
    local value = tostring(weather)
    if value == "" or cleanString(value) == "unknown" or cleanString(value) == "laden" then return false end
    return true
end

local function getActiveWeather()
    local currentWeatherObj = ReplicatedStorage:FindFirstChild("CurrentWeather") or ReplicatedStorage:FindFirstChild("CurrentWeather", true)
    if currentWeatherObj then
        local value = nil
        if currentWeatherObj:IsA("ValueBase") then value = currentWeatherObj.Value
        elseif currentWeatherObj:IsA("TextLabel") or currentWeatherObj:IsA("TextBox") then value = currentWeatherObj.Text end
        if value == nil or tostring(value) == "" then
            value = currentWeatherObj:GetAttribute("Value") or currentWeatherObj:GetAttribute("Weather") or currentWeatherObj:GetAttribute("CurrentWeather")
        end
        if value ~= nil and tostring(value) ~= "" then return tostring(value) end
    end
    local attrWeather = ReplicatedStorage:GetAttribute("CurrentWeather")
    if attrWeather ~= nil and tostring(attrWeather) ~= "" then return tostring(attrWeather) end
    return "Unknown"
end

local function getNextWeather()
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "GetNextWeather" and desc:IsA("RemoteFunction") then
            local success, result = pcall(function() return desc:InvokeServer() end)
            if success then
                if type(result) == "table" then return tostring(result.key or result.Name or result.weather or result.Weather or "Unknown")
                elseif type(result) == "string" then return result end
            end
        end
    end
    return "Unknown"
end

local function getPlayerSpiritTree()
    local bigField = Workspace:FindFirstChild("BigField")
    if not bigField then return nil end
    local playerPlots = bigField:FindFirstChild("PlayerPlots")
    if not playerPlots then return nil end

    local myPlot = nil
    for _, plot in ipairs(playerPlots:GetChildren()) do
        if tonumber(plot:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then
            myPlot = plot
            break
        end
    end
    if not myPlot then return nil end

    for _, child in ipairs(myPlot:GetChildren()) do
        if child:GetAttribute("SeedType") == "Spirit" then return child end
    end
    for _, child in ipairs(myPlot:GetDescendants()) do
        if child:GetAttribute("SeedType") == "Spirit" then return child end
    end
    return nil
end

local function getFruitMap(fruitSpawnsFolder)
    local fruitMap = {}
    for _, obj in ipairs(fruitSpawnsFolder:GetChildren()) do
        local rawIndex = obj:GetAttribute("SpawnIndex")
        local idx = tonumber(rawIndex)
        if idx and idx >= 1 and idx <= FRUIT_COUNT and idx % 1 == 0 and fruitMap[idx] == nil then
            fruitMap[idx] = obj
        end
    end
    for i = 1, FRUIT_COUNT do
        if fruitMap[i] == nil then return nil end
    end
    return fruitMap
end

local function getMutationData(spawnObj)
    if not spawnObj then return {count = 0, found = {}, missing = WEATHER_ORDER, raw = nil} end
    local raw = spawnObj:GetAttribute("FruitMutations")
    local foundMap = {}
    if typeof(raw) == "string" then
        for part in string.gmatch(raw, "[^,]+") do
            local mutation = normalizeMutation(part)
            if mutation ~= "" then foundMap[mutation] = true end
        end
    end

    local count = 0
    local found = {}
    local missing = {}
    for _, entry in ipairs(WEATHER_ORDER) do
        if foundMap[normalizeMutation(entry.mutation)] then
            count += 1
            table.insert(found, entry.mutation)
        else
            table.insert(missing, entry)
        end
    end
    return {count = count, found = found, missing = missing, raw = raw}
end

-- ============================================================
-- SICHERE AUTO-COLLECT FUNKTION
-- ============================================================
local function collectFruit(spawnObj)
    if not spawnObj then return false end
    
    local triggered = false
    pcall(function()
        local prompt = spawnObj:FindFirstChildOfClass("ProximityPrompt") or spawnObj:FindFirstChild("ProximityPrompt", true)
        if prompt then
            fireproximityprompt(prompt)
            triggered = true
            print("[SmartGrinder] 🍇 Frucht automatisch eingesammelt via ProximityPrompt!")
            return
        end

        local clickDetector = spawnObj:FindFirstChildOfClass("ClickDetector") or spawnObj:FindFirstChild("ClickDetector", true)
        if clickDetector then
            fireclickdetector(clickDetector)
            triggered = true
            print("[SmartGrinder] 🍇 Frucht automatisch eingesammelt via ClickDetector!")
            return
        end
    end)
    return triggered
end

local function getWeatherMatches(allMissingWeathers, weather)
    local matches = {}
    local weatherClean = cleanString(weather)
    if weatherClean == "" then return matches end
    for _, req in ipairs(allMissingWeathers) do
        if cleanString(req.weather) == weatherClean then table.insert(matches, req) end
    end
    return matches
end

local function displayMatches(prefix, matches)
    local fruitNumbers = {}
    local mutationNames = {}
    local seenFruits = {}
    local seenMutations = {}
    for _, match in ipairs(matches) do
        if not seenFruits[match.fruitIdx] then
            seenFruits[match.fruitIdx] = true
            table.insert(fruitNumbers, "F" .. tostring(match.fruitIdx))
        end
        if not seenMutations[match.mutation] then
            seenMutations[match.mutation] = true
            table.insert(mutationNames, match.mutation)
        end
    end
    lblTarget.Text = string.format("%s: %s → %s", prefix, table.concat(fruitNumbers, ", "), table.concat(mutationNames, ", "))
end

-- ============================================================
-- OPTIMIERTER SERVER HOP
-- ============================================================
local function triggerServerHop()
    if not autoHopEnabled or teleporting then return end
    
    if os.clock() - lastTeleportFail < TELEPORT_COOLDOWN then
        lblNeeded.Text = "⏳ Teleport-Cooldown aktiv..."
        return
    end

    teleporting = true
    hopPending = false

    print("============================================================")
    print("[SmartGrinder] 🔄 Suche idealen Server (Low Pop & Unbesucht)")
    print("[SmartGrinder] Aktuelle JobId:", game.JobId)
    print("============================================================")

    hopButton.Text = "Auto-Hop: Suche Server..."

    local success, err = pcall(function()
        local placeId = tostring(game.PlaceId)
        local cursor = nil
        local selectedServer = nil
        math.randomseed(os.time())

        for page = 1, 5 do
            local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
            if cursor then url = url .. "&cursor=" .. HttpService:UrlEncode(cursor) end

            local response = game:HttpGet(url)
            if not response or response == "" then error("Leere Server-API-Antwort") end

            local data = HttpService:JSONDecode(response)
            if type(data) ~= "table" or type(data.data) ~= "table" then error("Ungültige Server-API-Antwort") end

            local validServersInPage = {}

            for _, server in ipairs(data.data) do
                if type(server) == "table" then
                    local serverId = server.id
                    local playing = tonumber(server.playing)
                    local maxPlayers = tonumber(server.maxPlayers)

                    if serverId and serverId ~= game.JobId and not visitedServers[serverId] and playing and maxPlayers then
                        if playing < (maxPlayers - 1) and playing > 0 then
                            table.insert(validServersInPage, server)
                        end
                    end
                end
            end

            if #validServersInPage > 0 then
                selectedServer = validServersInPage[math.random(1, #validServersInPage)]
                break
            end

            cursor = data.nextPageCursor
            if not cursor then break end
            task.wait(0.2)
        end

        if not selectedServer then
            print("[SmartGrinder] ⚠️ Kein neuer, freier Server gefunden. Warte auf nächste API-Abfrage.")
            teleporting = false
            if autoHopEnabled then hopButton.Text = "Auto-Hop: AN" end
            return
        end

        print("[SmartGrinder] ✅ Server gewählt:", selectedServer.id)
        
        hopButton.Text = "Auto-Hop: Teleportiere..."
        
        visitedServers[selectedServer.id] = os.time()
        pcall(function()
            if writefile then writefile(VISITED_FILE, HttpService:JSONEncode(visitedServers)) end
        end)

        TeleportService:TeleportToPlaceInstance(game.PlaceId, selectedServer.id, LocalPlayer)
    end)

    if not success then
        teleporting = false
        lastTeleportFail = os.clock()
        warn("[SmartGrinder] ❌ Server-Hop Fehler:", err)
        if autoHopEnabled then hopButton.Text = "Auto-Hop: AN" end
    end
end

-- ============================================================
-- WETTER-SYNC THREAD
-- ============================================================
task.spawn(function()
    while screenGui.Parent do
        local success, err = pcall(function()
            local current = getActiveWeather()
            local nextWeather = getNextWeather()

            cachedCurW = current
            cachedNextW = nextWeather

            local currentValid = isValidWeather(current)
            local nextValid = isValidWeather(nextWeather)

            weatherReadError = not currentValid or not nextValid
            weatherDataReady = true
        end)

        if not success then
            weatherReadError = true
            warn("[SmartGrinder] Wetter-Sync Fehler:", err)
        end
        task.wait(WEATHER_UPDATE_INTERVAL)
    end
end)

-- ============================================================
-- HAUPTLOGIK
-- ============================================================
task.spawn(function()
    while screenGui.Parent do
        local success, err = pcall(function()

            lblWeather.Text = "Aktuell: " .. tostring(cachedCurW)
            lblNextWeather.Text = "Nächstes: " .. tostring(cachedNextW)

            if not weatherDataReady then
                hopPending = false
                resetUIState("Phase: Wetter-Sync...", "Ziel: Warte auf Wetterdaten", "Kein Hop während Sync")
                return
            end

            if weatherReadError then
                hopPending = false
                resetUIState("Phase: Wetter-Sync Fehler", "Ziel: Keine sichere Entscheidung", "Hop pausiert...")
                return
            end

            local spiritTree = getPlayerSpiritTree()
            if not spiritTree then
                hopPending = false
                resetUIState("Phase: Kein Spirit-Baum", "Ziel: Spirit-Baum nicht gefunden", "Hop pausiert...")
                return
            end

            local fruitSpawnsFolder = spiritTree:FindFirstChild("FruitSpawns")
            if not fruitSpawnsFolder then
                hopPending = false
                resetUIState("Phase: FruitSpawns fehlen", "Ziel: Warte auf Spawns", "Hop pausiert...")
                return
            end

            local fruitMap = getFruitMap(fruitSpawnsFolder)
            if not fruitMap then
                hopPending = false
                resetUIState("Phase: Spawns werden geladen", "Ziel: Warte auf Frucht 1-4", "Hop pausiert...")
                return
            end

            -- ====================================================
            -- CLEANUP: Entferne zerstörte/alte Instanzen aus Tabelle
            -- ====================================================
            for spawnObj, _ in pairs(collectedInstances) do
                if not spawnObj or not spawnObj.Parent then
                    collectedInstances[spawnObj] = nil
                end
            end

            local allMissingWeathers = {}

            for i = 1, FRUIT_COUNT do
                local spawnObj = fruitMap[i]
                local data = getMutationData(spawnObj)

                if data.count >= TARGET_COUNT then
                    fruitLabels[i].Text = string.format("Frucht %d: %d/%d | Komplett ✅", i, data.count, TARGET_COUNT)
                    fruitLabels[i].TextColor3 = Color3.fromRGB(100, 255, 100)

                    if spawnObj then
                        local triggerTime = collectedInstances[spawnObj]
                        if not triggerTime then
                            if collectFruit(spawnObj) then
                                collectedInstances[spawnObj] = os.clock() -- Timestamp speichern
                            end
                        else
                            -- Wenn das Ding nach 4 Sekunden immer noch da ist und immer noch 6/6,
                            -- hat das Spiel es nicht akzeptiert -> Retry erlauben!
                            if (os.clock() - triggerTime > 4.0) and spawnObj.Parent then
                                collectedInstances[spawnObj] = nil
                            end
                        end
                    end
                else
                    local missingNames = {}
                    for _, entry in ipairs(data.missing) do
                        table.insert(missingNames, entry.mutation)
                        table.insert(allMissingWeathers, {
                            fruitIdx = i,
                            weather = entry.weather,
                            mutation = entry.mutation
                        })
                    end
                    fruitLabels[i].Text = string.format("Frucht %d: %d/%d | Fehlt: %s", i, data.count, TARGET_COUNT, table.concat(missingNames, ", "))
                    fruitLabels[i].TextColor3 = Color3.fromRGB(255, 170, 80)
                end
            end

            if #allMissingWeathers == 0 then
                hopPending = false
                lblPhase.Text = "Status: Alle Früchte komplett/geerntet"
                lblTarget.Text = "Ziel: Warte auf neue Fruit-Spawns"
                lblNeeded.Text = "🟢 Kein Hop erforderlich."
                lblNeeded.TextColor3 = Color3.fromRGB(100, 255, 100)
                return
            end

            local currentMatches = getWeatherMatches(allMissingWeathers, cachedCurW)
            local nextMatches = getWeatherMatches(allMissingWeathers, cachedNextW)

            if #currentMatches > 0 then
                hopPending = false
                displayMatches("Jetzt", currentMatches)
                lblPhase.Text = string.format("Status: %d aktuelle Treffer", #currentMatches)
                lblNeeded.Text = "🟢 Wetter passt! Server behalten."
                lblNeeded.TextColor3 = Color3.fromRGB(80, 255, 120)

            elseif #nextMatches > 0 then
                hopPending = false
                displayMatches("Bald", nextMatches)
                lblPhase.Text = string.format("Status: %d Treffer im nächsten Wetter", #nextMatches)
                lblNeeded.Text = "🟡 Nächstes Wetter passt! Server behalten."
                lblNeeded.TextColor3 = Color3.fromRGB(255, 220, 80)

            else
                if #allMissingWeathers > 0 then
                    local firstReq = allMissingWeathers[1]
                    lblTarget.Text = string.format("Offen: F%d → %s (%s)", firstReq.fruitIdx, firstReq.weather, firstReq.mutation)
                else
                    lblTarget.Text = "Ziel: Keine offenen Mutationen"
                end

                lblPhase.Text = "Status: Kein Treffer für aktuelle/nächste Runde"
                lblNeeded.Text = "🔴 Kein benötigtes Wetter → Hop-Kandidat"
                lblNeeded.TextColor3 = Color3.fromRGB(220, 100, 100)

                if autoHopEnabled then
                    if not hopPending then
                        hopPending = true
                        hopPendingSince = os.clock()
                        lblPhase.Text = "Status: Hop wird bestätigt..."
                    else
                        local elapsed = os.clock() - hopPendingSince
                        if elapsed >= HOP_CONFIRM_DELAY then
                            
                            local verifyTree = getPlayerSpiritTree()
                            local verifyFolder = verifyTree and verifyTree:FindFirstChild("FruitSpawns")
                            local verifyMap = verifyFolder and getFruitMap(verifyFolder)
                            
                            local verifyMissingWeathers = {}

                            if verifyMap then
                                for i = 1, FRUIT_COUNT do
                                    local vData = getMutationData(verifyMap[i])
                                    if vData.count < TARGET_COUNT then
                                        for _, entry in ipairs(vData.missing) do
                                            table.insert(verifyMissingWeathers, {
                                                fruitIdx = i,
                                                weather = entry.weather,
                                                mutation = entry.mutation
                                            })
                                        end
                                    end
                                end
                            else
                                verifyMissingWeathers = allMissingWeathers
                            end

                            local verifyCurrent = getActiveWeather()
                            local verifyNext = getNextWeather()

                            if #verifyMissingWeathers == 0 then
                                hopPending = false
                                lblNeeded.Text = "🟢 Alle Früchte inzwischen komplett/geerntet!"
                            elseif not isValidWeather(verifyCurrent) or not isValidWeather(verifyNext) then
                                hopPending = false
                                lblNeeded.Text = "🟡 Wetterprüfung unsicher → Hop abgebrochen"
                            else
                                local verifyCurrentMatches = getWeatherMatches(verifyMissingWeathers, verifyCurrent)
                                local verifyNextMatches = getWeatherMatches(verifyMissingWeathers, verifyNext)

                                if #verifyCurrentMatches > 0 or #verifyNextMatches > 0 then
                                    hopPending = false
                                    lblNeeded.Text = "🟢 Mutationen/Wetter inzwischen relevant → Server behalten"
                                else
                                    triggerServerHop()
                                end
                            end
                        end
                    end
                else
                    hopPending = false
                end
            end
        end)

        if not success then
            warn("[SmartGrinder] Hauptschleife Fehler:", err)
        end
        task.wait(FRUIT_UPDATE_INTERVAL)
    end
end)
