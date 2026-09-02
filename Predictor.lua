--// GREEDY GROWERS
--// AUTO FARM MUTATIONS
--// EXACT NEXT WEATHER + EXACT START TIME
--// AUTO SERVER HOP

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

--==================================================
-- EVENTS
--==================================================

local EVENTS = {
    "Meteor Shower",
    "Acid Rain",
    "Blizzard",
    "Sandstorm",
    "Misty",
    "Rainbow",
    "Lucky River"
}

local Selected = {}

for _, eventName in ipairs(EVENTS) do
    Selected[eventName] = false
end

local Running = false
local Hopping = false

local LastNextWeather = nil
local LastNextTime = "--"

--==================================================
-- COLORS
--==================================================

local WHITE = Color3.fromRGB(240, 243, 248)
local GREEN = Color3.fromRGB(90, 230, 125)
local RED = Color3.fromRGB(235, 75, 75)
local YELLOW = Color3.fromRGB(230, 180, 60)
local GREY = Color3.fromRGB(120, 128, 142)

--==================================================
-- REMOVE OLD GUI
--==================================================

pcall(function()
    local old = CoreGui:FindFirstChild("GreedyGrowersAutoFarm")
    if old then
        old:Destroy()
    end
end)

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "GreedyGrowersAutoFarm"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(350, 475)
Main.Position = UDim2.new(0.5, -175, 0.5, -237)
Main.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55, 60, 72)
MainStroke.Thickness = 1
MainStroke.Transparency = 0.35
MainStroke.Parent = Main

--==================================================
-- DRAG
--==================================================

local dragging = false
local dragStart
local startPos

Main.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Main.InputEnded:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)

    if not dragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 34)
Title.Position = UDim2.fromOffset(15, 12)
Title.BackgroundTransparency = 1
Title.Text = "GREEDY GROWERS"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextColor3 = Color3.fromRGB(245, 247, 250)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -30, 0, 20)
Subtitle.Position = UDim2.fromOffset(15, 39)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "WEATHER AUTO FARM"
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextSize = 10
Subtitle.TextColor3 = Color3.fromRGB(125, 132, 145)
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Main

--==================================================
-- WEATHER CARDS
--==================================================

local function createCard(y, title)

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -30, 0, 75)
    card.Position = UDim2.fromOffset(15, y)
    card.BackgroundColor3 = Color3.fromRGB(21, 24, 31)
    card.BorderSizePixel = 0
    card.Parent = Main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 11)
    corner.Parent = card

    -- TITLE
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.fromOffset(10, 8)
    label.BackgroundTransparency = 1
    label.Text = title
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextColor3 = GREY
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    -- WEATHER NAME
    local value = Instance.new("TextLabel")
    value.Size = UDim2.fromOffset(125, 30)
    value.Position = UDim2.fromOffset(10, 28)
    value.BackgroundTransparency = 1
    value.Text = "..."
    value.Font = Enum.Font.GothamBold
    value.TextSize = 16
    value.TextColor3 = WHITE
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.TextTruncate = Enum.TextTruncate.AtEnd
    value.Parent = card

    -- FOUND / NOT FOUND
    local result = Instance.new("TextLabel")
    result.Size = UDim2.new(1, -145, 0, 30)
    result.Position = UDim2.fromOffset(140, 28)
    result.BackgroundTransparency = 1
    result.Text = ""
    result.Font = Enum.Font.GothamBold
    result.TextSize = 8
    result.TextColor3 = GREY
    result.TextXAlignment = Enum.TextXAlignment.Left
    result.TextWrapped = true
    result.Parent = card

    return card, value, result
end

local CurrentCard, CurrentValue, CurrentResult =
    createCard(70, "CURRENT WEATHER")

local NextCard, NextValue, NextResult =
    createCard(153, "NEXT WEATHER")

--==================================================
-- NEXT START TIME
--==================================================

local NextStart = Instance.new("TextLabel")
NextStart.Size = UDim2.new(1, -30, 0, 18)
NextStart.Position = UDim2.fromOffset(15, 230)
NextStart.BackgroundTransparency = 1
NextStart.Text = "Start: --"
NextStart.Font = Enum.Font.GothamMedium
NextStart.TextSize = 10
NextStart.TextColor3 = GREY
NextStart.TextXAlignment = Enum.TextXAlignment.Left
NextStart.Parent = Main

--==================================================
-- AUTOFARM HEADER
--==================================================

