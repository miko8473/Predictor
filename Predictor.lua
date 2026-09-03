-- ============================================================
-- SPIRIT FRUIT SMART GRINDER
-- ALL 4 FRUITS + AUTO COLLECT + WEATHER PREVIEW + AUTO-HOP
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

print("============================================================")
print("[SmartGrinder] Gestartet!")
print("[SmartGrinder] Alle 4 Früchte + Auto-Collect")
print("============================================================")


-- ============================================================
-- EINSTELLUNGEN
-- ============================================================

local AUTO_HOP = true
local AUTO_COLLECT = true

local WEATHER_UPDATE_TIME = 4
local MAIN_UPDATE_TIME = 1.5
local COLLECT_DELAY = 0.15


-- ============================================================
-- DIE 6 WETTER-MUTATIONEN
-- ============================================================

local WEATHER_ORDER = {
    {
        weather = "Misty",
        mutation = "Dewy"
    },

    {
        weather = "Sandstorm",
        mutation = "Dusty"
    },

    {
        weather = "Blizzard",
        mutation = "Frosted"
    },

    {
        weather = "Acid-Rain",
        mutation = "Radioactive"
    },

    {
        weather = "Rainbow",
        mutation = "Golden"
    },

    {
        weather = "Meteor Shower",
        mutation = "Cosmic"
    }
}


-- ============================================================
-- STATUS
-- ============================================================

local autoHopEnabled = AUTO_HOP
local autoCollectEnabled = AUTO_COLLECT

local teleporting = false
local grindCompleted = false

local collectedFruits = {}


-- ============================================================
-- GUI AUFRÄUMEN
-- ============================================================

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("SpiritGrinderGUI") then
    playerGui.SpiritGrinderGUI:Destroy()
end


-- ============================================================
-- GUI
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpiritGrinderGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui


local mainFrame = Instance.new("Frame")

mainFrame.Size = UDim2.new(0, 360, 0, 390)
mainFrame.Position = UDim2.new(0, 25, 0, 80)

mainFrame.BackgroundColor3 =
    Color3.fromRGB(14, 14, 20)

mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

mainFrame.Parent = screenGui


local mainCorner = Instance.new("UICorner")

mainCorner.CornerRadius =
    UDim.new(0, 12)

mainCorner.Parent = mainFrame


local mainStroke = Instance.new("UIStroke")

mainStroke.Color =
    Color3.fromRGB(45, 45, 65)

mainStroke.Thickness = 1.5

mainStroke.Parent = mainFrame


-- ============================================================
-- HEADER
-- ============================================================

local header = Instance.new("Frame")

header.Size =
    UDim2.new(1, 0, 0, 36)

header.BackgroundColor3 =
    Color3.fromRGB(22, 22, 32)

header.BorderSizePixel = 0

header.Parent = mainFrame


local headerCorner = Instance.new("UICorner")

headerCorner.CornerRadius =
    UDim.new(0, 12)

headerCorner.Parent = header


local titleLabel = Instance.new("TextLabel")

titleLabel.Size =
    UDim2.new(1, -16, 1, 0)

titleLabel.Position =
    UDim2.new(0, 12, 0, 0)

titleLabel.BackgroundTransparency = 1

titleLabel.Text =
    "🌱 SMART GRINDER <font color='#8888aa'>(Auto-Collect)</font>"

titleLabel.RichText = true

titleLabel.TextColor3 =
    Color3.fromRGB(255, 255, 255)

titleLabel.TextSize = 13

titleLabel.Font =
    Enum.Font.GothamBold

titleLabel.TextXAlignment =
    Enum.TextXAlignment.Left

titleLabel.Parent = header


-- ============================================================
-- CONTENT
-- ============================================================

local contentContainer = Instance.new("Frame")

contentContainer.Size =
    UDim2.new(1, -20, 1, -44)

contentContainer.Position =
    UDim2.new(0, 10, 0, 40)

contentContainer.BackgroundTransparency = 1

contentContainer.Parent = mainFrame


local contentLayout = Instance.new("UIListLayout")

contentLayout.SortOrder =
    Enum.SortOrder.LayoutOrder

contentLayout.Padding =
    UDim.new(0, 4)

contentLayout.Parent = contentContainer


local function createRow(name, sizeY, textSize)

    local lbl = Instance.new("TextLabel")

    lbl.Name = name

    lbl.Size =
        UDim2.new(1, 0, 0, sizeY or 20)

    lbl.BackgroundTransparency = 1

    lbl.TextColor3 =
        Color3.fromRGB(210, 210, 220)

    lbl.TextSize =
        textSize or 12

    lbl.Font =
        Enum.Font.GothamMedium

    lbl.TextXAlignment =
        Enum.TextXAlignment.Left

    lbl.Parent =
        contentContainer

    return lbl
