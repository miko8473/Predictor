-- ===================================================
-- SPIRIT FRUIT COMPLETE GRINDER (Mit Auto-Hop & 8/8)
-- ===================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

print("[Grinder] Vollversion mit Auto-Hop gestartet. JobId:", game.JobId)

-- Die 8 Ziel-Mutationen mit zugehörigem Wetter (Shocked ausgeschlossen)
local TARGET_MUTATIONS = {
    {name = "Dewy",        weather = "Misty"},
    {name = "Dusty",       weather = "Sandstorm"},
    {name = "Frosted",     weather = "Blizzard"},
    {name = "Radioactive", weather = "Acid-Rain"},
    {name = "Golden",      weather = "Rainbow"},
    {name = "Cosmic",      weather = "Meteor Shower"},
    {name = "Infested",    weather = nil},
    {name = "Huge",        weather = nil}
}

local autoHopEnabled = true
local teleporting = false
local grindCompleted = false

-- Altes GUI auf PlayerGui aufräumen
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("SpiritGrinderGUI") then
    playerGui.SpiritGrinderGUI:Destroy()
end

-- GUI Erstellen
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpiritGrinderGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 360, 0, 360)
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

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -16, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🌱 MUTATION GRINDER <font color='#8888aa'>(Mit Auto-Hop)</font>"
titleLabel.RichText = true
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = header

-- Inhalt Container
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, -20, 1, -44)
contentContainer.Position = UDim2.new(0, 10, 0, 40)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 4)
contentLayout.Parent = contentContainer

local function createRow(name, sizeY, textSize)
    local lbl = Instance.new("TextLabel")
    lbl.Name = name
    lbl.Size = UDim2.new(1, 0, 0, sizeY or 22)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(210, 210, 220)
    lbl.TextSize = textSize || 11
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = contentContainer
    return lbl
end

local lblWeather = createRow("LblWeather", 20, 12)

local div1 = Instance.new("Frame")
div1.Size = UDim2.new(1, 0, 0, 1)
div1.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
div1.BorderSizePixel = 0
div1.Parent = contentContainer

local fruitLabels = {
    createRow("Fruit1", 22, 11),
    createRow("Fruit2", 22, 11),
    createRow("Fruit3", 22, 11),
    createRow("Fruit4", 22, 11)
}

local div2 = Instance.new("Frame")
div2.Size = UDim2.new(1, 0, 0, 1)
div2.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
div2.BorderSizePixel = 0
div2.Parent = contentContainer

local lblPhase = createRow("LblPhase", 20, 11)
lblPhase.Font = Enum.Font.GothamBold
lblPhase.TextColor3 = Color3.fromRGB(100, 200, 255)

local lblTarget = createRow("LblTarget", 20, 11)
lblTarget.Font = Enum.Font.GothamBold
lblTarget.TextColor3 = Color3.fromRGB(255, 190, 80)

local lblNeeded = createRow("LblNeeded", 20, 11)
lblNeeded.Font = Enum.Font.GothamBold
lblNeeded.TextColor3 = Color3.fromRGB(80, 255, 120)

-- Auto-Hop Button
local hopButton = Instance.new("TextButton")
hopButton.Size = UDim2.new(1, 0, 0, 28)
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
    if grindCompleted then return end
    autoHopEnabled = not autoHopEnabled
    if autoHopEnabled then
        teleporting = false
        hopButton.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
        hopButton.Text = "Auto-Hop: AN"
    else
        teleporting = false
        hopButton.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
        hopButton.Text = "Auto-Hop: AUS (Manuell)"
    end
end)

local function resetUIState(phaseText, targetText, neededText)
    lblPhase.Text = phaseText
    lblTarget.Text = targetText
    lblNeeded.Text = neededText
    for i = 1, 4 do
        fruitLabels[i].Text = string.format("Frucht %d: Warten...", i)
        fruitLabels[i].TextColor3 = Color3.fromRGB(120, 120, 140)
    end
end

local function cleanString(str)
    if not str then return "" end
    return tostring(str):gsub("%s+", ""):lower()
end

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

local function triggerServerHop()
    if not autoHopEnabled or grindCompleted then return end
    if teleporting then return end

    teleporting = true
    print("[Grinder] 🔄 Starte Serverhop! JobId:", game.JobId)
    hopButton.Text = "Auto-Hop: Wechsle Server..."

    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

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

local cachedCurW = "Laden..."

task.spawn(function()
    while screenGui.Parent do
        cachedCurW = getActiveWeather()
        task.wait(3)
    end
end)

