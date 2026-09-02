--------------------------------------------------
-- SERVICES
--------------------------------------------------

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local WeatherEvents = {
    "Meteor Shower",
    "Acid Rain",
    "Blizzard",
    "Sandstorm",
    "Misty",
    "Rainbow",
    "Lucky River"
}

-- Ausgewählte Events
local SelectedEvents = {}

for _, eventName in ipairs(WeatherEvents) do
    SelectedEvents[eventName] = false
end

local DropdownOpen = false
local IsHopping = false

--------------------------------------------------
-- ALTE GUI ENTFERNEN
--------------------------------------------------

pcall(function()
    local oldGui = CoreGui:FindFirstChild("WeatherHopperGui")

    if oldGui then
        oldGui:Destroy()
    end
end)

--------------------------------------------------
-- SCREEN GUI
--------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WeatherHopperGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

--------------------------------------------------
-- MAIN FRAME
--------------------------------------------------

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 225)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

--------------------------------------------------
-- LABEL FUNKTION
--------------------------------------------------

local function createLabel(posY, text, color)

    local lbl = Instance.new("TextLabel")

    lbl.Size = UDim2.new(1, -24, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    lbl.Parent = MainFrame

    return lbl
end

--------------------------------------------------
-- WEATHER LABELS
--------------------------------------------------

local CurrentLbl = createLabel(
    12,
    "Aktuell: Lädt...",
    Color3.fromRGB(200, 200, 200)
)

local NextLbl = createLabel(
    38,
    "Nächstes: Lädt...",
    Color3.fromRGB(100, 220, 255)
)

local TimeLbl = createLabel(
    64,
    "Uhrzeit: Lädt...",
    Color3.fromRGB(255, 220, 100)
)

local StatusLbl = createLabel(
    90,
    "Status: Bereit",
    Color3.fromRGB(150, 255, 150)
)

--------------------------------------------------
-- AUTOFARM MUTATIONS HEADER
--------------------------------------------------

local MutationHeader = Instance.new("TextButton")

MutationHeader.Name = "MutationHeader"
MutationHeader.Size = UDim2.new(1, -24, 0, 28)
MutationHeader.Position = UDim2.new(0, 12, 0, 116)

MutationHeader.BackgroundColor3 =
    Color3.fromRGB(40, 40, 55)

MutationHeader.BorderSizePixel = 0

MutationHeader.Text =
    "AutoFarm Mutations                 >"

MutationHeader.TextColor3 =
    Color3.fromRGB(255, 255, 255)

MutationHeader.TextSize = 13
MutationHeader.Font = Enum.Font.GothamBold
MutationHeader.TextXAlignment = Enum.TextXAlignment.Left

MutationHeader.Parent = MainFrame

local HeaderPadding = Instance.new("UIPadding")
HeaderPadding.PaddingLeft = UDim.new(0, 10)
HeaderPadding.Parent = MutationHeader

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 7)
HeaderCorner.Parent = MutationHeader

--------------------------------------------------
-- EVENT FRAME
--------------------------------------------------

local EventFrame = Instance.new("Frame")

EventFrame.Name = "EventFrame"
EventFrame.Size = UDim2.new(1, -24, 0, 0)
EventFrame.Position = UDim2.new(0, 12, 0, 148)

EventFrame.BackgroundTransparency = 1
EventFrame.Visible = false

EventFrame.Parent = MainFrame

local EventLayout = Instance.new("UIListLayout")

EventLayout.SortOrder = Enum.SortOrder.LayoutOrder
EventLayout.Padding = UDim.new(0, 4)

EventLayout.Parent = EventFrame

--------------------------------------------------
-- AUSGEWÄHLT LABEL
--------------------------------------------------

local SelectedCountLbl = Instance.new("TextLabel")

SelectedCountLbl.Name = "SelectedCountLbl"
SelectedCountLbl.Size = UDim2.new(1, 0, 0, 22)
SelectedCountLbl.BackgroundTransparency = 1
SelectedCountLbl.Text = "Ausgewählt: 0/7"
SelectedCountLbl.TextColor3 = Color3.fromRGB(170, 170, 190)
SelectedCountLbl.TextSize = 11
SelectedCountLbl.Font = Enum.Font.GothamBold
SelectedCountLbl.TextXAlignment = Enum.TextXAlignment.Left
SelectedCountLbl.LayoutOrder = 100
SelectedCountLbl.Parent = EventFrame

--------------------------------------------------
-- CONTROL FRAME
--------------------------------------------------

local ControlFrame = Instance.new("Frame")

ControlFrame.Name = "ControlFrame"
ControlFrame.Size = UDim2.new(1, 0, 0, 25)
ControlFrame.BackgroundTransparency = 1
ControlFrame.LayoutOrder = 0

ControlFrame.Parent = EventFrame

