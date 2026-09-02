-- ===================================================
-- V29: SPIRIT FRUIT MASTER - FLEXIBLE WEATHER MATCHING & AUTO-COLLECT
-- ===================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

print("[V29] Gestartet. Initiale JobId:", game.JobId)

-- Die 6 echten Wetter-Mutationen
local WEATHER_ORDER = {
    {weather = "Misty",         mutation = "Dewy"},
    {weather = "Sandstorm",     mutation = "Dusty"},
    {weather = "Blizzard",      mutation = "Frosted"},
    {weather = "Acid-Rain",     mutation = "Radioactive"},
    {weather = "Rainbow",       mutation = "Golden"},
    {weather = "Meteor Shower", mutation = "Cosmic"}
}

local REQUIRED_WEATHER_COUNT = #WEATHER_ORDER -- 6

-- Globale Steuerung & Guards
local autoHopEnabled = true
local teleporting = false
local setCompleted = false
local collectedTriggered = false

-- Altes GUI aufräumen, falls vorhanden
local container = (pcall(function() return CoreGui end) and CoreGui) or LocalPlayer:WaitForChild("PlayerGui")
if container:FindFirstChild("SpiritFruitMonitorGUI") then
    container.SpiritFruitMonitorGUI:Destroy()
end

-- GUI Erstellen
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpiritFruitMonitorGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = container

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 330)
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

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 6)
headerFix.Position = UDim2.new(0, 0, 1, -6)
headerFix.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -16, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ SPIRIT FRUIT MASTER <font color='#8888aa'>V29 (Fix Match)</font>"
titleLabel.RichText = true
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

-- Container für Inhalt
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -20, 1, -44)
contentContainer.Position = UDim2.new(0, 10, 0, 40)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 4)
contentLayout.Parent = contentContainer

local function createRow(name, order, sizeY, textSize)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.Size = UDim2.new(1, 0, 0, sizeY or 20)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    lbl.TextSize = textSize or 12
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = contentContainer
    return lbl
end

local lblWeather = createRow("LblWeather", 1, 20, 12)
local lblNextWeather = createRow("LblNextWeather", 2, 20, 12)

local div1 = Instance.new("Frame")
div1.Size = UDim2.new(1, 0, 0, 1)
div1.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
div1.BorderSizePixel = 0
div1.LayoutOrder = 3
div1.Parent = contentContainer

local fruitLabels = {
    createRow("Fruit1", 4, 18, 11),
    createRow("Fruit2", 5, 18, 11),
    createRow("Fruit3", 6, 18, 11),
    createRow("Fruit4", 7, 18, 11)
}

local div2 = Instance.new("Frame")
div2.Size = UDim2.new(1, 0, 0, 1)
div2.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
div2.BorderSizePixel = 0
div2.LayoutOrder = 8
div2.Parent = contentContainer

local lblPhase = createRow("LblPhase", 9, 20, 11)
lblPhase.Font = Enum.Font.GothamBold
lblPhase.TextColor3 = Color3.fromRGB(100, 200, 255)

local lblTarget = createRow("LblTarget", 10, 20, 11)
lblTarget.Font = Enum.Font.GothamBold
lblTarget.TextColor3 = Color3.fromRGB(255, 190, 80)

local lblNeeded = createRow("LblNeeded", 11, 20, 11)
lblNeeded.Font = Enum.Font.GothamBold
lblNeeded.TextColor3 = Color3.fromRGB(80, 255, 120)

local lblActionInfo = createRow("LblActionInfo", 12, 18, 10)
lblActionInfo.TextColor3 = Color3.fromRGB(200, 100, 100)

-- Auto-Hop Button
local hopButton = Instance.new("TextButton")
hopButton.Size = UDim2.new(1, 0, 0, 30)
hopButton.LayoutOrder = 13
hopButton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
hopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hopButton.TextSize = 12
hopButton.Font = Enum.Font.GothamBold
hopButton.Text = "Auto-Hop: AN (Flexible Match)"
hopButton.Parent = contentContainer

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = hopButton