end


local lblWeather =
    createRow("LblWeather", 20, 12)

local lblNextWeather =
    createRow("LblNextWeather", 20, 12)


local div1 = Instance.new("Frame")

div1.Size =
    UDim2.new(1, 0, 0, 1)

div1.BackgroundColor3 =
    Color3.fromRGB(40, 40, 60)

div1.BorderSizePixel = 0

div1.Parent =
    contentContainer


local fruitLabels = {

    createRow("Fruit1", 20, 11),

    createRow("Fruit2", 20, 11),

    createRow("Fruit3", 20, 11),

    createRow("Fruit4", 20, 11)
}


local div2 = Instance.new("Frame")

div2.Size =
    UDim2.new(1, 0, 0, 1)

div2.BackgroundColor3 =
    Color3.fromRGB(40, 40, 60)

div2.BorderSizePixel = 0

div2.Parent =
    contentContainer


local lblPhase =
    createRow("LblPhase", 20, 11)

lblPhase.Font =
    Enum.Font.GothamBold

lblPhase.TextColor3 =
    Color3.fromRGB(100, 200, 255)


local lblTarget =
    createRow("LblTarget", 20, 11)

lblTarget.Font =
    Enum.Font.GothamBold

lblTarget.TextColor3 =
    Color3.fromRGB(255, 190, 80)


local lblNeeded =
    createRow("LblNeeded", 20, 11)

lblNeeded.Font =
    Enum.Font.GothamBold

lblNeeded.TextColor3 =
    Color3.fromRGB(80, 255, 120)


-- ============================================================
-- AUTO COLLECT BUTTON
-- ============================================================

local collectButton = Instance.new("TextButton")

collectButton.Size =
    UDim2.new(1, 0, 0, 28)

collectButton.BackgroundColor3 =
    Color3.fromRGB(40, 160, 80)

collectButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

collectButton.TextSize = 12

collectButton.Font =
    Enum.Font.GothamBold

collectButton.Text =
    "Auto-Collect: AN"

collectButton.Parent =
    contentContainer


local collectCorner =
    Instance.new("UICorner")

collectCorner.CornerRadius =
    UDim.new(0, 6)

collectCorner.Parent =
    collectButton


collectButton.MouseButton1Click:Connect(function()

    autoCollectEnabled =
        not autoCollectEnabled

    if autoCollectEnabled then

        collectButton.BackgroundColor3 =
            Color3.fromRGB(40, 160, 80)

        collectButton.Text =
            "Auto-Collect: AN"

    else

        collectButton.BackgroundColor3 =
            Color3.fromRGB(160, 40, 40)

        collectButton.Text =
            "Auto-Collect: AUS"
    end
end)


-- ============================================================
-- AUTO HOP BUTTON
-- ============================================================

local hopButton = Instance.new("TextButton")

hopButton.Size =
    UDim2.new(1, 0, 0, 28)

hopButton.BackgroundColor3 =
    Color3.fromRGB(40, 160, 80)

hopButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

hopButton.TextSize = 12

hopButton.Font =
    Enum.Font.GothamBold

hopButton.Text =
    "Auto-Hop: AN"

hopButton.Parent =
    contentContainer


local hopCorner =
    Instance.new("UICorner")

hopCorner.CornerRadius =
    UDim.new(0, 6)

hopCorner.Parent =
    hopButton


hopButton.MouseButton1Click:Connect(function()

    if grindCompleted then
        return
    end

    autoHopEnabled =
        not autoHopEnabled

    teleporting = false

    if autoHopEnabled then

        hopButton.BackgroundColor3 =
            Color3.fromRGB(40, 160, 80)

        hopButton.Text =
            "Auto-Hop: AN"

    else

        hopButton.BackgroundColor3 =
            Color3.fromRGB(160, 40, 40)

        hopButton.Text =
            "Auto-Hop: AUS"
    end
end)


-- ============================================================
-- STRING BEREINIGEN
-- ============================================================

local function cleanString(str)

    if not str then
        return ""
    end

    return tostring(str)
        :gsub("%s+", "")
        :lower()
end


-- ============================================================
-- AKTUELLES WETTER
-- ============================================================