task.spawn(function()
    while screenGui.Parent do
        local ok, err = pcall(function()
            lblWeather.Text = "Aktuelles Wetter: " .. cachedCurW

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
            for _, obj in ipairs(fruitSpawnsFolder:GetChildren()) do
                local idx = obj:GetAttribute("SpawnIndex")
                if typeof(idx) == "number" and idx >= 1 and idx <= 4 and idx % 1 == 0 then
                    fruitMap[idx] = obj
                end
            end

            local allComplete = true
            local fruitDataList = {}

            for i = 1, 4 do
                local spawnObj = fruitMap[i]
                if not spawnObj then
                    allComplete = false
                    fruitDataList[i] = {count = 0, missingWeather = {}}
                    fruitLabels[i].Text = string.format("Frucht %d: Nicht gefunden", i)
                    fruitLabels[i].TextColor3 = Color3.fromRGB(120, 120, 140)
                else
                    local mutationsAttr = spawnObj:GetAttribute("FruitMutations") or ""
                    local foundMap = {}
                    for mut in mutationsAttr:gmatch("[^,%s]+") do
                        foundMap[mut:lower()] = true
                    end

                    local count = 0
                    local missingWeatherList = {}
                    local missingNames = {}

                    for _, target in ipairs(TARGET_MUTATIONS) do
                        if foundMap[target.name:lower()] then
                            count = count + 1
                        else
                            table.insert(missingNames, target.name)
                            if target.weather then
                                table.insert(missingWeatherList, target)
                            end
                        end
                    end

                    if count < #TARGET_MUTATIONS then
                        allComplete = false
                    end

                    fruitDataList[i] = {
                        count = count,
                        missingWeather = missingWeatherList,
                        missingNames = missingNames
                    }

                    if count >= #TARGET_MUTATIONS then
                        fruitLabels[i].Text = string.format("Frucht %d: 8/8 Komplett ✅", i)
                        fruitLabels[i].TextColor3 = Color3.fromRGB(100, 255, 100)
                    else
                        local missingStr = table.concat(missingNames, ", ")
                        fruitLabels[i].Text = string.format("Frucht %d: %d/8 | Fehlt: %s", i, count, missingStr)
                        fruitLabels[i].TextColor3 = Color3.fromRGB(255, 170, 80)
                    end
                end
            end

            -- ARBEITS- / HOP-PHASE
            if not allComplete then
                lblPhase.Text = "Status: Sammle alle Mutationen (8/8)"

                local activeFruitIdx = 1
                for i = 1, 4 do
                    if fruitDataList[i] and fruitDataList[i].count < #TARGET_MUTATIONS then
                        activeFruitIdx = i
                        break
                    end
                end

                local neededWeathers = fruitDataList[activeFruitIdx] and fruitDataList[activeFruitIdx].missingWeather or {}
                local nextWeatherEntry = neededWeathers[1]

                if nextWeatherEntry then
                    lblTarget.Text = string.format("Ziel: F%d braucht Wetter '%s' (%s)", activeFruitIdx, nextWeatherEntry.weather, nextWeatherEntry.name)

                    local curClean = cleanString(cachedCurW)
                    local reqClean = cleanString(nextWeatherEntry.weather)

                    if curClean == reqClean then
                        lblNeeded.Text = "Status: Wetter passt! Warten auf Mutation..."
                        lblNeeded.TextColor3 = Color3.fromRGB(80, 255, 120)
                    else
                        lblNeeded.Text = "Status: Wetter unpassend -> Serverhop"
                        lblNeeded.TextColor3 = Color3.fromRGB(220, 100, 100)

                        if autoHopEnabled then
                            triggerServerHop()
                        end
                    end
                else
                    lblTarget.Text = string.format("Ziel: F%d braucht zufällige Mutationen (Infested/Huge)", activeFruitIdx)
                    lblNeeded.Text = "Status: Serverhop aktiv..."
                    lblNeeded.TextColor3 = Color3.fromRGB(255, 220, 80)
                    if autoHopEnabled then
                        triggerServerHop()
                    end
                end

            -- FERTIG-PHASE (Alle 4 Früchte haben 8/8)
            else
                grindCompleted = true
                autoHopEnabled = false
                hopButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
                hopButton.Text = "Auto-Hop: FERTIG (8/8)"

                lblPhase.Text = "🎉 ALLE 4 FRÜCHTE HABEN 8/8 MUTATIONEN!"
                lblTarget.Text = "Ziel: Bereit zum manuellen Ernten"
                lblNeeded.Text = "Status: Auto-Hop gestoppt."
                lblTarget.TextColor3 = Color3.fromRGB(100, 255, 100)
                lblNeeded.TextColor3 = Color3.fromRGB(100, 255, 100)

                for i = 1, 4 do
                    fruitLabels[i].Text = string.format("Frucht %d: 8/8 Mutationen aktiv ✅", i)
                    fruitLabels[i].TextColor3 = Color3.fromRGB(100, 255, 100)
                end
            end

        end)

        if not ok then
            warn("[Grinder] Fehler:", err)
        end
        
        task.wait(2)
    end
end)

print("[Grinder] Vollständiges Skript mit Auto-Hop erfolgreich geladen!")
