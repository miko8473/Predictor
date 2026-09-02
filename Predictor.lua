-- ===================================================
-- V14.7: SPIRIT FRUIT MASTER - CYBER COMPACT EDITION
-- ===================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

print("[V14.7] Gestartet. Initiale JobId:", game.JobId)

-- Feste Reihenfolge der Wetter- und Mutationszuordnungen
local WEATHER_ORDER = {
    {weather = "Misty",         mutation = "Dewy"},
    {weather = "Sandstorm",     mutation = "Dusty"},
    {weather = "Blizzard",      mutation = "Frosted"},
    {weather = "Acid-Rain",     mutation = "Radioactive"},
    {weather = "Rainbow",       mutation = "Golden"},
    {weather = "Meteor Shower", mutation = "Cosmic"}
}

-- Globale Steuerung & Teleport-Lock
local autoHopEnabled = false
local teleporting = false

-- Altes GUI aufräumen, falls vorhanden
local container = (pcall(function() return CoreGui end) and CoreGui) or LocalPlayer:WaitForChild("PlayerGui")
if container:FindFirstChild("SpiritFruitMonitorGUI") then
    container.SpiritFruitMonitorGUI:Destroy()
end

-- GUI Erstellen (Ultra-Kompakt & Cyber-Style)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpiritFruitMonitorGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = container

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 320)
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

-- Korrektur, damit die unteren Ecken des Headers nicht abgerundet sind
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
titleLabel.Text = "⚡ SPIRIT FRUIT MASTER <font color='#8888aa'>V14.7</font>"
titleLabel.RichText = true
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

-- Container für Inhalt (mit Padding)
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

-- Kleiner Trenner
local div1 = Instance.new("Frame")
div1.Size = UDim2.new(1, 0, 0, 1)
div1.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
div1.BorderSizePixel = 0
div1.LayoutOrder = 3
div1.Parent = contentContainer

-- Kompakte Frucht-Zeilen
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

local lblTarget = createRow("LblTarget", 9, 20, 11)
lblTarget.Font = Enum.Font.GothamBold
lblTarget.TextColor3 = Color3.fromRGB(255, 190, 80)

local lblNeeded = createRow("LblNeeded", 10, 20, 11)
lblNeeded.Font = Enum.Font.GothamBold
lblNeeded.TextColor3 = Color3.fromRGB(80, 255, 120)

local lblProgress = createRow("LblProgress", 11, 20, 11)
lblProgress.Font = Enum.Font.GothamBold
lblProgress.TextColor3 = Color3.fromRGB(100, 200, 255)

local lblMissingWeathers = createRow("LblMissingWeathers", 12, 18, 10)
lblMissingWeathers.TextColor3 = Color3.fromRGB(200, 100, 100)

-- Ultra-Sleek Auto-Hop Button
local hopButton = Instance.new("TextButton")
hopButton.Size = UDim2.new(1, 0, 0, 30)
hopButton.LayoutOrder = 13
hopButton.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
hopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hopButton.TextSize = 12
hopButton.Font = Enum.Font.GothamBold
hopButton.Text = "Auto-Hop: AUS"
hopButton.Parent = contentContainer

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = hopButton

hopButton.MouseButton1Click:Connect(function()
    autoHopEnabled = not autoHopEnabled

    if autoHopEnabled then
        teleporting = false
        hopButton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
        hopButton.Text = "Auto-Hop: AN (Bereit)"
    else
        teleporting = false
        hopButton.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
        hopButton.Text = "Auto-Hop: AUS"
    end
end)

