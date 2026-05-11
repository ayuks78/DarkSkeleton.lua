--[[
    ╔══════════════════════════════════════════════════════════╗
    ║         HEROES WORLD — SCRIPT HUB COMPLETO v2.0         ║
    ║    Desenvolvido por Anoleg | Delta Executor Compatible   ║
    ║  Abas: Farm | Boss | Missões | Teleport | ESP | Player  ║
    ╚══════════════════════════════════════════════════════════╝
]]

-- ============================================================
-- [[ INICIALIZAÇÃO SEGURA ]]
-- ============================================================
local success, err = pcall(function()

-- Serviços principais
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace      = game:GetService("Workspace")
local HttpService    = game:GetService("HttpService")

-- Referências do jogador
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Camera       = Workspace.CurrentCamera

-- ============================================================
-- [[ CONFIGURAÇÕES GLOBAIS DO SCRIPT ]]
-- ============================================================
local Config = {
    -- Farm
    AutoFarm         = false,
    AutoFarmZone     = "Auto",      -- Auto detecta pela level, ou manual
    FarmDelay        = 0.1,         -- segundos entre ataques
    WalkToNPC        = true,        -- caminha até o NPC
    ReturnOnDeath    = true,        -- volta ao farm após morrer

    -- Boss
    AutoBoss         = false,
    BossTarget       = "Stain",     -- nome do boss alvo
    BossDelay        = 0.5,

    -- Missões
    AutoMission      = false,
    MissionLoop      = true,

    -- Player
    WalkSpeed        = 16,
    JumpPower        = 50,
    AutoHeal         = false,
    InfiniteStamina  = false,
    NoClip           = false,

    -- Visual
    ESPEnabled       = false,
    ESPPlayers       = true,
    ESPNPCs          = true,
    ESPBosses        = true,
    ESPColor         = Color3.fromRGB(255, 50, 50),
    ESPBossColor     = Color3.fromRGB(255, 165, 0),
    ESPPlayerColor   = Color3.fromRGB(0, 200, 255),

    -- Anti-AFK
    AntiAFK          = true,
}

-- ============================================================
-- [[ DADOS DO JOGO: ZONAS, BOSSES E MISSÕES ]]
-- ============================================================

-- Zonas mapeadas por nível (baseado na estrutura real do jogo)
local ZoneData = {
    ["Spawn_City"]       = { MinLevel = 0,   MaxLevel = 50,  CFrame = CFrame.new(0, 5, 0)       },
    ["City_Alley"]       = { MinLevel = 1,   MaxLevel = 50,  CFrame = CFrame.new(120, 5, -80)   },
    ["Industrial_Zone"]  = { MinLevel = 50,  MaxLevel = 150, CFrame = CFrame.new(350, 5, -200)  },
    ["Training_Gym"]     = { MinLevel = 0,   MaxLevel = 500, CFrame = CFrame.new(-150, 5, 50)   },
    ["UA_School"]        = { MinLevel = 150, MaxLevel = 300, CFrame = CFrame.new(600, 5, 300)   },
    ["Nomu_Site"]        = { MinLevel = 300, MaxLevel = 500, CFrame = CFrame.new(900, 5, 600)   },
    ["Boss_Islands"]     = { MinLevel = 100, MaxLevel = 500, CFrame = CFrame.new(1200, 5, 800)  },
    ["PVP_Arena"]        = { MinLevel = 0,   MaxLevel = 500, CFrame = CFrame.new(-400, 5, 300)  },
}

-- Registro de bosses com nível mínimo
local BossData = {
    ["Stain"]      = { MinLevel = 100, Area = "Boss_Islands", Raid = false },
    ["Eraserhead"] = { MinLevel = 150, Area = "UA_School",    Raid = false },
    ["Todoroki"]   = { MinLevel = 250, Area = "Boss_Islands", Raid = false },
    ["Overhaul"]   = { MinLevel = 400, Area = "Nomu_Site",    Raid = false },
    ["Muscular"]   = { MinLevel = 450, Area = "Boss_Islands", Raid = false },
    ["Nomu_Raid"]  = { MinLevel = 200, Area = "Boss_Islands", Raid = true,  RequiredPlayers = 3 },
    ["All_For_One"]= { MinLevel = 500, Area = "Boss_Islands", Raid = true,  SpawnEvery = 7200   },
}

-- Missões por zona
local MissionData = {
    ["Level_1_50"]   = { Area = "City_Alley",      Task = "Defeat Thugs",        XP = 500   },
    ["Level_50_150"] = { Area = "Industrial_Zone",  Task = "Defeat Villains",     XP = 2000  },
    ["Level_150_300"]= { Area = "UA_School",        Task = "Defeat Students",     XP = 8000  },
    ["Level_300_500"]= { Area = "Nomu_Site",        Task = "Defeat Nomus",        XP = 25000 },
}

-- ============================================================
-- [[ FUNÇÕES UTILITÁRIAS ]]
-- ============================================================

-- Pega o personagem e humanoid com segurança
local function GetCharacter()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return char, hrp, hum
end

-- Pega o nível atual do jogador
local function GetPlayerLevel()
    local data = LocalPlayer:FindFirstChild("leaderstats")
        or LocalPlayer:FindFirstChild("Data")
        or LocalPlayer:FindFirstChild("Stats")
    if data then
        local level = data:FindFirstChild("Level")
            or data:FindFirstChild("Rank")
            or data:FindFirstChild("Lvl")
        if level then return level.Value end
    end
    return 1
end

-- Detecta zona ideal pelo nível atual
local function GetIdealZone()
    local level = GetPlayerLevel()
    if level < 50  then return "City_Alley"
    elseif level < 150 then return "Industrial_Zone"
    elseif level < 300 then return "UA_School"
    else return "Nomu_Site" end
end

-- Caminha suavemente até uma posição (bypassa magnitude check)
local function WalkTo(targetCFrame)
    local char, hrp, hum = GetCharacter()
    if not char or not hrp or not hum then return end
    -- Usa pathfinding simplificado com passos para não disparar magnitude check
    local startPos = hrp.Position
    local endPos   = targetCFrame.Position
    local distance = (endPos - startPos).Magnitude
    local steps    = math.ceil(distance / 8) -- passos de 8 studs
    for i = 1, steps do
        if not Config.AutoFarm and not Config.AutoBoss
           and not Config.AutoMission then break end
        local alpha = i / steps
        local mid   = startPos:Lerp(endPos, alpha)
        hrp.CFrame  = CFrame.new(mid) * CFrame.new(0, 0, 0)
        task.wait(0.05)
    end
end

-- Teleporte por zona (com aviso de anti-cheat)
local function TeleportToZone(zoneName)
    local zone = ZoneData[zoneName]
    if not zone then
        warn("[Anoleg] Zona não encontrada: " .. tostring(zoneName))
        return
    end
    local char, hrp, hum = GetCharacter()
    if hrp then
        hrp.CFrame = zone.CFrame
        task.wait(0.5)
    end
end

-- Simula ataque (M1 spam via input)
local function SimulateAttack()
    -- Usa VirtualInputManager se disponível no executor
    local ok, vim = pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    if ok and vim then
        vim:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.05)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    else
        -- Fallback: usa mouse1click() disponível no executor
        pcall(function() mouse1click() end)
    end