local AutoHeader = Instance.new("TextButton")
AutoHeader.Size = UDim2.new(1, -30, 0, 34)
AutoHeader.Position = UDim2.fromOffset(15, 253)
AutoHeader.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
AutoHeader.BorderSizePixel = 0
AutoHeader.Text = ""
AutoHeader.AutoButtonColor = false
AutoHeader.Parent = Main

local AutoCorner = Instance.new("UICorner")
AutoCorner.CornerRadius = UDim.new(0, 9)
AutoCorner.Parent = AutoHeader

local AutoTitle = Instance.new("TextLabel")
AutoTitle.Size = UDim2.new(1, -70, 1, 0)
AutoTitle.Position = UDim2.fromOffset(12, 0)
AutoTitle.BackgroundTransparency = 1
AutoTitle.Text = "AutoFarm Mutations"
AutoTitle.Font = Enum.Font.GothamBold
AutoTitle.TextSize = 12
AutoTitle.TextColor3 = Color3.fromRGB(235, 238, 244)
AutoTitle.TextXAlignment = Enum.TextXAlignment.Left
AutoTitle.Parent = AutoHeader

local CountLabel = Instance.new("TextLabel")
CountLabel.Size = UDim2.fromOffset(45, 34)
CountLabel.Position = UDim2.new(1, -70, 0, 0)
CountLabel.BackgroundTransparency = 1
CountLabel.Text = "0/7"
CountLabel.Font = Enum.Font.GothamBold
CountLabel.TextSize = 10
CountLabel.TextColor3 = Color3.fromRGB(125, 132, 145)
CountLabel.Parent = AutoHeader

local Arrow = Instance.new("TextLabel")
Arrow.Size = UDim2.fromOffset(20, 34)
Arrow.Position = UDim2.new(1, -27, 0, 0)
Arrow.BackgroundTransparency = 1
Arrow.Text = ">"
Arrow.Font = Enum.Font.GothamBold
Arrow.TextSize = 16
Arrow.TextColor3 = Color3.fromRGB(200, 205, 215)
Arrow.Parent = AutoHeader

--==================================================
-- START / STOP
--==================================================

local StartButton = Instance.new("TextButton")
StartButton.Size = UDim2.new(1, -30, 0, 38)
StartButton.Position = UDim2.fromOffset(15, 292)
StartButton.BackgroundColor3 = Color3.fromRGB(35, 39, 49)
StartButton.BorderSizePixel = 0
StartButton.Text = "START"
StartButton.Font = Enum.Font.GothamBold
StartButton.TextSize = 12
StartButton.TextColor3 = Color3.fromRGB(235, 238, 244)
StartButton.AutoButtonColor = false
StartButton.Parent = Main

local StartCorner = Instance.new("UICorner")
StartCorner.CornerRadius = UDim.new(0, 10)
StartCorner.Parent = StartButton

--==================================================
-- STATUS
--==================================================

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -60, 0, 22)
StatusText.Position = UDim2.fromOffset(37, 436)
StatusText.BackgroundTransparency = 1
StatusText.Text = "OFF"
StatusText.Font = Enum.Font.GothamBold
StatusText.TextSize = 10
StatusText.TextColor3 = Color3.fromRGB(130, 137, 150)
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.Parent = Main

local Dot = Instance.new("Frame")
Dot.Size = UDim2.fromOffset(8, 8)
Dot.Position = UDim2.fromOffset(18, 443)
Dot.BackgroundColor3 = Color3.fromRGB(220, 70, 70)
Dot.BorderSizePixel = 0
Dot.Parent = Main

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = Dot

--==================================================
-- EVENT PANEL
--==================================================

local EventPanel = Instance.new("Frame")
EventPanel.Size = UDim2.new(1, -30, 0, 138)
EventPanel.Position = UDim2.fromOffset(15, 335)
EventPanel.BackgroundColor3 = Color3.fromRGB(19, 22, 28)
EventPanel.BorderSizePixel = 0
EventPanel.Parent = Main

local EventCorner = Instance.new("UICorner")
EventCorner.CornerRadius = UDim.new(0, 10)
EventCorner.Parent = EventPanel

local AllButton = Instance.new("TextButton")
AllButton.Size = UDim2.fromOffset(48, 24)
AllButton.Position = UDim2.fromOffset(8, 7)
AllButton.BackgroundColor3 = Color3.fromRGB(34, 38, 48)
AllButton.BorderSizePixel = 0
AllButton.Text = "ALL"
AllButton.Font = Enum.Font.GothamBold
AllButton.TextSize = 9
AllButton.TextColor3 = Color3.fromRGB(220, 224, 232)
AllButton.Parent = EventPanel