-- Hilfsfunktion zum Zurücksetzen
local function resetUIState(targetText, neededText, progressText, missingText)
    lblTarget.Text = targetText
    lblNeeded.Text = neededText
    lblProgress.Text = progressText or "Fortschritt: --/24"
    lblMissingWeathers.Text = missingText or "Fehlend: -"
    lblTarget.TextColor3 = Color3.fromRGB(180, 180, 180)
    lblNeeded.TextColor3 = Color3.fromRGB(180, 180, 180)
    for i = 1, 4 do
        fruitLabels[i].Text = string.format("Frucht %d: Warten...", i)
        fruitLabels[i].TextColor3 = Color3.fromRGB(120, 120, 140)
    end
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
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    if packages then
        local indexFolder = packages:FindFirstChild("_Index")
        if indexFolder then
            for _, pkg in ipairs(indexFolder:GetChildren()) do
                if pkg.Name:lower():sub(1, 9) == "sleitnick" then
                    local knit = pkg:FindFirstChild("knit") or pkg:FindFirstChild("Knit")
                    if knit then
                        local services = knit:FindFirstChild("Services")
                        if services then
                            local weatherService = services:FindFirstChild("WeatherService")
                            if weatherService then
                                local rfFolder = weatherService:FindFirstChild("RF") or weatherService:FindFirstChild("Remotes")
                                local rf = (rfFolder and rfFolder:FindFirstChild("GetNextWeather")) or weatherService:FindFirstChild("GetNextWeather")
                                if rf and rf:IsA("RemoteFunction") then
                                    local success, res = pcall(function()
                                        return rf:InvokeServer()
                                    end)
                                    if success and type(res) == "table" then
                                        return res.key or "Unknown"
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
        if desc.Name == "GetNextWeather" and desc:IsA("RemoteFunction") then
            local success, res = pcall(function()
                return desc:InvokeServer()
            end)
            if success and type(res) == "table" then
                return res.key or "Unknown"
            end
        end
    end
    return "Unknown"
end

-- Server-Hop mit JobId Debug
local function triggerServerHop()
    if not autoHopEnabled then return end
    if teleporting then return end

    teleporting = true
    print("[V14.7] 🔄 Starte Serverhop! Vorherige JobId:", game.JobId)
    hopButton.Text = "Auto-Hop: Wechsle..."

    local success, err = pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)

    if not success then
        warn("[V14.7] Teleport-Fehler:", err)
        teleporting = false
        hopButton.Text = "Auto-Hop: AN (Retry...)"
    end
end

-- Caches
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