--------------------------------------------------
-- ALLE BUTTON
--------------------------------------------------

local AllButton = Instance.new("TextButton")

AllButton.Size = UDim2.new(0.48, 0, 1, 0)
AllButton.Position = UDim2.new(0, 0, 0, 0)

AllButton.BackgroundColor3 =
    Color3.fromRGB(70, 160, 90)

AllButton.BorderSizePixel = 0

AllButton.Text = "ALLE"
AllButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

AllButton.TextSize = 12
AllButton.Font = Enum.Font.GothamBold

AllButton.Parent = ControlFrame

local AllCorner = Instance.new("UICorner")
AllCorner.CornerRadius = UDim.new(0, 6)
AllCorner.Parent = AllButton

--------------------------------------------------
-- KEINE BUTTON
--------------------------------------------------

local NoneButton = Instance.new("TextButton")

NoneButton.Size = UDim2.new(0.48, 0, 1, 0)
NoneButton.Position = UDim2.new(0.52, 0, 0, 0)

NoneButton.BackgroundColor3 =
    Color3.fromRGB(160, 70, 70)

NoneButton.BorderSizePixel = 0

NoneButton.Text = "KEINE"
NoneButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

NoneButton.TextSize = 12
NoneButton.Font = Enum.Font.GothamBold

NoneButton.Parent = ControlFrame

local NoneCorner = Instance.new("UICorner")
NoneCorner.CornerRadius = UDim.new(0, 6)
NoneCorner.Parent = NoneButton

--------------------------------------------------
-- EVENT BUTTONS
--------------------------------------------------

local EventButtons = {}

--------------------------------------------------
-- SELECTED COUNT AKTUALISIEREN
--------------------------------------------------

local function updateSelectedCount()

    local count = 0

    for _, eventName in ipairs(WeatherEvents) do

        if SelectedEvents[eventName] then
            count = count + 1
        end

    end

    SelectedCountLbl.Text =
        "Ausgewählt: " .. count .. "/" .. #WeatherEvents

end

--------------------------------------------------
-- EVENT BUTTON AKTUALISIEREN
--------------------------------------------------

local function updateEventButton(eventName)

    local button = EventButtons[eventName]

    if not button then
        return
    end

    if SelectedEvents[eventName] then

        button.Text =
            "✓  " .. eventName

        button.BackgroundColor3 =
            Color3.fromRGB(60, 150, 90)

    else

        button.Text =
            "□  " .. eventName

        button.BackgroundColor3 =
            Color3.fromRGB(45, 45, 58)

    end

end

--------------------------------------------------
-- EVENT BUTTONS ERSTELLEN
--------------------------------------------------

for index, eventName in ipairs(WeatherEvents) do

    local button = Instance.new("TextButton")

    button.Name =
        eventName:gsub("%s+", "")

    button.Size =
        UDim2.new(1, 0, 0, 27)

    button.BackgroundColor3 =
        Color3.fromRGB(45, 45, 58)

    button.BorderSizePixel = 0

    button.Text =
        "□  " .. eventName

    button.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    button.TextSize = 12
    button.Font = Enum.Font.GothamBold

    button.TextXAlignment =
        Enum.TextXAlignment.Left

    button.LayoutOrder =
        index

    button.Parent = EventFrame

    local padding = Instance.new("UIPadding")

    padding.PaddingLeft =
        UDim.new(0, 10)

    padding.Parent = button

    local corner = Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(0, 6)

    corner.Parent = button

    EventButtons[eventName] =
        button

    button.MouseButton1Click:Connect(function()

        SelectedEvents[eventName] =
            not SelectedEvents[eventName]

        updateEventButton(eventName)
        updateSelectedCount()

    end)

end

--------------------------------------------------
-- ALLE AUSWÄHLEN
--------------------------------------------------

AllButton.MouseButton1Click:Connect(function()

    for _, eventName in ipairs(WeatherEvents) do

        SelectedEvents[eventName] = true

        updateEventButton(eventName)

    end

    updateSelectedCount()

end)

--------------------------------------------------
-- KEINE AUSWÄHLEN
--------------------------------------------------

NoneButton.MouseButton1Click:Connect(function()

    for _, eventName in ipairs(WeatherEvents) do

        SelectedEvents[eventName] = false

        updateEventButton(eventName)

    end

    updateSelectedCount()

end)

--------------------------------------------------
-- SERVER HOP BUTTON
--------------------------------------------------

local HopButton = Instance.new("TextButton")

HopButton.Name = "HopButton"

HopButton.Size =
    UDim2.new(1, -24, 0, 35)

HopButton.Position =
    UDim2.new(0, 12, 0, 125)

HopButton.BackgroundColor3 =
    Color3.fromRGB(255, 100, 100)

HopButton.Text =
    "SERVER HOP"

HopButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