local AllCorner = Instance.new("UICorner")
AllCorner.CornerRadius = UDim.new(0, 7)
AllCorner.Parent = AllButton

local NoneButton = Instance.new("TextButton")
NoneButton.Size = UDim2.fromOffset(48, 24)
NoneButton.Position = UDim2.fromOffset(62, 7)
NoneButton.BackgroundColor3 = Color3.fromRGB(34, 38, 48)
NoneButton.BorderSizePixel = 0
NoneButton.Text = "NONE"
NoneButton.Font = Enum.Font.GothamBold
NoneButton.TextSize = 9
NoneButton.TextColor3 = Color3.fromRGB(220, 224, 232)
NoneButton.Parent = EventPanel

local NoneCorner = Instance.new("UICorner")
NoneCorner.CornerRadius = UDim.new(0, 7)
NoneCorner.Parent = EventPanel

local EventScroll = Instance.new("ScrollingFrame")
EventScroll.Size = UDim2.new(1, -16, 0, 95)
EventScroll.Position = UDim2.fromOffset(8, 36)
EventScroll.BackgroundTransparency = 1
EventScroll.BorderSizePixel = 0
EventScroll.ScrollBarThickness = 3
EventScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
EventScroll.Parent = EventPanel

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 4)
Layout.Parent = EventScroll

--==================================================
-- EVENT BUTTONS
--==================================================

local EventButtons = {}

local function countSelected()

    local count = 0

    for _, eventName in ipairs(EVENTS) do
        if Selected[eventName] then
            count += 1
        end
    end

    return count
end

local function refreshButtons()

    CountLabel.Text =
        tostring(countSelected()) .. "/7"

    for eventName, button in pairs(EventButtons) do

        if Selected[eventName] then

            button.BackgroundColor3 =
                Color3.fromRGB(55, 90, 65)

            button.TextColor3 =
                Color3.fromRGB(220, 255, 225)

            button.Text =
                "✓  " .. eventName

        else

            button.BackgroundColor3 =
                Color3.fromRGB(28, 32, 40)

            button.TextColor3 =
                Color3.fromRGB(185, 190, 200)

            button.Text =
                "○  " .. eventName
        end
    end
end

for _, eventName in ipairs(EVENTS) do

    local button = Instance.new("TextButton")

    button.Size = UDim2.new(1, -4, 0, 26)
    button.BackgroundColor3 = Color3.fromRGB(28, 32, 40)
    button.BorderSizePixel = 0
    button.Text = "○  " .. eventName
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 10
    button.TextColor3 = Color3.fromRGB(185, 190, 200)
    button.AutoButtonColor = false
    button.Parent = EventScroll

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    EventButtons[eventName] = button

    button.MouseButton1Click:Connect(function()

        Selected[eventName] =
            not Selected[eventName]

        refreshButtons()
    end)
end

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()

    EventScroll.CanvasSize = UDim2.new(
        0,
        0,
        0,
        Layout.AbsoluteContentSize.Y + 5
    )
end)

AllButton.MouseButton1Click:Connect(function()

    for _, eventName in ipairs(EVENTS) do
        Selected[eventName] = true
    end

    refreshButtons()
end)

NoneButton.MouseButton1Click:Connect(function()

    for _, eventName in ipairs(EVENTS) do
        Selected[eventName] = false
    end

    refreshButtons()
end)

refreshButtons()

--==================================================
-- COLLAPSE
--==================================================

local Expanded = true

AutoHeader.MouseButton1Click:Connect(function()

    Expanded = not Expanded

    if Expanded then

        Arrow.Text = ">"
        EventPanel.Visible = true
        Main.Size = UDim2.fromOffset(350, 475)

    else

        Arrow.Text = "<"
        EventPanel.Visible = false
        Main.Size = UDim2.fromOffset(350, 335)

    end
end)

--==================================================
-- EXACT WEATHER REMOTE
--==================================================

