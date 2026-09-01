-- Greedy Growers Meteor Hopper (Final Edition - Rechts-Seiten & Chance Filter)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Alte GUI entfernen, damit es keine Doppelten gibt
pcall(function()
    if CoreGui:FindFirstChild("MeteorSnifferGui") then
        CoreGui.MeteorSnifferGui:Destroy()
    end
end)

-- GUI erstellen (Sauber, minimalistisch & verschiebbar)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeteorSnifferGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 110)
MainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local function createLabel(posY, text, color)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 22)
    lbl.Position = UDim2.new(0, 10, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = MainFrame
    return lbl
end

local CurrentLbl = createLabel(12, "Aktuelles Wetter: Lade...", Color3.fromRGB(200, 200, 200))
local StatusLbl = createLabel(42, "Status: Prüfe Server...", Color3.fromRGB(255, 220, 100))

local validWeathers = {
    "Meteor Shower", "Acid Rain", "Blizzard", "Sandstorm", "Misty", "Rainbow", "Lucky River"
}

local function normalize(str)
    return tostring(str):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local latestCurrent = "Normal"

-- Server-Hop Funktion
local function serverHop()
    StatusLbl.Text = "Status: Kein Meteor -> Server Hop!"
    StatusLbl.TextColor3 = Color3.fromRGB(255, 150, 0)
    pcall(function()
        local servers = {}
        local url = "https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if success and result and result.data then
            for _, server in ipairs(result.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end
        end
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(PlaceId, servers[math.random(1, #servers)], LocalPlayer)
        else
            TeleportService:Teleport(PlaceId, LocalPlayer)
        end
    end)
end

-- Präziser Scanner: Konzentriert sich auf die rechte Bildschirmseite & Chance-Anzeige
local function scanGame()
    local detectedWeather = "Normal"

    pcall(function()
        if LocalPlayer:FindFirstChild("PlayerGui") then
            local camera = Workspace.CurrentCamera
            local screenWidth = camera and camera.ViewportSize.X or 1000
            
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextBox") then
                    local txt = gui.Text
                    local cleanTxt = normalize(txt)
                    
                    if not gui:IsDescendantOf(ScreenGui) and txt ~= "" then
                        -- Prüfen, ob das Element auf der RECHTEN Bildschirmhälfte liegt (wo das Wetter angezeigt wird)
                        local onRightSide = false
                        pcall(function()
                            if gui.AbsolutePosition.X > (screenWidth * 0.5) then
                                onRightSide = true
                            end
                        end)
                        
                        -- Auch prüfen, ob in dem Text eine Chance/Prozentangabe oder "mutate" steht
                        local hasChanceOrMutation = cleanTxt:find("%%") or cleanTxt:find("mutate") or cleanTxt:find("chance") or cleanTxt:find("seed")
                        
                        -- Shops und Menüs strikt ausschließen
                        local ignore = false
                        local parentObj = gui.Parent
                        while parentObj and parentObj ~= LocalPlayer.PlayerGui do
                            local pName = parentObj.Name:lower()
                            if pName:find("shop") or pName:find("market") or pName:find("guide") or pName:find("info") or pName:find("index") or pName:find("list") or pName:find("pass") then
                                ignore = true
                                break
                            end
                            parentObj = parentObj.Parent
                        end
                        
                        -- Wenn es rechts ist oder die Chance anzeigt und kein Shop ist:
                        if not ignore and (onRightSide or hasChanceOrMutation) then
                            for _, w in ipairs(validWeathers) do
                                local normW = normalize(w)
                                if cleanTxt:find(normW) then
                                    detectedWeather = w
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    latestCurrent = detectedWeather
end

-- Hauptlogik beim Start
task.spawn(function()
    task.wait(5) -- Kurz warten, bis das Spiel auf dem iPad geladen ist
    
    -- Ein paar Scans zum Einpendeln
    for i = 1, 3 do
        scanGame()
        task.wait(1)
    end
    
    CurrentLbl.Text = "Wetter: " .. latestCurrent
    
    -- Prüfen, ob Meteor Shower aktiv ist
    local hasMeteor = (normalize(latestCurrent) == "meteor shower")
    
    if hasMeteor then
        StatusLbl.Text = "Status: METEOR GEFUNDEN! Bleibe hier!"
        StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
    else
        StatusLbl.Text = "Status: Kein Meteor, springe weiter..."
        StatusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
        task.wait(3)
        
        -- Letzter Sicherheitscheck vor dem Hop
        scanGame()
        if (normalize(latestCurrent) == "meteor shower") then
            StatusLbl.Text = "Status: METEOR GEFUNDEN! Bleibe hier!"
            StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
        else
            serverHop()
        end
    end
end)