hopButton.MouseButton1Click:Connect(function()
    if setCompleted then return end
    autoHopEnabled = not autoHopEnabled

    if autoHopEnabled then
        teleporting = false
        hopButton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
        hopButton.Text = "Auto-Hop: AN (Flexible Match)"
    else
        teleporting = false
        hopButton.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
        hopButton.Text = "Auto-Hop: AUS (Manuell gestoppt)"
    end
end)

local function resetUIState(phaseText, targetText, neededText, actionText)
    lblPhase.Text = phaseText
    lblTarget.Text = targetText
    lblNeeded.Text = neededText
    lblActionInfo.Text = actionText or "Status: -"
    for i = 1, 4 do
        fruitLabels[i].Text = string.format("Frucht %d: Warten...", i)
        fruitLabels[i].TextColor3 = Color3.fromRGB(120, 120, 140)
    end
end

-- Hilfsfunktion: Bereinigt Text für perfekten Vergleich (entfernt Leerzeichen & Großschreibung)
local function cleanString(str)
    if not str then return "" end
    return tostring(str):gsub("%s+", ""):lower()
end

-- Wetter-Erkennung (Aktuell)
local function getActiveWeather()
    local currentWeatherObj = ReplicatedStorage:FindFirstChild("CurrentWeather") 
        or ReplicatedStorage:FindFirstChild("CurrentWeather", true)
    if currentWeatherObj then
        local val = nil
        if currentWeatherObj:IsA("ValueBase") then
            val = currentWeatherObj.Value
        elseif currentWeatherObj:IsA("TextLabel") or currentWeatherObj:IsA("TextBox") then
            val = currentWeatherObj.Text
        end
        if not val or val == "" then
            val = currentWeatherObj:GetAttribute("Value") or currentWeatherObj:GetAttribute("Weather") or currentWeatherObj:GetAttribute("CurrentWeather")
        end
        if val and tostring(val) ~= "" then
            return tostring(val)
        end
    end
    local attrWeather = ReplicatedStorage:GetAttribute("CurrentWeather")
    if attrWeather then
        return tostring(attrWeather)
    end
    return "Unknown"
end

-- Wetter-Erkennung (Nächstes)
local function getNextWeather()
    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "GetNextWeather" and desc:IsA("RemoteFunction") then
            local success, res = pcall(function()
                return desc:InvokeServer()
            end)
            if success and type(res) == "table" then
                return res.key or res.Name or "Unknown"
            elseif success and type(res) == "string" then
                return res
            end
        end
    end
    return "Unknown"
end

-- Server-Hop
local function triggerServerHop()
    if not autoHopEnabled or setCompleted then return end
    if teleporting then return end

    teleporting = true
    print("[V29] 🔄 Starte Serverhop! Vorherige JobId:", game.JobId)
    hopButton.Text = "Auto-Hop: Wechsle Server..."

    local success, err = pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)

    if not success then
        warn("[V29] Teleport-Fehler:", err)
        teleporting = false
        hopButton.Text = "Auto-Hop: AN (Retry...)"
    end
end

-- Hilfsfunktion: Findet den Spirit-Baum des Spielers
local function getPlayerSpiritTree()
    local playerPlots = Workspace:FindFirstChild("BigField") and Workspace.BigField:FindFirstChild("PlayerPlots")
    if not playerPlots then return nil end

    local myPlot = nil
    for _, plot in ipairs(playerPlots:GetChildren()) do
        if plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            myPlot = plot
            break
        end
    end
    if not myPlot then return nil end

    for _, child in ipairs(myPlot:GetChildren()) do
        if child:GetAttribute("SeedType") == "Spirit" then
            return child
        end
    end
    return nil
end

-- Automatisch einsammeln per ClickDetector oder ProximityPrompt
local function triggerCollection(spawnObj)
    for _, desc in ipairs(spawnObj:GetDescendants()) do
        if desc:IsA("ClickDetector") then
            pcall(function()
                fireclickdetector(desc)
                print("[V29] 🖱️ ClickDetector ausgelöst für:", spawnObj.Name)
            end)
        elseif desc:IsA("ProximityPrompt") then
            pcall(function()
                fireproximityprompt(desc)
                print("[V29] 🧺 ProximityPrompt ausgelöst für:", spawnObj.Name)
            end)
        end
    end