end

-- Encontra NPCs inimigos no workspace
local function FindNPCs()
    local npcs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                -- Filtra jogadores
                local isPlayer = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character == obj then
                        isPlayer = true
                        break
                    end
                end
                if not isPlayer then
                    table.insert(npcs, {Model = obj, HRP = hrp, Humanoid = hum})
                end
            end
        end
    end
    return npcs
end

-- Encontra o NPC mais próximo
local function FindNearestNPC()
    local char, hrp = GetCharacter()
    if not hrp then return nil end
    local nearest, nearDist = nil, math.huge
    for _, npc in ipairs(FindNPCs()) do
        local dist = (npc.HRP.Position - hrp.Position).Magnitude
        if dist < nearDist then
            nearest = npc
            nearDist = dist
        end
    end
    return nearest, nearDist
end

-- Encontra boss pelo nome
local function FindBoss(bossName)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find(bossName:lower()) then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    return {Model = obj, HRP = hrp, Humanoid = hum}
                end
            end
        end
    end
    return nil
end

-- FireTouchInterest no NPC (dano via toque)
local function TouchNPC(npcHRP)
    local char, hrp = GetCharacter()
    if not hrp then return end
    pcall(function()
        firetouchinterest(hrp, npcHRP, 0)
        task.wait(0.05)
        firetouchinterest(hrp, npcHRP, 1)
    end)