HopButton.TextSize = 14
HopButton.Font = Enum.Font.GothamBold

HopButton.Parent = MainFrame

local HopCorner = Instance.new("UICorner")

HopCorner.CornerRadius =
    UDim.new(0, 8)

HopCorner.Parent = HopButton

--------------------------------------------------
-- DROPDOWN AUF / ZU
--------------------------------------------------

local function updateDropdown()

    DropdownOpen = not DropdownOpen

    EventFrame.Visible =
        DropdownOpen

    if DropdownOpen then

        MutationHeader.Text =
            "AutoFarm Mutations                 v"

        --------------------------------------------------
        -- EVENT LISTE ÖFFNEN
        --------------------------------------------------

        local eventHeight =
            22 +
            25 +
            (#WeatherEvents * 31)

        EventFrame.Size =
            UDim2.new(
                1,
                -24,
                0,
                eventHeight
            )

        --------------------------------------------------
        -- MAIN FRAME VERGRÖSSERN
        --------------------------------------------------

        MainFrame.Size =
            UDim2.new(
                0,
                300,
                0,
                170 + eventHeight
            )

        --------------------------------------------------
        -- HOP BUTTON NACH UNTEN
        --------------------------------------------------

        HopButton.Position =
            UDim2.new(
                0,
                12,
                0,
                170 + eventHeight
            )

    else

        MutationHeader.Text =
            "AutoFarm Mutations                 >"

        --------------------------------------------------
        -- EVENT LISTE SCHLIESSEN
        --------------------------------------------------

        EventFrame.Size =
            UDim2.new(
                1,
                -24,
                0,
                0
            )

        --------------------------------------------------
        -- MAIN FRAME ZURÜCKSETZEN
        --------------------------------------------------

        MainFrame.Size =
            UDim2.new(
                0,
                300,
                0,
                225
            )

        --------------------------------------------------
        -- HOP BUTTON ZURÜCK
        --------------------------------------------------

        HopButton.Position =
            UDim2.new(
                0,
                12,
                0,
                125
            )

    end

end

MutationHeader.MouseButton1Click:Connect(updateDropdown)

--------------------------------------------------
-- STRING NORMALISIEREN
--------------------------------------------------

local function normalize(str)

    return tostring(str)
        :lower()
        :gsub("^%s+", "")
        :gsub("%s+$", "")

end

--------------------------------------------------
-- AUSGEWÄHLTES EVENT FINDEN
--------------------------------------------------

local function isSelectedWeather(weatherName)

    local normalizedWeather =
        normalize(weatherName)

    for _, eventName in ipairs(WeatherEvents) do

        if SelectedEvents[eventName] then

            local normalizedEvent =
                normalize(eventName)

            if normalizedWeather ==
                normalizedEvent then

                return true, eventName

            end

            if normalizedWeather:find(
                normalizedEvent,
                1,
                true
            ) then

                return true, eventName

            end

        end

    end

    return false, nil

end

--------------------------------------------------
-- SERVER HOP
--------------------------------------------------

local function serverHop()

    if IsHopping then
        return
    end

    IsHopping = true

    StatusLbl.Text =
        "Status: Server Hop..."

    StatusLbl.TextColor3 =
        Color3.fromRGB(255, 150, 80)

    task.wait(0.5)

    local success = pcall(function()

        local servers = {}

        local url =
            "https://games.roblox.com/v1/games/"
            .. PlaceId
            .. "/servers/Public?sortOrder=Asc&limit=100"

        local requestSuccess, result =
            pcall(function()

                return HttpService:JSONDecode(
                    game:HttpGet(url)
                )

            end)

        if requestSuccess
            and result
            and result.data then

            for _, server in ipairs(result.data) do

                if server.playing
                    and server.maxPlayers
                    and server.playing < server.maxPlayers
                    and server.id ~= game.JobId then

                    table.insert(
                        servers,
                        server.id
                    )

                end

            end

        end

        if #servers > 0 then

            local selectedServer =
                servers[
                    math.random(
                        1,
                        #servers
                    )
                ]

            TeleportService:
                TeleportToPlaceInstance(
                    PlaceId,
                    selectedServer,
                    LocalPlayer
                )

        else

            TeleportService:
                Teleport(
                    PlaceId,
                    LocalPlayer
                )

        end

    end)

    if not success then

        StatusLbl.Text =
            "Status: Hop fehlgeschlagen"

        StatusLbl.TextColor3 =
            Color3.fromRGB(255, 80, 80)

        IsHopping = false

    end

end

--------------------------------------------------
-- MANUELLER HOP
--------------------------------------------------

HopButton.MouseButton1Click:Connect(function()

    serverHop()

end)

--------------------------------------------------
-- WEATHER REMOTE SUCHEN
--------------------------------------------------

local function getNextWeatherRemote()

    local packages =
        ReplicatedStorage:
        FindFirstChild("Packages")

    if not packages then
        return nil
    end

    local index =
        packages:
        FindFirstChild("_Index")

    if not index then
        return nil
    end

    for _, child in ipairs(index:GetChildren()) do

        if child.Name:sub(1, 14) ==
            "sleitnick_knit" then

            local knit =
                child:FindFirstChild("knit")

            if knit then

                local services =
                    knit:FindFirstChild("Services")

                if services then

                    local weatherService =
                        services:
                        FindFirstChild("WeatherService")

                    if weatherService then

                        local rf =
                            weatherService:
                            FindFirstChild("RF")

                        if rf then

                            local remote =
                                rf:
                                FindFirstChild(
                                    "GetNextWeather"
                                )

                            if remote then
                                return remote
                            end

                        end

                    end

                end

            end

        end

    end

    return nil

end

--------------------------------------------------
-- AUSGEWÄHLTE EVENTS ALS TEXT
--------------------------------------------------

local function getSelectedText()

    local selected = {}

    for _, eventName in ipairs(WeatherEvents) do

        if SelectedEvents[eventName] then

            table.insert(
                selected,
                eventName
            )

        end

    end

    if #selected == 0 then
        return "Keine"
    end

    return table.concat(
        selected,
        ", "
    )

end

--------------------------------------------------
-- WEATHER CHECK LOOP
--------------------------------------------------

task.spawn(function()

    task.wait(2)

    while true do

        if not IsHopping then

            pcall(function()

                --------------------------------------------------
                -- AKTUELLES WETTER
                --------------------------------------------------

                local curr = "Normal"

                local currentWeather =
                    ReplicatedStorage:
                    FindFirstChild(
                        "CurrentWeather"
                    )

                if currentWeather then

                    curr =
                        tostring(
                            currentWeather.Value
                        )

                end

                CurrentLbl.Text =
                    "Aktuell: " .. curr

                --------------------------------------------------
                -- NÄCHSTES WETTER
                --------------------------------------------------

                local nxt = "Keines"
                local timeStr = "Unbekannt"

                local remote =
                    getNextWeatherRemote()

                if remote then

                    local success, res =
                        pcall(function()

                            return remote:
                                InvokeServer()

                        end)

                    if success
                        and type(res) == "table" then

                        if res.key then

                            nxt =
                                tostring(
                                    res.key
                                )

                        end

                        if res.startTime then

                            timeStr =
                                os.date(
                                    "%H:%M:%S",
                                    res.startTime
                                )

                        end

                    end

                end

                NextLbl.Text =
                    "Nächstes: " .. nxt

                TimeLbl.Text =
                    "Uhrzeit: " .. timeStr

                --------------------------------------------------
                -- AUSGEWÄHLTE EVENTS PRÜFEN
                --------------------------------------------------

                local currentFound,
                    currentMatch =
                    isSelectedWeather(curr)

                local nextFound,
                    nextMatch =
                    isSelectedWeather(nxt)

                --------------------------------------------------
                -- KEINE EVENTS AUSGEWÄHLT
                --------------------------------------------------

                if getSelectedText() == "Keine" then

                    StatusLbl.Text =
                        "Status: Keine Events ausgewählt"

                    StatusLbl.TextColor3 =
                        Color3.fromRGB(
                            255,
                            180,
                            80
                        )

                    return

                end

                --------------------------------------------------
                -- AKTUELLES EVENT GEFUNDEN
                --------------------------------------------------

                if currentFound then

                    StatusLbl.Text =
                        "Status: 🎯 " ..
                        currentMatch ..
                        " gefunden!"

                    StatusLbl.TextColor3 =
                        Color3.fromRGB(
                            80,
                            255,
                            120
                        )

                    return

                end

                --------------------------------------------------
                -- NÄCHSTES EVENT GEFUNDEN
                --------------------------------------------------

                if nextFound then

                    StatusLbl.Text =
                        "Status: 🎯 Nächstes: " ..
                        nextMatch

                    StatusLbl.TextColor3 =
                        Color3.fromRGB(
                            80,
                            255,
                            120
                        )

                    return

                end

                --------------------------------------------------
                -- NICHTS GEFUNDEN
                --------------------------------------------------

                StatusLbl.Text =
                    "Status: Kein Ziel-Event → Hop!"

                StatusLbl.TextColor3 =
                    Color3.fromRGB(
                        255,
                        120,
                        120
                    )

                task.wait(1.5)

                serverHop()

                return

            end)

        end

        task.wait(3)

    end

end)

--------------------------------------------------
-- INITIAL UPDATE
--------------------------------------------------

updateSelectedCount()

print(
    "[Weather Hopper] Loaded!"
)

print(
    "[Weather Hopper] Events: "
    .. table.concat(
        WeatherEvents,
        ", "
    )
)
