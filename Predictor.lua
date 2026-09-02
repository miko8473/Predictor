```lua
--// Greedy Growers - Weather Sniffer & Auto Hopper
--// AutoFarm Mutations mit Auswahl mehrerer Wetter-Events
--// Kein manueller Server-Hop Button

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

--==================================================
-- SETTINGS
--==================================================

local WeatherEvents = {
    "Meteor Shower",
    "Acid Rain",
    "Blizzard",
    "Sandstorm",
    "Misty",
    "Rainbow",
    "Lucky River"
}

local SelectedEvents = {}

for _, eventName in ipairs(WeatherEvents) do
    SelectedEvents[eventName] = false
end

local DropdownOpen = false
local IsHopping = false

--==================================================
-- REMOVE OLD GUI
--==================================================

pcall(function()
    local oldGui = CoreGui:FindFirstChild("WeatherHopperGui")
    if oldGui then
        oldGui:Destroy()
    end
end)

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WeatherHopperGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.05, 0, 0.30, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = MainFrame

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 25)
Title.Position = UDim2.new(0, 5, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "Greedy Growers Weather Sniffer"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

--==================================================
-- CURRENT WEATHER
--==================================================

local CurrentLabel = Instance.new("TextLabel")
CurrentLabel.Size = UDim2.new(1, -10, 0, 22)
CurrentLabel.Position = UDim2.new(0, 5, 0, 35)
CurrentLabel.BackgroundTransparency = 1
CurrentLabel.Text = "Current: ..."
CurrentLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
CurrentLabel.TextSize = 13
CurrentLabel.Font = Enum.Font.Gotham
CurrentLabel.TextXAlignment = Enum.TextXAlignment.Left
CurrentLabel.Parent = MainFrame

--==================================================
-- NEXT WEATHER
--==================================================

local NextLabel = Instance.new("TextLabel")
NextLabel.Size = UDim2.new(1, -10, 0, 22)
NextLabel.Position = UDim2.new(0, 5, 0, 58)
NextLabel.BackgroundTransparency = 1
NextLabel.Text = "Next: ..."
NextLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
NextLabel.TextSize = 13
NextLabel.Font = Enum.Font.Gotham
NextLabel.TextXAlignment = Enum.TextXAlignment.Left
NextLabel.Parent = MainFrame

--==================================================
-- TIME
--==================================================

local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(1, -10, 0, 22)
TimeLabel.Position = UDim2.new(0, 5, 0, 81)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "Next Start: ..."
TimeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
TimeLabel.TextSize = 12
TimeLabel.Font = Enum.Font.Gotham
TimeLabel.TextXAlignment = Enum.TextXAlignment.Left
TimeLabel.Parent = MainFrame

--==================================================
-- STATUS
--==================================================

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 22)
StatusLabel.Position = UDim2.new(0, 5, 0, 104)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Starte..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

--==================================================
-- AUTOFARM MUTATIONS HEADER
--==================================================

local MutationHeader = Instance.new("Frame")
MutationHeader.Name = "MutationHeader"
MutationHeader.Size = UDim2.new(1, -10, 0, 30)
MutationHeader.Position = UDim2.new(0, 5, 0, 126)
MutationHeader.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
MutationHeader.BorderSizePixel = 0
MutationHeader.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 6)
HeaderCorner.Parent = MutationHeader

-- Header text
local HeaderButton = Instance.new("TextButton")
HeaderButton.Name = "HeaderButton"
HeaderButton.Size = UDim2.new(1, -40, 1, 0)
HeaderButton.Position = UDim2.new(0, 0, 0, 0)
HeaderButton.BackgroundTransparency = 1
HeaderButton.Text = "AutoFarm Mutations"
HeaderButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderButton.TextSize = 13
HeaderButton.Font = Enum.Font.GothamBold
HeaderButton.TextXAlignment = Enum.TextXAlignment.Left
HeaderButton.Parent = MutationHeader

local HeaderPadding = Instance.new("UIPadding")
HeaderPadding.PaddingLeft = UDim.new(0, 8)
HeaderPadding.Parent = HeaderButton

--==================================================
-- ARROW BUTTON
--==================================================

local ArrowButton = Instance.new("TextButton")
ArrowButton.Name = "ArrowButton"
ArrowButton.Size = UDim2.new(0, 36, 1, 0)
ArrowButton.Position = UDim2.new(1, -36, 0, 0)
ArrowButton.BackgroundTransparency = 1
ArrowButton.Text = ">"
ArrowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ArrowButton.TextSize = 20
ArrowButton.Font = Enum.Font.GothamBold
ArrowButton.ZIndex = 10
ArrowButton.AutoButtonColor = true
ArrowButton.Parent = MutationHeader

--==================================================
-- EVENT LIST
--==================================================

local EventFrame = Instance.new("Frame")
EventFrame.Name = "EventFrame"
EventFrame.Size = UDim2.new(1, -10, 0, 255)
EventFrame.Position = UDim2.new(0, 5, 0, 161)
EventFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
EventFrame.BorderSizePixel = 0
EventFrame.Visible = false
EventFrame.Parent = MainFrame

local EventCorner = Instance.new("UICorner")
EventCorner.CornerRadius = UDim.new(0, 6)
EventCorner.Parent = EventFrame

local EventLayout = Instance.new("UIListLayout")
EventLayout.Padding = UDim.new(0, 3)
EventLayout.SortOrder = Enum.SortOrder.LayoutOrder
EventLayout.Parent = EventFrame

local EventPadding = Instance.new("UIPadding")
EventPadding.PaddingTop = UDim.new(0, 5)
EventPadding.PaddingLeft = UDim.new(0, 5)
EventPadding.PaddingRight = UDim.new(0, 5)
EventPadding.PaddingBottom = UDim.new(0, 5)
EventPadding.Parent = EventFrame

--==================================================
-- ALL / NONE BUTTONS
--==================================================

local ControlFrame = Instance.new("Frame")
ControlFrame.Size = UDim2.new(1, 0, 0, 25)
ControlFrame.BackgroundTransparency = 1
ControlFrame.LayoutOrder = 0
ControlFrame.Parent = EventFrame

local AllButton = Instance.new("TextButton")
AllButton.Size = UDim2.new(0.48, 0, 1, 0)
AllButton.Position = UDim2.new(0, 0, 0, 0)
AllButton.BackgroundColor3 = Color3.fromRGB(55, 100, 65)
AllButton.BorderSizePixel = 0
AllButton.Text = "ALL"
AllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AllButton.TextSize = 12
AllButton.Font = Enum.Font.GothamBold
AllButton.Parent = ControlFrame

local AllCorner = Instance.new("UICorner")
AllCorner.CornerRadius = UDim.new(0, 5)
AllCorner.Parent = AllButton

local NoneButton = Instance.new("TextButton")
NoneButton.Size = UDim2.new(0.48, 0, 1, 0)
NoneButton.Position = UDim2.new(0.52, 0, 0, 0)
NoneButton.BackgroundColor3 = Color3.fromRGB(100, 55, 55)
NoneButton.BorderSizePixel = 0
NoneButton.Text = "NONE"
NoneButton.TextColor3 = Color3.fromRGB(255, 255, 255)
NoneButton.TextSize = 12
NoneButton.Font = Enum.Font.GothamBold
NoneButton.Parent = ControlFrame

local NoneCorner = Instance.new("UICorner")
NoneCorner.CornerRadius = UDim.new(0, 5)
NoneCorner.Parent = NoneButton

--==================================================
-- SELECTED COUNT
--==================================================

local SelectedCount = Instance.new("TextLabel")
SelectedCount.Size = UDim2.new(1, 0, 0, 20)
SelectedCount.BackgroundTransparency = 1
SelectedCount.Text = "Ausgewählt: 0 / 7"
SelectedCount.TextColor3 = Color3.fromRGB(180, 180, 180)
SelectedCount.TextSize = 11
SelectedCount.Font = Enum.Font.Gotham
SelectedCount.LayoutOrder = 100
SelectedCount.Parent = EventFrame

--==================================================
-- EVENT BUTTONS
--==================================================

local EventButtons = {}

local function updateSelectedCount()
    local count = 0

    for _, eventName in ipairs(WeatherEvents) do
        if SelectedEvents[eventName] then
            count = count + 1
        end
    end

    SelectedCount.Text = "Ausgewählt: " .. count .. " / " .. #WeatherEvents
end

local function updateEventButton(eventName)
    local button = EventButtons[eventName]

    if not button then
        return
    end

    if SelectedEvents[eventName] then
        button.Text = "✓  " .. eventName
        button.BackgroundColor3 = Color3.fromRGB(55, 100, 65)
    else
        button.Text = "□  " .. eventName
        button.BackgroundColor3 = Color3.fromRGB(48, 48, 55)
    end
end

for index, eventName in ipairs(WeatherEvents) do

    local Button = Instance.new("TextButton")
    Button.Name = eventName:gsub("%s+", "_")
    Button.Size = UDim2.new(1, 0, 0, 27)
    Button.BackgroundColor3 = Color3.fromRGB(48, 48, 55)
    Button.BorderSizePixel = 0
    Button.Text = "□  " .. eventName
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.TextSize = 12
    Button.Font = Enum.Font.Gotham
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.LayoutOrder = index
    Button.Parent = EventFrame

    local ButtonPadding = Instance.new("UIPadding")
    ButtonPadding.PaddingLeft = UDim.new(0, 8)
    ButtonPadding.Parent = Button

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 5)
    ButtonCorner.Parent = Button

    EventButtons[eventName] = Button

    Button.MouseButton1Click:Connect(function()
        SelectedEvents[eventName] = not SelectedEvents[eventName]

        updateEventButton(eventName)
        updateSelectedCount()
    end)
end

--==================================================
-- DROPDOWN TOGGLE
--==================================================

local function toggleDropdown()
    DropdownOpen = not DropdownOpen

    if DropdownOpen then
        ArrowButton.Text = "v"
        EventFrame.Visible = true

        MainFrame.Size = UDim2.new(0, 300, 0, 425)
    else
        ArrowButton.Text = ">"
        EventFrame.Visible = false

        MainFrame.Size = UDim2.new(0, 300, 0, 156)
    end
end

ArrowButton.MouseButton1Click:Connect(toggleDropdown)
HeaderButton.MouseButton1Click:Connect(toggleDropdown)

--==================================================
-- ALL / NONE
--==================================================

AllButton.MouseButton1Click:Connect(function()

    for _, eventName in ipairs(WeatherEvents) do
        SelectedEvents[eventName] = true
        updateEventButton(eventName)
    end

    updateSelectedCount()
end)

NoneButton.MouseButton1Click:Connect(function()

    for _, eventName in ipairs(WeatherEvents) do
        SelectedEvents[eventName] = false
        updateEventButton(eventName)
    end

    updateSelectedCount()
end)

updateSelectedCount()

--==================================================
-- WEATHER REMOTE
--==================================================

local function getNextWeatherRemote()

    local Packages = ReplicatedStorage:FindFirstChild("Packages")

    if not Packages then
        return nil
    end

    local KnitFolder = nil

    for _, child in ipairs(Packages:GetChildren()) do
        if string.sub(child.Name, 1, 13) == "sleitnick_knit" then
            KnitFolder = child
            break
        end
    end

    if not KnitFolder then
        return nil
    end

    local Knit = KnitFolder:FindFirstChild("Knit")

    if not Knit then
        return nil
    end

    local Services = Knit:FindFirstChild("Services")

    if not Services then
        return nil
    end

    local WeatherService = Services:FindFirstChild("WeatherService")

    if not WeatherService then
        return nil
    end

    local RF = WeatherService:FindFirstChild("RF")

    if not RF then
        return nil
    end

    local Remote = RF:FindFirstChild("GetNextWeather")

    return Remote
end

--==================================================
-- NORMALIZE
--==================================================

local function normalize(value)

    if value == nil then
        return ""
    end

    return string.lower(string.gsub(tostring(value), "^%s*(.-)%s*$", "%1"))
end

--==================================================
-- SELECTED WEATHER CHECK
--==================================================

local function getSelectedEvent(weatherName)

    local normalizedWeather = normalize(weatherName)

    if normalizedWeather == "" then
        return nil
    end

    for _, eventName in ipairs(WeatherEvents) do

        if SelectedEvents[eventName] then

            local normalizedEvent = normalize(eventName)

            if string.find(normalizedWeather, normalizedEvent, 1, true) then
                return eventName
            end
        end
    end

    return nil
end

--==================================================
-- CHECK IF ANY EVENT IS SELECTED
--==================================================

local function hasSelectedEvents()

    for _, eventName in ipairs(WeatherEvents) do
        if SelectedEvents[eventName] then
            return true
        end
    end

    return false
end

--==================================================
-- SERVER HOP
--==================================================

local function serverHop()

    if IsHopping then
        return
    end

    IsHopping = true

    StatusLabel.Text = "Status: Suche neuen Server..."

    local success, result = pcall(function()

        local url =
            "https://games.roblox.com/v1/games/"
            .. tostring(PlaceId)
            .. "/servers/Public?sortOrder=Asc&limit=100"

        return game:HttpGet(url)
    end)

    if not success then

        StatusLabel.Text = "Status: Server-Liste Fehler"
        IsHopping = false

        task.wait(3)

        return
    end

    local decodeSuccess, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(result)
    end)

    if not decodeSuccess or not data or not data.data then

        StatusLabel.Text = "Status: Server-Daten Fehler"
        IsHopping = false

        task.wait(3)

        return
    end

    local Servers = {}

    for _, server in ipairs(data.data) do

        if server.id
            and server.id ~= game.JobId
            and server.playing
            and server.maxPlayers
            and server.playing < server.maxPlayers then

            table.insert(Servers, server.id)
        end
    end

    if #Servers > 0 then

        local RandomServer = Servers[math.random(1, #Servers)]

        StatusLabel.Text = "Status: Teleportiere..."

        pcall(function()
            TeleportService:TeleportToPlaceInstance(
                PlaceId,
                RandomServer,
                LocalPlayer
            )
        end)

        task.wait(5)

        IsHopping = false

    else

        StatusLabel.Text = "Status: Kein Server gefunden"

        IsHopping = false

        task.wait(5)
    end
end

--==================================================
-- MAIN WEATHER LOOP
--==================================================

task.spawn(function()

    task.wait(2)

    while true do

        -- Keine Events ausgewählt
        if not hasSelectedEvents() then

            CurrentLabel.Text = "Current: -"
            NextLabel.Text = "Next: -"
            TimeLabel.Text = "Next Start: -"
            StatusLabel.Text = "Status: Keine Events ausgewählt"

            task.wait(3)

            continue
        end

        -- Current Weather
        local currentWeather = "Unknown"

        pcall(function()

            local CurrentWeather = ReplicatedStorage:FindFirstChild("CurrentWeather")

            if CurrentWeather then

                if CurrentWeather:IsA("StringValue") then
                    currentWeather = CurrentWeather.Value

                elseif CurrentWeather:IsA("ObjectValue") and CurrentWeather.Value then
                    currentWeather = CurrentWeather.Value.Name

                else
                    currentWeather = tostring(CurrentWeather.Value or CurrentWeather.Name)
                end

            end
        end)

        -- Next Weather
        local nextWeather = "Unknown"
        local nextStart = "Unknown"

        local Remote = getNextWeatherRemote()

        if Remote then

            pcall(function()

                local result = Remote:InvokeServer()

                if typeof(result) == "table" then

                    nextWeather =
                        result.Weather
                        or result.weather
                        or result.NextWeather
                        or result.nextWeather
                        or "Unknown"

                    nextStart =
                        result.StartTime
                        or result.startTime
                        or result.NextStart
                        or result.nextStart
                        or result.Time
                        or result.time
                        or "Unknown"

                elseif result ~= nil then
                    nextWeather = tostring(result)
                end

            end)
        end

        -- Update GUI
        CurrentLabel.Text = "Current: " .. tostring(currentWeather)
        NextLabel.Text = "Next: " .. tostring(nextWeather)
        TimeLabel.Text = "Next Start: " .. tostring(nextStart)

        -- Check Current
        local currentMatch = getSelectedEvent(currentWeather)

        -- Check Next
        local nextMatch = getSelectedEvent(nextWeather)

        if currentMatch then

            StatusLabel.Text = "✓ AKTIV: " .. currentMatch

        elseif nextMatch then

            StatusLabel.Text = "✓ GEFUNDEN: " .. nextMatch

        else

            StatusLabel.Text = "✗ Nicht gefunden - Server Hop"

            task.wait(1)

            serverHop()

            task.wait(5)
        end

        task.wait(3)
    end
end)
```