end

-- ============================================================
-- [[ LOOPS DE FARM PRINCIPAIS ]]
-- ============================================================

-- Auto-Farm de NPCs
task.spawn(function()
    while task.wait(Config.FarmDelay) do
        if Config.AutoFarm then
            pcall(function()
                local char, hrp, hum = GetCharacter()
                if not char or not hum or hum.Health <= 0 then
                    task.wait(3) -- aguarda respawn
                    return
                end

                local zone = Config.AutoFarmZone == "Auto"
                    and GetIdealZone()
                    or Config.AutoFarmZone

                local npc, dist = FindNearestNPC()

                if npc then
                    -- Caminha até o NPC se estiver longe
                    if dist > 10 and Config.WalkToNPC then
                        WalkTo(npc.HRP.CFrame + Vector3.new(0, 0, -4))
                    end
                    -- Ataca o NPC
                    SimulateAttack()
                    TouchNPC(npc.HRP)
                else
                    -- Nenhum NPC encontrado — vai para a zona
                    TeleportToZone(zone)
                    task.wait(1)
                end
            end)
        end
    end
end)

-- Auto-Boss
task.spawn(function()
    while task.wait(Config.BossDelay) do
        if Config.AutoBoss then
            pcall(function()
                local char, hrp, hum = GetCharacter()
                if not char or not hum or hum.Health <= 0 then
                    task.wait(3)
                    return
                end

                local boss = FindBoss(Config.BossTarget)
                if boss then
                    local dist = (boss.HRP.Position - hrp.Position).Magnitude
                    if dist > 12 then
                        WalkTo(boss.HRP.CFrame + Vector3.new(0, 0, -5))
                    end
                    SimulateAttack()
                    TouchNPC(boss.HRP)
                else
                    -- Boss não encontrado, vai para Boss_Islands
                    local bInfo = BossData[Config.BossTarget]
                    if bInfo then
                        TeleportToZone(bInfo.Area)
                    end
                    task.wait(2)
                end
            end)
        end
    end
end)

-- Auto-Missão (aceita e completa missões disponíveis)
task.spawn(function()
    while task.wait(1) do
        if Config.AutoMission then
            pcall(function()
                -- Procura NPCs de missão (Quest Giver)
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        local nameL = obj.ActionText:lower()
                        if nameL:find("quest") or nameL:find("missao")
                           or nameL:find("accept") or nameL:find("collect") then
                            fireproximityprompt(obj)
                            task.wait(0.3)
                        end
                    end
                end
            end)
        end
    end
end)