end

local cachedCurW = "Laden..."
local cachedNextW = "Laden..."

-- 1. Hintergrund-Task für Wetter
task.spawn(function()
    while screenGui.Parent do
        cachedCurW = getActiveWeather()
        cachedNextW = getNextWeather()
        task.wait(4)
    end
end)

-- 2. Haupt-Loop mit robuster Match-Logik & Phase 2
task.spawn(function()
    while screenGui.Parent do
        local ok, err = pcall(function()
            lblWeather.Text = "Aktuell: " .. cachedCurW
            lblNextWeather.Text = "Nächstes: " .. cachedNextW

            local spiritTree = getPlayerSpiritTree()
            if not spiritTree then
                resetUIState("Phase: Fehler", "Ziel: Kein Spirit-Baum", "Baum pflanzen...")
                return
            end

            local fruitSpawnsFolder = spiritTree:FindFirstChild("FruitSpawns")
            if not fruitSpawnsFolder then
                resetUIState("Phase: Fehler", "Ziel: Spawns fehlen", "Strukturfehler")
                return
            end

            local fruitMap = {}
            local uniqueCount = 0
            local duplicateIndex = nil

            for _, obj in ipairs(fruitSpawnsFolder:GetChildren()) do
                local idx = obj:GetAttribute("SpawnIndex")
                if typeof(idx) == "number" and idx % 1 == 0 and idx >= 1 and idx <= 4 then
                    if fruitMap[idx] then
                        duplicateIndex = idx
                    else
                        fruitMap[idx] = obj
                        uniqueCount = uniqueCount + 1
                    end
                end
            end

            if uniqueCount ~= 4 or duplicateIndex ~= nil then
                local reason = duplicateIndex and string.format("Doppelter SpawnIndex %d", duplicateIndex) or "Nicht exakt 1..4"
                resetUIState("Phase: Fehler", "Ziel: Ungültige Spawns", reason .. " – warte...")
                return
            end

            local validSpawns = {
                {obj = fruitMap[1], index = 1},
                {obj = fruitMap[2], index = 2},
                {obj = fruitMap[3], index = 3},
                {obj = fruitMap[4], index = 4}
            }

            -- Analysiere Wetter-Status für jede Frucht einzeln
            local fruitWeatherCounts = {}
            local fruitMissingWeathers = {}
            local allWeatherComplete = true

            for i = 1, 4 do
                local spawnObj = fruitMap[i]
                local mutationsAttr = spawnObj:GetAttribute("FruitMutations") or ""
                local foundMap = {}
                for mut in mutationsAttr:gmatch("[^,%s]+") do
                    foundMap[mut:lower()] = true
                end

                local count = 0
                local missingList = {}
                for _, entry in ipairs(WEATHER_ORDER) do
                    if foundMap[entry.mutation:lower()] then
                        count = count + 1
                    else
                        table.insert(missingList, entry)
                    end
                end

                fruitWeatherCounts[i] = count
                fruitMissingWeathers[i] = missingList

                if count < REQUIRED_WEATHER_COUNT then
                    allWeatherComplete = false
                end

                if count >= REQUIRED_WEATHER_COUNT then
                    fruitLabels[i].Text = string.format("Frucht %d: 6/6 Wetter ✅", i)
                    fruitLabels[i].TextColor3 = Color3.fromRGB(100, 255, 100)
                else
                    fruitLabels[i].Text = string.format("Frucht %d: Fehlen %d Wetter", i, #missingList)
                    fruitLabels[i].TextColor3 = Color3.fromRGB(255, 170, 80)
                end
            end

            -- ==========================================
            -- PHASE 1: Sequenzielle Wetter-Suche (F1 -> F2 -> F3 -> F4)
            -- ==========================================
            if not allWeatherComplete then
                lblPhase.Text = "Phase 1: Wetter-Sammlung (Frucht-by-Frucht)"
                
                local activeFruitIdx = 1
                for i = 1, 4 do
                    if fruitWeatherCounts[i] < REQUIRED_WEATHER_COUNT then
                        activeFruitIdx = i
                        break
                    end
                end

                local neededWeathers = fruitMissingWeathers[activeFruitIdx]
                local nextNeededEntry = neededWeathers[1]

                lblTarget.Text = string.format("Ziel: Frucht %d braucht '%s' (%s)", activeFruitIdx, nextNeededEntry.weather, nextNeededEntry.mutation)
                lblActionInfo.Text = string.format("Fortschritt F%d: %d/6 Wetter", activeFruitIdx, fruitWeatherCounts[activeFruitIdx])

                local curClean = cleanString(cachedCurW)
                local nextClean = cleanString(cachedNextW)
                local reqClean = cleanString(nextNeededEntry.weather)

                if curClean == reqClean then
                    lblNeeded.Text = "Status: Aktives Wetter passt! Warten auf Mutation..."
                    lblNeeded.TextColor3 = Color3.fromRGB(80, 255, 120)
                elseif nextClean == reqClean then
                    lblNeeded.Text = "Status: Nächstes Wetter passt! Bereit machen..."
                    lblNeeded.TextColor3 = Color3.fromRGB(255, 220, 80)
                else
                    lblNeeded.Text = "Status: Wetter unpassend -> Hoppe"
                    lblNeeded.TextColor3 = Color3.fromRGB(220, 100, 100)

                    if autoHopEnabled then
                        triggerServerHop()
                    end
                end

            -- ==========================================
            -- PHASE 2: Warten auf Huge + Infested (Auto-Hop AUS)
            -- ==========================================
            else
                autoHopEnabled = false
                hopButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
                hopButton.Text = "Auto-Hop: GESPERRT (Warte auf Huge/Infested)"

                lblPhase.Text = "Phase 2: Warten auf Huge + Infested"
                
                local allHugeInfested = true
                for i = 1, 4 do
                    local spawnObj = fruitMap[i]
                    local mutationsAttr = spawnObj:GetAttribute("FruitMutations") or ""
                    local foundMap = {}
                    for mut in mutationsAttr:gmatch("[^,%s]+") do
                        foundMap[mut:lower()] = true
                    end
                    if not (foundMap["huge"] and foundMap["infested"]) then
                        allHugeInfested = false
                        break
                    end
                end

                if allHugeInfested then
                    setCompleted = true
                    lblTarget.Text = "Ziel: Alles komplett (6 Wetter + Huge + Infested)! 🎉"
                    lblNeeded.Text = "Status: Sammle alle 4 Früchte ein..."
                    lblTarget.TextColor3 = Color3.fromRGB(100, 255, 100)
                    lblNeeded.TextColor3 = Color3.fromRGB(100, 255, 100)
                    lblActionInfo.Text = "Erfolgreich beendet."
                    
                    hopButton.Text = "Auto-Hop: GESTOPPT (Fertig eingesammelt)"

                    if not collectedTriggered then
                        collectedTriggered = true
                        task.spawn(function()
                            for _, data in ipairs(validSpawns) do
                                triggerCollection(data.obj)
                                task.wait(0.2)
                            end
                        end)
                    end
                else
                    lblTarget.Text = "Ziel: Alle 4 Früchte haben 6 Wetter ✅"
                    lblNeeded.Text = "Status: Warte, bis Huge + Infested da sind..."
                    lblTarget.TextColor3 = Color3.fromRGB(100, 200, 255)
                    lblNeeded.TextColor3 = Color3.fromRGB(255, 190, 80)
                    lblActionInfo.Text = "Kein Hop mehr. Warten auf Standard-Mutationen."
                end
            end

        end)

        if not ok then
            warn("[V29] Fehler:", err)
        end
        
        task.wait(1.5)
    end
end)

print("[V29] Spirit Fruit Master (Flexible String Match) erfolgreich geladen!")