-- 2. Haupt-Loop für Analyse und UI-Update
task.spawn(function()
    while screenGui.Parent do
        local ok, err = pcall(function()
            lblWeather.Text = "Aktuell: " .. cachedCurW
            lblNextWeather.Text = "Nächstes: " .. cachedNextW

            local playerPlots = Workspace:FindFirstChild("BigField") and Workspace.BigField:FindFirstChild("PlayerPlots")
            local myPlot = nil
            if playerPlots then
                for _, plot in ipairs(playerPlots:GetChildren()) do
                    if plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                        myPlot = plot
                        break
                    end
                end
            end

            if not myPlot then
                resetUIState("Ziel: Kein Plot", "Warte auf Plot...")
                return
            end

            local spiritTree = nil
            for _, child in ipairs(myPlot:GetChildren()) do
                if child:GetAttribute("SeedType") == "Spirit" then
                    spiritTree = child
                    break
                end
            end

            if not spiritTree then
                resetUIState("Ziel: Kein Spirit-Baum", "Baum pflanzen...")
                return
            end

            local fruitSpawnsFolder = spiritTree:FindFirstChild("FruitSpawns")
            if not fruitSpawnsFolder then
                resetUIState("Ziel: Spawns fehlen", "Strukturfehler")
                return
            end

            -- Index-Check 1..4
            local fruitMap = {}
            local uniqueCount = 0
            for _, obj in ipairs(fruitSpawnsFolder:GetChildren()) do
                local idx = obj:GetAttribute("SpawnIndex")
                if typeof(idx) == "number" and idx >= 1 and idx <= 4 and idx % 1 == 0 then
                    if not fruitMap[idx] then
                        fruitMap[idx] = obj
                        uniqueCount = uniqueCount + 1
                    end
                end
            end

            if uniqueCount ~= 4 then
                resetUIState("Ziel: Unvollständige Spawns", "Warte auf 1..4...")
                return
            end

            local validSpawns = {
                {obj = fruitMap[1], index = 1},
                {obj = fruitMap[2], index = 2},
                {obj = fruitMap[3], index = 3},
                {obj = fruitMap[4], index = 4}
            }

            local totalMissingCount = 0
            local allCompleted = true
            local globalNeededWeathers = {}
            local fruitsNeedingCurrent = {}
            local fruitsNeedingNext = {}

            for i, data in ipairs(validSpawns) do
                local spawnObj = data.obj
                local mutationsAttr = spawnObj:GetAttribute("FruitMutations") or ""
                
                local foundMutations = {}
                local uniqueMutationsMap = {}
                for mut in mutationsAttr:gmatch("[^,%s]+") do
                    if not uniqueMutationsMap[mut:lower()] then
                        uniqueMutationsMap[mut:lower()] = true
                        table.insert(foundMutations, mut)
                    end
                end

                local missingWeathersForThisFruit = {}
                for _, entry in ipairs(WEATHER_ORDER) do
                    local hasMutation = false
                    local targetMutLower = entry.mutation:lower()
                    for _, m in ipairs(foundMutations) do
                        if m:lower() == targetMutLower then
                            hasMutation = true
                            break
                        end
                    end

                    if not hasMutation then
                        table.insert(missingWeathersForThisFruit, entry.weather)
                        totalMissingCount = totalMissingCount + 1
                        globalNeededWeathers[entry.weather] = true

                        if entry.weather:lower() == cachedCurW:lower() then
                            table.insert(fruitsNeedingCurrent, string.format("F%d (%s)", i, entry.mutation))
                        end
                        if entry.weather:lower() == cachedNextW:lower() then
                            table.insert(fruitsNeedingNext, string.format("F%d (%s)", i, entry.mutation))
                        end
                    end
                end

                if #missingWeathersForThisFruit == 0 then
                    fruitLabels[i].Text = string.format("Frucht %d: Komplett (6/6)", i)
                    fruitLabels[i].TextColor3 = Color3.fromRGB(100, 255, 100)
                else
                    allCompleted = false
                    fruitLabels[i].Text = string.format("Frucht %d: Fehlen %d Mutationen", i, #missingWeathersForThisFruit)
                    fruitLabels[i].TextColor3 = Color3.fromRGB(255, 170, 80)
                end
            end

            local totalAcquired = 24 - totalMissingCount
            lblProgress.Text = string.format("Fortschritt: %d / 24 Mutationen", totalAcquired)

            if allCompleted then
                lblTarget.Text = "Ziel: Alle Früchte maxed! 🎉"
                lblNeeded.Text = "Status: Fertig!"
                lblTarget.TextColor3 = Color3.fromRGB(100, 255, 100)
                lblNeeded.TextColor3 = Color3.fromRGB(100, 255, 100)
                lblMissingWeathers.Text = "Fehlend: Keine"
            else
                local missingListFormatted = {}
                for _, entry in ipairs(WEATHER_ORDER) do
                    if globalNeededWeathers[entry.weather] then
                        table.insert(missingListFormatted, entry.weather)
                    end
                end
                lblMissingWeathers.Text = "Fehlt: " .. table.concat(missingListFormatted, ", ")

                if #fruitsNeedingCurrent > 0 then
                    lblTarget.Text = "Ziel: Aktives Wetter nutzen!"
                    lblNeeded.Text = "Aktion: " .. table.concat(fruitsNeedingCurrent, ", ")
                    lblNeeded.TextColor3 = Color3.fromRGB(80, 255, 120)
                elseif #fruitsNeedingNext > 0 then
                    lblTarget.Text = "Ziel: Nächstes Wetter vorbereiten!"
                    lblNeeded.Text = "Kommt: " .. table.concat(fruitsNeedingNext, ", ")
                    lblNeeded.TextColor3 = Color3.fromRGB(255, 220, 80)
                else
                    lblTarget.Text = "Ziel: Kein Wetter passend"
                    lblNeeded.Text = "Status: Server unbrauchbar -> Hoppe"
                    lblNeeded.TextColor3 = Color3.fromRGB(220, 100, 100)

                    if autoHopEnabled then
                        triggerServerHop()
                    end
                end
            end

        end)

        if not ok then
            warn("[V14.7] Fehler:", err)
        end
        
        task.wait(1.5)
    end
end)

print("[V14.7] Spirit Fruit Master Cyber Compact erfolgreich geladen!")