local function getActiveWeather()

    local currentWeatherObj =
        ReplicatedStorage:FindFirstChild("CurrentWeather")
        or ReplicatedStorage:FindFirstChild("CurrentWeather", true)

    if currentWeatherObj then

        local val = nil

        if currentWeatherObj:IsA("ValueBase") then

            val =
                currentWeatherObj.Value

        elseif currentWeatherObj:IsA("TextLabel")
            or currentWeatherObj:IsA("TextBox") then

            val =
                currentWeatherObj.Text
        end


        if not val or val == "" then

            val =
                currentWeatherObj:GetAttribute("Value")
                or currentWeatherObj:GetAttribute("Weather")
                or currentWeatherObj:GetAttribute("CurrentWeather")
        end


        if val and tostring(val) ~= "" then

            return tostring(val)
        end
    end


    local attrWeather =
        ReplicatedStorage:GetAttribute(
            "CurrentWeather"
        )


    if attrWeather then

        return tostring(attrWeather)
    end


    return "Unknown"
end


-- ============================================================
-- NÄCHSTES WETTER
-- ============================================================

local function getNextWeather()

    for _, desc in ipairs(
        ReplicatedStorage:GetDescendants()
    ) do

        if desc.Name == "GetNextWeather"
            and desc:IsA("RemoteFunction") then

            local success, res =
                pcall(function()

                    return desc:InvokeServer()
                end)


            if success and type(res) == "table" then

                return res.key
                    or res.Name
                    or "Unknown"

            elseif success
                and type(res) == "string" then

                return res
            end
        end
    end


    return "Unknown"
end


-- ============================================================
-- SPIRIT TREE FINDEN
-- ============================================================

local function getPlayerSpiritTree()

    local bigField =
        Workspace:FindFirstChild("BigField")

    if not bigField then
        return nil
    end


    local playerPlots =
        bigField:FindFirstChild("PlayerPlots")

    if not playerPlots then
        return nil
    end


    local myPlot = nil


    for _, plot in ipairs(
        playerPlots:GetChildren()
    ) do

        if tonumber(
            plot:GetAttribute("OwnerUserId")
        ) == LocalPlayer.UserId then

            myPlot = plot
            break
        end
    end


    if not myPlot then
        return nil
    end


    for _, child in ipairs(
        myPlot:GetChildren()
    ) do

        if child:GetAttribute("SeedType")
            == "Spirit" then

            return child
        end
    end


    return nil
end


-- ============================================================
-- FRUIT SPAWNS FINDEN
-- ============================================================

local function getFruitSpawns()

    local spiritTree =
        getPlayerSpiritTree()

    if not spiritTree then
        return nil
    end


    local fruitSpawnsFolder =
        spiritTree:FindFirstChild("FruitSpawns")

    if not fruitSpawnsFolder then
        return nil
    end


    local fruitMap = {}


    for _, obj in ipairs(
        fruitSpawnsFolder:GetChildren()
    ) do

        local idx =
            obj:GetAttribute("SpawnIndex")


        if typeof(idx) == "number"
            and idx >= 1
            and idx <= 4
            and idx % 1 == 0 then

            fruitMap[idx] = obj
        end
    end


    return fruitMap
end


-- ============================================================
-- AUTO COLLECT
-- ============================================================

local function collectFruit(spawnObj, fruitIndex)

    if not autoCollectEnabled then
        return false
    end

    if not spawnObj then
        return false
    end


    -- Verhindert mehrfaches Einsammeln
    -- derselben bereits gefundenen Frucht.
    if collectedFruits[spawnObj] then
        return false
    end


    local collected = false


    -- ========================================================
    -- CLICK DETECTOR
    -- ========================================================

    local clickDetector =
        spawnObj:FindFirstChildOfClass(
            "ClickDetector"
        )


    if clickDetector then

        local success =
            pcall(function()

                fireclickdetector(
                    clickDetector
                )
            end)


        if success then

            collected = true

            print(
                "[AutoCollector] 🍎 Frucht",
                fruitIndex,
                "per ClickDetector eingesammelt!"
            )
        end
    end


    -- ========================================================
    -- PROXIMITY PROMPT
    -- ========================================================

    if not collected then

        local prompt =
            spawnObj:FindFirstChildOfClass(
                "ProximityPrompt"
            )


        if prompt then

            local success =
                pcall(function()

                    fireproximityprompt(
                        prompt
                    )
                end)


            if success then

                collected = true

                print(
                    "[AutoCollector] 🍎 Frucht",
                    fruitIndex,
                    "per ProximityPrompt eingesammelt!"
                )
            end
        end
    end


    if collected then

        collectedFruits[spawnObj] = true

        task.wait(COLLECT_DELAY)

        return true
    end


    return false