local function getNextWeatherRemote()

    local Packages =
        ReplicatedStorage:FindFirstChild("Packages")

    if not Packages then
        return nil
    end

    local Index =
        Packages:FindFirstChild("_Index")

    if not Index then
        return nil
    end

    for _, child in ipairs(Index:GetChildren()) do

        local childName =
            string.lower(child.Name)

        local prefix = "sleitnick_knit"

        if string.sub(
            childName,
            1,
            #prefix
        ) == prefix then

            local knit =
                child:FindFirstChild("knit")

            if knit then

                local Services =
                    knit:FindFirstChild("Services")

                if Services then

                    local WeatherService =
                        Services:FindFirstChild(
                            "WeatherService"
                        )

                    if WeatherService then

                        local RF =
                            WeatherService:FindFirstChild("RF")

                        if RF then

                            local Remote =
                                RF:FindFirstChild(
                                    "GetNextWeather"
                                )

                            if Remote
                                and Remote:IsA("RemoteFunction") then

                                return Remote
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

--==================================================
-- GET CURRENT WEATHER
--==================================================

local function getCurrentWeather()

    local current =
        ReplicatedStorage:FindFirstChild(
            "CurrentWeather"
        )

    if not current then
        return "Normal"
    end

    local value

    pcall(function()

        if current:IsA("ValueBase") then
            value = current.Value
        end

    end)

    if value == nil then
        return "Normal"
    end

    local weather =
        tostring(value)

    if weather == ""
        or weather:lower() == "nil"
        or weather:lower() == "none" then

        return "Normal"
    end

    return weather
end

--==================================================
-- GET EXACT NEXT WEATHER
--==================================================

local function getNextWeather()

    local remote =
        getNextWeatherRemote()

    if not remote then
        return nil, nil
    end

    local success, result =
        pcall(function()
            return remote:InvokeServer()
        end)

    if not success then
        return nil, nil
    end

    if type(result) ~= "table" then
        return nil, nil
    end

    -- EXACT VALUES FROM THE WORKING WEATHER REMOTE
    local nextWeather =
        result.key

    local startTime =
        result.startTime

    if nextWeather ~= nil then
        nextWeather =
            tostring(nextWeather)
    end

    if startTime ~= nil then

        local numericTime =
            tonumber(startTime)

        if numericTime then

            startTime =
                os.date(
                    "%H:%M:%S",
                    numericTime
                )

        else
            startTime =
                tostring(startTime)
        end
    else
        startTime = "--"
    end

    return nextWeather, startTime
end

--==================================================
-- CHECK SELECTED WEATHER
--==================================================

local function isSelectedWeather(weather)

    if not weather then
        return false
    end

    local weatherNorm =
        tostring(weather)
            :lower()
            :gsub("^%s+", "")
            :gsub("%s+$", "")

    for _, eventName in ipairs(EVENTS) do

        local eventNorm =
            eventName
                :lower()
                :gsub("^%s+", "")
                :gsub("%s+$", "")

        if weatherNorm == eventNorm then
            return Selected[eventName] == true
        end
    end

    return false
end

--==================================================
-- UPDATE CURRENT DISPLAY
--==================================================

local function updateCurrentDisplay(current)

    CurrentValue.Text = current

    -- No weather event is currently running
    if current == "Normal" then

        CurrentValue.TextColor3 = WHITE

        if countSelected() > 0 then

            CurrentResult.Text =
                "WAS NOT FOUND BY CURRENT WEATHER"

            CurrentResult.TextColor3 = RED

        else

            CurrentResult.Text =
                "NO EVENT SELECTED"

            CurrentResult.TextColor3 = GREY
        end

        return
    end

    -- Selected event is currently active
    if isSelectedWeather(current) then

        CurrentValue.TextColor3 = GREEN

        CurrentResult.Text =
            "FOUND BY CURRENT WEATHER"

        CurrentResult.TextColor3 = GREEN

    else

        CurrentValue.TextColor3 = RED

        CurrentResult.Text =
            "WAS NOT FOUND BY CURRENT WEATHER"

        CurrentResult.TextColor3 = RED
    end
end

--==================================================
-- UPDATE NEXT DISPLAY
--==================================================

local function updateNextDisplay(nextWeather, startTime)

    if not nextWeather then

        NextValue.Text = "Lädt..."

        NextValue.TextColor3 = YELLOW

        NextResult.Text =
            "READING NEXT WEATHER..."

        NextResult.TextColor3 = YELLOW

        NextStart.Text = "Start: --"

        return
    end

    LastNextWeather = nextWeather
    LastNextTime = startTime or "--"

    NextValue.Text =
        LastNextWeather

    NextStart.Text =
        "Start: " .. LastNextTime

    if isSelectedWeather(nextWeather) then

        NextValue.TextColor3 = GREEN

        NextResult.Text =
            "FOUND BY NEXT WEATHER"

        NextResult.TextColor3 = GREEN

    else

        NextValue.TextColor3 = RED

        NextResult.Text =
            "WAS NOT FOUND BY NEXT WEATHER"

        NextResult.TextColor3 = RED
    end
