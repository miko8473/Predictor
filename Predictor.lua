-- Greedy Growers Meteor Hopper (100% Präzise & Zuverlässig)
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Alte GUI entfernen
pcall(function()
    if CoreGui:FindFirstChild("MeteorSnifferGui") then
        CoreGui.MeteorSnifferGui:Destroy()
    end
end)

-- Clean GUI (Aktuelles & Nächstes Wetter zur Kontrolle)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeteorSnifferGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 115)
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
local NextLbl = createLabel(36, "Nächstes Wetter: Lade...", Color3.fromRGB(100, 220, 255))
local StatusLbl = createLabel(62, "Status: Prüfe Server...", Color3.fromRGB(255, 220, 100))

local validWeathers = {
    "Misty", "Sandstorm", "Blizzard", "Acid-Rain", "Acid Rain", "Rainbow", "Meteor Shower", "Lucky River"
}

local function normalize(str)
    return tostring(str):lower():gsub("[%s_%-]+", "")
end

local latestCurrent = "Normal"
local latestNext = "Wartet..."

-- Strenger Scanner der Menüs und Infotafeln komplett ausschließt
local function scanGame()
    local detectedWeather = "Normal"
    local detectedNext = "Keins"

    pcall(function()
        if LocalPlayer:FindFirstChild("PlayerGui") then
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if gui:IsA("TextLabel") or gui:IsA("TextBox") then
                    local txt = gui.Text
                    local cleanTxt = normalize(txt)
                    
                    if not gui:IsDescendantOf(ScreenGui) and txt ~= "" then
                        -- Alles was Shop, Info, Guide, Liste oder Menü ist, knallhart ignorieren!
                        local ignore = false
                        local parentObj = gui.Parent
                        while parentObj and parentObj ~= LocalPlayer.PlayerGui do
                            local pName = parentObj.Name:lower()
                            if pName:find("shop") or pName:find("market") or pName:find("guide") or pName:find("info") or pName:find("index") or pName:find("list") or pName:find("grid") or pName:find("menu") or pName:find("pass") then
                                ignore = true
                                break
                            end
                            parentObj = parentObj.Parent
                        end
                        
                        if not ignore then
                            for _, w in ipairs(validWeathers) do
                                if cleanTxt:find(normalize(w)) then
                                    local pName = gui.Parent.Name:lower()
                                    local gName = gui.Name:lower()
                                    if pName:find("next") or gName:find("next") or pName:find("upcoming") then
                                        detectedNext = w
                                    else
                                        detectedWeather = w
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    latestCurrent = detectedWeather
    latestNext = detectedNext
end

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

-- Hauptlogik mit kurzer Einlese-Zeit
task.spawn(function()
    task.wait(5) -- Zeit zum Laden geben
    
    -- Mehrere Scans machen, um sicherzugehen, dass sich das HUD eingependelt hat
    for i = 1, 3 do
        scanGame()
        task.wait(1)
    end
    
    CurrentLbl.Text = "Aktuelles Wetter: " .. latestCurrent
    NextLbl.Text = "Nächstes Wetter: " .. latestNext
    
    -- Prüfen ob Meteor Shower (aktuell ODER nächste) da ist
    local hasMeteor = (normalize(latestCurrent) == normalize("Meteor Shower")) or (normalize(latestNext) == normalize("Meteor Shower"))
    
    if hasMeteor then
        StatusLbl.Text = "Status: METEOR GEFUNDEN! Bleibe hier!"
        StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
    else
        StatusLbl.Text = "Status: Kein Meteor, springe weiter..."
        StatusLbl.TextColor3 = Color3.fromRGB(255, 120, 120)
        task.wait(3)
        
        -- Letzter Sicherheits-Scan vor dem Hop
        scanGame()
        if (normalize(latestCurrent) == normalize("Meteor Shower")) or (normalize(latestNext) == normalize("Meteor Shower")) then
            StatusLbl.Text = "Status: METEOR GEFUNDEN! Bleibe hier!"
            StatusLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
        else
            serverHop()
        end
    end
end)