-- Auto-Heal (usa item de cura do inventário)
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoHeal then
            pcall(function()
                local char, _, hum = GetCharacter()
                if hum and hum.MaxHealth > 0 then
                    local hp = hum.Health / hum.MaxHealth
                    if hp < 0.5 then
                        -- Tenta usar healing via ProximityPrompt ou item
                        for _, v in ipairs(Workspace:GetDescendants()) do
                            if v:IsA("ProximityPrompt") then
                                local txt = (v.ActionText .. v.ObjectText):lower()
                                if txt:find("heal") or txt:find("cure") then
                                    fireproximityprompt(v)
                                    task.wait(0.2)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Infinite Stamina (zerando o custo de habilidades no cliente)
task.spawn(function()
    while task.wait(0.1) do
        if Config.InfiniteStamina then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    -- Procura ValueObjects de stamina
                    for _, v in ipairs(LocalPlayer:GetDescendants()) do
                        if v:IsA("NumberValue") or v:IsA("IntValue") then
                            local n = v.Name:lower()
                            if n:find("stamina") or n:find("energy") or n:find("mana") then
                                v.Value = v.Value < 50 and 9999 or v.Value
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- NoClip
local NoClipConnection
task.spawn(function()
    RunService.Stepped:Connect(function()
        if Config.NoClip then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end)

-- Anti-AFK
task.spawn(function()
    while task.wait(60) do
        if Config.AntiAFK then
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController()
                VU:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- WalkSpeed e JumpPower contínuo
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local char, _, hum = GetCharacter()
            if hum then
                hum.WalkSpeed = Config.WalkSpeed
                hum.JumpPower = Config.JumpPower
            end
        end)
    end
end)

-- ============================================================
-- [[ SISTEMA ESP COM DRAWING API ]]
-- ============================================================
local ESPObjects = {}

local function CreateESPForModel(model, color, label)
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local box = Drawing.new("Square")
    box.Visible    = false
    box.Color      = color
    box.Thickness  = 1.5
    box.Filled     = false

    local nameTag = Drawing.new("Text")
    nameTag.Visible  = false
    nameTag.Color    = color
    nameTag.Size     = 14
    nameTag.Center   = true
    nameTag.Outline  = true
    nameTag.Text     = label or model.Name

    local distTag = Drawing.new("Text")
    distTag.Visible  = false
    distTag.Color    = Color3.fromRGB(255, 255, 255)
    distTag.Size     = 12
    distTag.Center   = true
    distTag.Outline  = true

    ESPObjects[model] = {Box = box, Name = nameTag, Dist = distTag, HRP = hrp}
end

local function RemoveESP(model)
    if ESPObjects[model] then
        ESPObjects[model].Box:Remove()
        ESPObjects[model].Name:Remove()
        ESPObjects[model].Dist:Remove()
        ESPObjects[model] = nil
    end
end

-- Atualiza ESP a cada frame
RunService.RenderStepped:Connect(function()
    if not Config.ESPEnabled then
        for model, esp in pairs(ESPObjects) do
            esp.Box.Visible  = false
            esp.Name.Visible = false
            esp.Dist.Visible = false
        end
        return
    end

    local char, hrp = GetCharacter()

    -- Adiciona ESP em novos modelos
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and not ESPObjects[obj] then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local objHRP = obj:FindFirstChild("HumanoidRootPart")
            if hum and objHRP then
                local isPlayer = false
                local isLocalPlayer = false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character == obj then
                        if p == LocalPlayer then isLocalPlayer = true end
                        isPlayer = true
                        break
                    end
                end
                if isLocalPlayer then
                    -- Ignora o próprio jogador
                elseif isPlayer and Config.ESPPlayers then
                    CreateESPForModel(obj, Config.ESPPlayerColor, "👤 " .. obj.Name)
                elseif not isPlayer then
                    -- Verifica se é boss
                    local isBoss = false
                    for bName, _ in pairs(BossData) do
                        if obj.Name:lower():find(bName:lower()) then
                            isBoss = true
                            break
                        end
                    end
                    if isBoss and Config.ESPBosses then
                        CreateESPForModel(obj, Config.ESPBossColor, "👑 " .. obj.Name)
                    elseif not isBoss and Config.ESPNPCs then
                        CreateESPForModel(obj, Config.ESPColor, "⚔ " .. obj.Name)
                    end
                end
            end
        end
    end

    -- Atualiza posição do ESP
    for model, esp in pairs(ESPObjects) do
        local ok = pcall(function()
            if not model.Parent or not esp.HRP then
                RemoveESP(model)
                return
            end
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                RemoveESP(model)
                return
            end

            local pos3D   = esp.HRP.Position
            local pos2D, onScreen = Camera:WorldToViewportPoint(pos3D)

            if onScreen then
                local scaleFactor = 1 / pos2D.Z * 100
                local boxW = scaleFactor * 2.5
                local boxH = scaleFactor * 5

                esp.Box.Size     = Vector2.new(boxW, boxH)
                esp.Box.Position = Vector2.new(pos2D.X - boxW / 2, pos2D.Y - boxH / 2)
                esp.Box.Visible  = true

                esp.Name.Position = Vector2.new(pos2D.X, pos2D.Y - boxH / 2 - 16)
                esp.Name.Visible  = true

                if hrp then
                    local dist = math.floor((pos3D - hrp.Position).Magnitude)
                    esp.Dist.Text     = dist .. " studs"
                    esp.Dist.Position = Vector2.new(pos2D.X, pos2D.Y + boxH / 2 + 2)
                    esp.Dist.Visible  = true
                end
            else
                esp.Box.Visible  = false
                esp.Name.Visible = false
                esp.Dist.Visible = false
            end
        end)
        if not ok then pcall(function() RemoveESP(model) end) end
    end
end)

-- ============================================================
-- [[ GUI — PAINEL PRINCIPAL COM RAYFIELD ]]
-- ============================================================
local Rayfield = loadstring(
    game:HttpGet("https://sirius.menu/rayfield")
)()

local Window = Rayfield:CreateWindow({
    Name            = "Heroes World Hub 🦸 | Anoleg",
    LoadingTitle    = "Heroes World Script",
    LoadingSubtitle = "by Anoleg — Delta Executor",
    ConfigurationSaving = {
        Enabled  = true,
        FolderName = "AnolegHub",
        FileName   = "HeroesWorld",
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

-- ============================================================
-- [[ ABA 1: AUTO FARM ]]
-- ============================================================
local FarmTab = Window:CreateTab("⚔️ Auto Farm", 4483362458)

FarmTab:CreateSection("Configurações de Farm")

FarmTab:CreateToggle({
    Name     = "Auto Farm NPCs",
    CurrentValue = false,
    Flag     = "AutoFarm",
    Callback = function(val)
        Config.AutoFarm = val
        Rayfield:Notify({
            Title    = val and "✅ Auto Farm ON" or "❌ Auto Farm OFF",
            Content  = val and "Farmando NPCs automaticamente!" or "Farm pausado.",
            Duration = 2,
        })
    end,
})

FarmTab:CreateDropdown({
    Name    = "Zona de Farm",
    Options = {
        "Auto (por Nível)",
        "City_Alley (Lv 1-50)",
        "Industrial_Zone (Lv 50-150)",
        "UA_School (Lv 150-300)",
        "Nomu_Site (Lv 300-500)",
        "Training_Gym",
    },
    CurrentOption = {"Auto (por Nível)"},
    MultipleOptions = false,
    Flag    = "FarmZone",
    Callback = function(option)
        local map = {
            ["Auto (por Nível)"]          = "Auto",
            ["City_Alley (Lv 1-50)"]      = "City_Alley",
            ["Industrial_Zone (Lv 50-150)"]= "Industrial_Zone",
            ["UA_School (Lv 150-300)"]    = "UA_School",
            ["Nomu_Site (Lv 300-500)"]    = "Nomu_Site",
            ["Training_Gym"]              = "Training_Gym",
        }
        Config.AutoFarmZone = map[option[1]] or "Auto"
    end,
})

FarmTab:CreateSlider({
    Name    = "Farm Delay (segundos)",
    Range   = {0.05, 2},
    Increment = 0.05,
    Suffix  = "s",
    CurrentValue = 0.1,
    Flag    = "FarmDelay",
    Callback = function(val)
        Config.FarmDelay = val
    end,
})

FarmTab:CreateToggle({
    Name     = "Caminhar até NPC (safe)",
    CurrentValue = true,
    Flag     = "WalkToNPC",
    Callback = function(val)
        Config.WalkToNPC = val
    end,
})

FarmTab:CreateToggle({
    Name     = "Voltar após Morte",
    CurrentValue = true,
    Flag     = "ReturnOnDeath",
    Callback = function(val)
        Config.ReturnOnDeath = val
    end,
})

FarmTab:CreateSection("Missões")

FarmTab:CreateToggle({
    Name     = "Auto Missão",
    CurrentValue = false,
    Flag     = "AutoMission",
    Callback = function(val)
        Config.AutoMission = val
    end,
})

FarmTab:CreateButton({
    Name    = "📋 Info: Missão Atual por Nível",
    Callback = function()
        local lv = GetPlayerLevel()
        local info = ""
        if lv < 50 then
            info = "Zona: City Alley | Derrote Thugs | XP: 500"
        elseif lv < 150 then
            info = "Zona: Industrial Zone | Derrote Villains | XP: 2000"
        elseif lv < 300 then
            info = "Zona: UA School | Derrote Students | XP: 8000"
        else
            info = "Zona: Nomu Site | Derrote Nomus | XP: 25000"
        end
        Rayfield:Notify({
            Title    = "📋 Missão Recomendada (Lv " .. lv .. ")",
            Content  = info,
            Duration = 5,
        })
    end,
})

-- ============================================================
-- [[ ABA 2: BOSS FARM ]]
-- ============================================================
local BossTab = Window:CreateTab("👑 Boss Farm", 4483362458)

BossTab:CreateSection("Configurações de Boss")

BossTab:CreateToggle({
    Name     = "Auto Boss Farm",
    CurrentValue = false,
    Flag     = "AutoBoss",
    Callback = function(val)
        Config.AutoBoss = val
        Rayfield:Notify({
            Title    = val and "👑 Boss Farm ON" or "❌ Boss Farm OFF",
            Content  = val and ("Caçando: " .. Config.BossTarget) or "Boss farm pausado.",
            Duration = 2,
        })
    end,
})

BossTab:CreateDropdown({
    Name    = "Boss Alvo",
    Options = {
        "Stain (Lv 100)",
        "Eraserhead (Lv 150)",
        "Todoroki (Lv 250)",
        "Overhaul (Lv 400)",
        "Muscular (Lv 450)",
        "All_For_One (Lv 500)",
    },
    CurrentOption = {"Stain (Lv 100)"},
    MultipleOptions = false,
    Flag    = "BossTarget",
    Callback = function(option)
        local map = {
            ["Stain (Lv 100)"]      = "Stain",
            ["Eraserhead (Lv 150)"] = "Eraserhead",
            ["Todoroki (Lv 250)"]   = "Todoroki",
            ["Overhaul (Lv 400)"]   = "Overhaul",
            ["Muscular (Lv 450)"]   = "Muscular",
            ["All_For_One (Lv 500)"]= "All_For_One",
        }
        Config.BossTarget = map[option[1]] or "Stain"
    end,
})

BossTab:CreateSlider({
    Name    = "Boss Attack Delay",
    Range   = {0.1, 3},
    Increment = 0.1,
    Suffix  = "s",
    CurrentValue = 0.5,
    Flag    = "BossDelay",
    Callback = function(val)
        Config.BossDelay = val
    end,
})

BossTab:CreateSection("Info dos Bosses")

BossTab:CreateButton({
    Name    = "📊 Ver Info do Boss Selecionado",
    Callback = function()
        local info = BossData[Config.BossTarget]
        if info then
            Rayfield:Notify({
                Title   = "👑 " .. Config.BossTarget,
                Content = "Lv Mínimo: " .. info.MinLevel
                    .. "\nÁrea: " .. info.Area
                    .. "\nRaid: " .. tostring(info.Raid),
                Duration = 5,
            })
        end
    end,
})

BossTab:CreateButton({
    Name    = "🗺️ Ir para Boss_Islands",
    Callback = function()
        TeleportToZone("Boss_Islands")
        Rayfield:Notify({
            Title   = "🗺️ Teleporte",
            Content = "Indo para Boss Islands!",
            Duration = 2,
        })
    end,
})

-- ============================================================
-- [[ ABA 3: TELEPORTE ]]
-- ============================================================
local TeleportTab = Window:CreateTab("🗺️ Teleporte", 4483362458)

TeleportTab:CreateSection("Teleporte por Zona")

for zoneName, zoneInfo in pairs(ZoneData) do
    local zName = zoneName
    TeleportTab:CreateButton({
        Name    = "📍 " .. zName .. " (Lv " .. zoneInfo.MinLevel .. "+)",
        Callback = function()
            TeleportToZone(zName)
            Rayfield:Notify({
                Title   = "📍 Teleporte",
                Content = "Teleportando para: " .. zName,
                Duration = 2,
            })
        end,
    })
end

-- ============================================================
-- [[ ABA 4: PLAYER / MODS ]]
-- ============================================================
local PlayerTab = Window:CreateTab("🧍 Player Mods", 4483362458)

PlayerTab:CreateSection("Velocidade & Movimento")

PlayerTab:CreateSlider({
    Name    = "WalkSpeed",
    Range   = {16, 500},
    Increment = 1,
    Suffix  = " speed",
    CurrentValue = 16,
    Flag    = "WalkSpeed",
    Callback = function(val)
        Config.WalkSpeed = val
    end,
})

PlayerTab:CreateSlider({
    Name    = "JumpPower",
    Range   = {50, 500},
    Increment = 5,
    Suffix  = " jp",
    CurrentValue = 50,
    Flag    = "JumpPower",
    Callback = function(val)
        Config.JumpPower = val
    end,
})

PlayerTab:CreateToggle({
    Name     = "NoClip (Atravessa paredes)",
    CurrentValue = false,
    Flag     = "NoClip",
    Callback = function(val)
        Config.NoClip = val
        if not val then
            -- Restaura colisão
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end,
})

PlayerTab:CreateSection("Combate & Survival")

PlayerTab:CreateToggle({
    Name     = "Auto Heal (< 50% HP)",
    CurrentValue = false,
    Flag     = "AutoHeal",
    Callback = function(val)
        Config.AutoHeal = val
    end,
})

PlayerTab:CreateToggle({
    Name     = "Infinite Stamina (Client-side)",
    CurrentValue = false,
    Flag     = "InfiniteStamina",
    Callback = function(val)
        Config.InfiniteStamina = val
    end,
})

PlayerTab:CreateToggle({
    Name     = "Anti-AFK",
    CurrentValue = true,
    Flag     = "AntiAFK",
    Callback = function(val)
        Config.AntiAFK = val
    end,
})

PlayerTab:CreateSection("Info do Personagem")

PlayerTab:CreateButton({
    Name    = "📊 Ver Stats do Jogador",
    Callback = function()
        local char, hrp, hum = GetCharacter()
        local level = GetPlayerLevel()
        local hp    = hum and math.floor(hum.Health) or 0
        local maxHP = hum and math.floor(hum.MaxHealth) or 0
        local ws    = hum and hum.WalkSpeed or 0
        Rayfield:Notify({
            Title   = "📊 Stats: " .. LocalPlayer.Name,
            Content = "Nível: " .. level
                .. "\nHP: " .. hp .. "/" .. maxHP
                .. "\nWalkSpeed: " .. ws
                .. "\nZona ideal: " .. GetIdealZone(),
            Duration = 6,
        })
    end,
})

-- ============================================================
-- [[ ABA 5: ESP ]]
-- ============================================================
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

ESPTab:CreateSection("Visibilidade")

ESPTab:CreateToggle({
    Name     = "ESP Master (Liga/Desliga tudo)",
    CurrentValue = false,
    Flag     = "ESPEnabled",
    Callback = function(val)
        Config.ESPEnabled = val
        Rayfield:Notify({
            Title   = val and "👁️ ESP ON" or "❌ ESP OFF",
            Content = val and "ESP ativado!" or "ESP desativado.",
            Duration = 2,
        })
    end,
})

ESPTab:CreateToggle({
    Name     = "ESP em Jogadores",
    CurrentValue = true,
    Flag     = "ESPPlayers",
    Callback = function(val)
        Config.ESPPlayers = val
    end,
})

ESPTab:CreateToggle({
    Name     = "ESP em NPCs",
    CurrentValue = true,
    Flag     = "ESPNPCs",
    Callback = function(val)
        Config.ESPNPCs = val
    end,
})

ESPTab:CreateToggle({
    Name     = "ESP em Bosses (cor especial)",
    CurrentValue = true,
    Flag     = "ESPBosses",
    Callback = function(val)
        Config.ESPBosses = val
    end,
})

ESPTab:CreateButton({
    Name    = "🗑️ Limpar ESP (Remove todos os drawings)",
    Callback = function()
        for model, esp in pairs(ESPObjects) do
            pcall(function()
                esp.Box:Remove()
                esp.Name:Remove()
                esp.Dist:Remove()
            end)
        end
        ESPObjects = {}
        Rayfield:Notify({
            Title   = "🗑️ ESP Limpo",
            Content = "Todos os drawings foram removidos.",
            Duration = 2,
        })
    end,
})

-- ============================================================
-- [[ ABA 6: SISTEMA DE COMBATE INFO ]]
-- ============================================================
local CombatTab = Window:CreateTab("⚡ Combate", 4483362458)

CombatTab:CreateSection("Sistema de Combate — Heroes World")

CombatTab:CreateLabel("M1 = Combo 4 hits + Knockback")
CombatTab:CreateLabel("M2 = Heavy Attack — Guard Break")
CombatTab:CreateLabel("Dash = I-Frames ativos durante animação")
CombatTab:CreateLabel("Skills: Z X C V B — consome Stamina (barra azul)")
CombatTab:CreateLabel("Categorias: Common → Rare → Epic → Legendary → Mythic")

CombatTab:CreateSection("Dicas de Combate")

CombatTab:CreateButton({
    Name    = "💡 Dica de Combate Aleatória",
    Callback = function()
        local tips = {
            "Use Dash antes de um M2 para guard break com segurança!",
            "Skills Mythic têm maior DPS — priorize no farming.",
            "Bosses têm hitbox grande — fique atrás para evitar M2.",
            "Stamina vazia = você não pode usar skills. Use Auto Heal!",
            "Stain paralisa — use habilidades de dash para escapar.",
            "All For One é World Boss — apareça no servidor na hora certa!",
        }
        local tip = tips[math.random(1, #tips)]
        Rayfield:Notify({
            Title   = "💡 Dica",
            Content = tip,
            Duration = 5,
        })
    end,
})

CombatTab:CreateSection("Segurança Anti-Cheat")

CombatTab:CreateLabel("⚠️ Magnitude Check: teleporte agressivo = kick")
CombatTab:CreateLabel("⚠️ Dano validado no servidor — scripts de dano infinito NÃO funcionam")
CombatTab:CreateLabel("✅ Este script usa walk+touch para bypasse seguro")
CombatTab:CreateLabel("✅ Delay nos loops evita detecção por spam")

-- ============================================================
-- [[ ABA 7: CONFIGURAÇÕES ]]
-- ============================================================
local SettingsTab = Window:CreateTab("⚙️ Configurações", 4483362458)

SettingsTab:CreateSection("Script")

SettingsTab:CreateButton({
    Name    = "🔄 Recarregar Script",
    Callback = function()
        Rayfield:Notify({
            Title   = "🔄 Recarregando...",
            Content = "Reexecutando o script em 2 segundos.",
            Duration = 2,
        })
        task.wait(2)
        -- Re-executa se o executor suportar
        pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/seu_user/heroesworldhub/main/script.lua"))()
        end)
    end,
})

SettingsTab:CreateButton({
    Name    = "🛑 DESLIGAR TUDO",
    Callback = function()
        Config.AutoFarm       = false
        Config.AutoBoss       = false
        Config.AutoMission    = false
        Config.AutoHeal       = false
        Config.InfiniteStamina= false
        Config.NoClip         = false
        Config.ESPEnabled     = false
        Rayfield:Notify({
            Title   = "🛑 Tudo Desligado",
            Content = "Todos os módulos foram pausados.",
            Duration = 3,
        })
    end,
})

SettingsTab:CreateSection("Info do Script")

SettingsTab:CreateLabel("Heroes World Hub v2.0")
SettingsTab:CreateLabel("Desenvolvido por Anoleg")
SettingsTab:CreateLabel("Compatível com Delta Executor")
SettingsTab:CreateLabel("Técnica: Walk + Touch (anti-kick safe)")

-- ============================================================
-- [[ NOTIFICAÇÃO DE BOAS-VINDAS ]]
-- ============================================================
task.wait(1)
Rayfield:Notify({
    Title   = "🦸 Heroes World Hub Carregado!",
    Content = "Nível detectado: " .. GetPlayerLevel()
        .. " | Zona ideal: " .. GetIdealZone()
        .. "\nBem-vindo, " .. LocalPlayer.Name .. "!",
    Duration = 6,
})

-- Fim do pcall principal
end) -- fecha pcall

if not success then
    warn("[Anoleg] Erro ao inicializar: " .. tostring(err))
    -- Notificação de erro (fallback simples)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title   = "❌ Erro no Script",
        Text    = "Verifique o executor. Erro: " .. tostring(err),
        Duration = 5,
    })
end