end

--==================================================
-- SERVER HOP
--==================================================

local function serverHop()

    if Hopping or not Running then
        return
    end

    Hopping = true

    StatusText.Text = "HOPPING..."
    Dot.BackgroundColor3 = YELLOW

    task.spawn(function()

        local success, data =
            pcall(function()

                local url =
                    "https://games.roblox.com/v1/games/"
                    .. tostring(PlaceId)
                    .. "/servers/Public?sortOrder=Asc&limit=100"

                return HttpService:JSONDecode(
                    game:HttpGet(url)
                )
            end)

        if not success
            or not data
            or not data.data then

            StatusText.Text = "HOP FAILED"
            Dot.BackgroundColor3 = RED

            Hopping = false
            return
        end

        local servers = {}

        for _, server in ipairs(data.data) do

            if server.id
                and server.id ~= game.JobId
                and server.playing
                and server.maxPlayers
                and server.playing < server.maxPlayers then

                table.insert(
                    servers,
                    server.id
                )
            end
        end

        if #servers == 0 then

            StatusText.Text = "NO SERVER"
            Dot.BackgroundColor3 = RED

            Hopping = false
            return
        end

        local target =
            servers[
                math.random(
                    1,
                    #servers
                )
            ]

        pcall(function()

            TeleportService:
                TeleportToPlaceInstance(
                    PlaceId,
                    target,
                    LocalPlayer
                )
        end)

        task.wait(6)

        Hopping = false
    end)
end

--==================================================
-- START / STOP
--==================================================

StartButton.MouseButton1Click:Connect(function()

    if not Running then

        if countSelected() == 0 then

            StatusText.Text =
                "SELECT EVENT"

            Dot.BackgroundColor3 = YELLOW

            return
        end

        Running = true

        StartButton.Text = "STOP"

        StatusText.Text = "RUNNING"
        Dot.BackgroundColor3 = GREEN

    else

        Running = false
        Hopping = false

        StartButton.Text = "START"

        StatusText.Text = "OFF"

        Dot.BackgroundColor3 = RED
    end
end)

--==================================================
-- RIGHT SHIFT
--==================================================

UserInputService.InputBegan:Connect(function(
    input,
    processed
)

    if processed then
        return
    end

    if input.KeyCode ==
        Enum.KeyCode.RightShift then

        Main.Visible =
            not Main.Visible
    end
end)

--==================================================
-- MAIN LOOP
--==================================================

task.spawn(function()

    task.wait(2)

    while Gui.Parent do

        --==========================================
        -- CURRENT WEATHER
        --==========================================

        local current =
            getCurrentWeather()

        updateCurrentDisplay(current)

        --==========================================
        -- EXACT NEXT WEATHER
        --==========================================

        local nextWeather,
            startTime =
            getNextWeather()

        updateNextDisplay(
            nextWeather,
            startTime
        )

        --==========================================
        -- AUTO FARM DECISION
        --==========================================

        if not Running then

            StatusText.Text = "OFF"

            Dot.BackgroundColor3 =
                Color3.fromRGB(
                    220,
                    70,
                    70
                )

        elseif countSelected() == 0 then

            StatusText.Text = "NO EVENT"

            Dot.BackgroundColor3 =
                YELLOW

        elseif isSelectedWeather(current) then

            -- CURRENT TARGET FOUND
            -- STAY IN SERVER

            StatusText.Text =
                "CURRENT TARGET"

            Dot.BackgroundColor3 =
                GREEN

        elseif nextWeather
            and isSelectedWeather(nextWeather) then

            -- NEXT TARGET FOUND
            -- STAY IN SERVER

            StatusText.Text =
                "NEXT TARGET"

            Dot.BackgroundColor3 =
                GREEN

        elseif nextWeather then

            -- EXACT NEXT WEATHER IS KNOWN
            -- BUT IT IS NOT SELECTED
            -- HOP TO ANOTHER SERVER

            StatusText.Text =
                "HOPPING..."

            Dot.BackgroundColor3 =
                YELLOW

            serverHop()

        else

            -- WAIT FOR EXACT NEXT WEATHER

            StatusText.Text =
                "READING..."

            Dot.BackgroundColor3 =
                YELLOW
        end

        task.wait(2)
    end
end)