end


-- ============================================================
-- WETTER-CACHE
-- ============================================================

local cachedCurW =
    "Laden..."

local cachedNextW =
    "Laden..."


task.spawn(function()

    while screenGui.Parent do

        cachedCurW =
            getActiveWeather()

        cachedNextW =
            getNextWeather()

        task.wait(
            WEATHER_UPDATE_TIME
        )
    end
end)


-- ============================================================
-- HAUPTLOGIK
-- ============================================================

task.spawn(function()

    while screenGui.Parent do

        local ok, err =
            pcall(function()

                lblWeather.Text =
                    "Aktuell: "
                    .. cachedCurW

                lblNextWeather.Text =
                    "Nächstes: "
                    .. cachedNextW


                local fruitMap =
                    getFruitSpawns()


                if not fruitMap then

                    resetUIState(
                        "Phase: Fehler",
                        "Ziel: Kein Spirit-Baum",
                        "Warte..."
                    )

                    return
                end


                -- ====================================================
                -- ALLE FRÜCHTE ANALYSIEREN
                -- ====================================================

                local fruitDataList = {}

                local allNeededWeathers = {}

                local allWeatherComplete =
                    true


                for i = 1, 4 do

                    local spawnObj =
                        fruitMap[i]


                    if not spawnObj then

                        fruitDataList[i] = {
                            count = 0,
                            missing = {}
                        }

                        allWeatherComplete =
                            false

                    else

                        local mutationsAttr =
                            spawnObj:GetAttribute(
                                "FruitMutations"
                            )
                            or ""


                        local foundMap = {}


                        for mut in mutationsAttr:gmatch(
                            "[^,%s]+"
                        ) do

                            foundMap[
                                mut:lower()
                            ] = true
                        end


                        local weatherCount = 0

                        local missingList = {}


                        for _, entry in ipairs(
                            WEATHER_ORDER
                        ) do

                            local mutationName =
                                entry.mutation:lower()


                            if foundMap[
                                mutationName
                            ] then

                                weatherCount =
                                    weatherCount + 1

                            else

                                table.insert(
                                    missingList,
                                    entry
                                )


                                -- Global speichern:
                                -- egal welche Frucht es braucht.
                                if not allNeededWeathers[
                                    mutationName
                                ] then

                                    allNeededWeathers[
                                        mutationName
                                    ] = {

                                        weather =
                                            entry.weather,

                                        mutation =
                                            entry.mutation,

                                        fruits = {}
                                    }
                                end


                                table.insert(
                                    allNeededWeathers[
                                        mutationName
                                    ].fruits,
                                    i
                                )
                            end
                        end


                        if weatherCount <
                            #WEATHER_ORDER then

                            allWeatherComplete =
                                false
                        end


                        fruitDataList[i] = {

                            count =
                                weatherCount,

                            missing =
                                missingList
                        }


                        -- ====================================================
                        -- AUTO COLLECT
                        -- ====================================================

                        if weatherCount >=
                            #WEATHER_ORDER then

                            if autoCollectEnabled then

                                collectFruit(
                                    spawnObj,
                                    i
                                )
                            end
                        end
                    end
                end


                -- ====================================================
                -- GUI FÜR ALLE 4 FRÜCHTE
                -- ====================================================

                for i = 1, 4 do

                    local dat =
                        fruitDataList[i]


                    if dat.count >=
                        #WEATHER_ORDER then

                        fruitLabels[i].Text =
                            string.format(
                                "Frucht %d: 6/6 Komplett ✅ → Einsammeln",
                                i
                            )

                        fruitLabels[i].TextColor3 =
                            Color3.fromRGB(
                                100,
                                255,
                                100
                            )

                    else

                        fruitLabels[i].Text =
                            string.format(
                                "Frucht %d: %d/6 Mutationen",
                                i,
                                dat.count
                            )

                        fruitLabels[i].TextColor3 =
                            Color3.fromRGB(
                                255,
                                170,
                                80
                            )
                    end
                end


                -- ====================================================
                -- ALLE FRÜCHTE FERTIG?
                -- ====================================================

                if allWeatherComplete then

                    grindCompleted = true

                    autoHopEnabled = false


                    hopButton.BackgroundColor3 =
                        Color3.fromRGB(
                            80,
                            80,
                            100
                        )


                    hopButton.Text =
                        "Auto-Hop: FERTIG"


                    lblPhase.Text =
                        "🎉 ALLE 4 FRÜCHTE HABEN 6/6!"


                    lblTarget.Text =
                        "Ziel: Früchte wurden eingesammelt"


                    lblNeeded.Text =
                        "Status: Grinder abgeschlossen."


                    lblTarget.TextColor3 =
                        Color3.fromRGB(
                            100,
                            255,
                            100
                        )


                    lblNeeded.TextColor3 =
                        Color3.fromRGB(
                            100,
                            255,
                            100
                        )


                    return
                end


                -- ====================================================
                -- AKTUELLES WETTER / NÄCHSTES WETTER
                -- FÜR ALLE 4 FRÜCHTE
                -- ====================================================

                local curClean =
                    cleanString(
                        cachedCurW
                    )


                local nextClean =
                    cleanString(
                        cachedNextW
                    )


                local currentMatch = nil

                local nextMatch = nil


                -- Aktuelles Wetter
                for mutationName, data in pairs(
                    allNeededWeathers
                ) do

                    if curClean ==
                        cleanString(
                            data.weather
                        ) then

                        currentMatch = data

                        break
                    end
                end


                -- Nächstes Wetter
                if not currentMatch then

                    for mutationName, data in pairs(
                        allNeededWeathers
                    ) do

                        if nextClean ==
                            cleanString(
                                data.weather
                            ) then

                            nextMatch = data

                            break
                        end
                    end
                end


                -- ====================================================
                -- AKTUELLES WETTER PASST
                -- ====================================================

                if currentMatch then

                    local fruitText = ""


                    for index, fruitIndex in ipairs(
                        currentMatch.fruits
                    ) do

                        if index > 1 then
                            fruitText =
                                fruitText .. ", "
                        end

                        fruitText =
                            fruitText
                            .. "F"
                            .. fruitIndex
                    end


                    lblPhase.Text =
                        "Status: Wetter aktiv"


                    lblTarget.Text =
                        string.format(
                            "Ziel: %s braucht '%s' (%s)",
                            fruitText,
                            currentMatch.weather,
                            currentMatch.mutation
                        )


                    lblNeeded.Text =
                        "🌦️ Wetter aktiv! Bleibe auf Server."


                    lblNeeded.TextColor3 =
                        Color3.fromRGB(
                            80,
                            255,
                            120
                        )


                -- ====================================================
                -- NÄCHSTES WETTER PASST
                -- ====================================================

                elseif nextMatch then

                    local fruitText = ""


                    for index, fruitIndex in ipairs(
                        nextMatch.fruits
                    ) do

                        if index > 1 then
                            fruitText =
                                fruitText .. ", "
                        end

                        fruitText =
                            fruitText
                            .. "F"
                            .. fruitIndex
                    end


                    lblPhase.Text =
                        "Status: Warte auf Wetter"


                    lblTarget.Text =
                        string.format(
                            "Ziel: %s braucht '%s' (%s)",
                            fruitText,
                            nextMatch.weather,
                            nextMatch.mutation
                        )


                    lblNeeded.Text =
                        "⏳ Nächstes Wetter passt! Warte."


                    lblNeeded.TextColor3 =
                        Color3.fromRGB(
                            255,
                            220,
                            80
                        )


                -- ====================================================
                -- KEIN WETTER PASST
                -- ====================================================

                else

                    lblPhase.Text =
                        "Status: Kein benötigtes Wetter"


                    lblTarget.Text =
                        "Ziel: Keine der 4 Früchte braucht dieses Wetter"


                    lblNeeded.Text =
                        "❌ Wetter nicht benötigt → Hoppe"


                    lblNeeded.TextColor3 =
                        Color3.fromRGB(
                            220,
                            100,
                            100
                        )


                    -- ====================================================
                    -- SERVER HOP
                    -- ====================================================

                    if autoHopEnabled
                        and not teleporting then

                        teleporting = true


                        print(
                            "[SmartGrinder] 🔄 Serverhop! JobId:",
                            game.JobId
                        )


                        hopButton.Text =
                            "Auto-Hop: Wechsle Server..."


                        pcall(function()

                            TeleportService:Teleport(
                                game.PlaceId,
                                LocalPlayer
                            )
                        end)
                    end
                end
            end)


        if not ok then

            warn(
                "[SmartGrinder] Fehler:",
                err
            )
        end


        task.wait(
            MAIN_UPDATE_TIME
        )
    end
end)


print(
    "[SmartGrinder] Erfolgreich geladen!"
)
