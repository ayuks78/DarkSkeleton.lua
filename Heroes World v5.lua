--[[
╔══════════════════════════════════════════════════════════════════╗
║         MY HERO MANIA — DARK HUB v5.0                          ║
║   Remotes reais | Fly equilibrado | Raid completa               ║
║   Main | Farm | Farm Proteção | Boss | Raid | Teleporte         ║
║   Player | ESP | Config                                          ║
║   Compatível: Delta, Fluxus, Solara, Arceus X, Codex            ║
╚══════════════════════════════════════════════════════════════════╝
]]

-- Guard dupla execução
if _G.MHM_Running then
    _G.MHM_Running = false
    task.wait(1.5)
end
_G.MHM_Running = true

-- ============================================================
-- SERVIÇOS
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser       = game:GetService("VirtualUser")
local Stats             = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ============================================================
-- REMOTES REAIS
-- ============================================================
local Events = ReplicatedStorage:WaitForChild("Package"):WaitForChild("Events")
local CombatRemote     = Events:WaitForChild("Combat")
local SkillRemote      = Events:WaitForChild("Skill")
local QuestRemote      = Events:WaitForChild("GetQuest")
local TeleportToQuest  = Events:WaitForChild("TeleportToQuest")
local TeleportToRaid   = Events:WaitForChild("TeleportToRaid")

-- ============================================================
-- CONFIGURAÇÕES GLOBAIS
-- ============================================================
local Config = {
    -- Farm Normal
    AutoFarm        = false,
    AutoFarmZone    = "Auto",
    FarmDelay       = 0.15,
    FarmRange       = 12,
    WalkToNPC       = true,
    ReturnOnDeath   = true,
    UseSkill        = false,
    SkillIndex      = "1",
    ComboIndex      = 1,
    ComboSpeed      = "Normal", -- Lento / Normal / Rápido / Super Rápido

    -- Farm Proteção
    AutoFarmProt    = false,
    ProtDelay       = 0.2,
    ProtRange       = 20,
    ProtRetreat     = 30,
    ProtAnimThresh  = 1.2,
    ProtWaiting     = false,

    -- Boss
    AutoBoss        = false,
    BossTarget      = "Bomb",
    BossDelay       = 0.2,

    -- Raid
    AutoRaid        = false,
    RaidName        = "Backstreet Raid",
    RaidDifficulty  = "Easy",
    RaidAutoStart   = false,
    RaidAutoKill    = false,
    RaidKillDelay   = 0.1,
    RaidHitboxSize  = 15,
    RaidInProgress  = false,

    -- Missão
    AutoMission     = false,
    AutoTeleportQuest = false,

    -- Fly
    FlyEnabled      = false,
    FlySpeed        = 1.0,
    FlyHeight       = 15,

    -- Player
    WalkSpeed       = 16,
    JumpPower       = 50,
    AutoHeal        = false,
    HealThreshold   = 0.5,
    NoClip          = false,
    AntiAFK         = true,

    -- ESP
    ESPEnabled      = false,
    ESPPlayers      = true,
    ESPNPCs         = true,
    ESPBosses       = true,
    ESPColor        = Color3.fromRGB(255,60,60),
    ESPBossColor    = Color3.fromRGB(255,165,0),
    ESPPlayerColor  = Color3.fromRGB(0,200,255),
}

-- ============================================================
-- DADOS DO JOGO
-- ============================================================
local ComboSpeedMap = {
    ["Lento"]       = 0.4,
    ["Normal"]      = 0.15,
    ["Rápido"]      = 0.08,
    ["Super Rápido"]= 0.04,
}

local RaidData = {
    { Name="Incursão Backstreet",          Remote="Backstreet Raid",        MinLevel=20  },
    { Name="Arena Sobrevivência (Herói)",  Remote="USJ Raid (Hero)",        MinLevel=60  },
    { Name="Arena Sobrevivência (Vilão)",  Remote="USJ Raid (Villain)",     MinLevel=60  },
    { Name="Renovar Bossfight",            Remote="Nomu Raid",              MinLevel=100 },
    { Name="Salada (100%) Chefes",         Remote="Salad Raid",             MinLevel=100 },
    { Name="Bomba (100%) Bossfight",       Remote="Bomb Raid",              MinLevel=120 },
    { Name="Raid Infernal",                Remote="Infernal Raid",          MinLevel=200 },
    { Name="Chefe Lagarto Monstro",        Remote="Monster Lizard Raid",    MinLevel=250 },
    { Name="Tudo é meu ataque",            Remote="All For One Raid",       MinLevel=300 },
}

local QuestData = {
    { Name="Thugs",           Level=0,   Remote="Thugs",            XP=250,     Money=100  },
    { Name="Criminals",       Level=10,  Remote="Criminals",        XP=1200,    Money=150  },
    { Name="Weak Villains",   Level=15,  Remote="Weak Villains",    XP=2500,    Money=200  },
    { Name="Proteinman",      Level=30,  Remote="Proteinman Hero",  XP=8500,    Money=700  },
    { Name="B-Rank Villains", Level=40,  Remote="B-Rank Villains",  XP=15000,   Money=1000 },
    { Name="A-Rank Villains", Level=75,  Remote="A-Rank Villains",  XP=33000,   Money=1800 },
    { Name="Pestos",          Level=105, Remote="Pestos",           XP=55000,   Money=2402 },
    { Name="Carbonaras",      Level=115, Remote="Carbonaras",       XP=65000,   Money=3000 },
    { Name="Squid Inks",      Level=125, Remote="Squid Inks",       XP=86000,   Money=3500 },
    { Name="Bomb",            Level=140, Remote="Bomb",             XP=100000,  Money=4000 },
    { Name="Salad (5%)",      Level=170, Remote="Salad (5%)",       XP=150000,  Money=4500 },
    { Name="Icy Hot",         Level=200, Remote="Icy Hot",          XP=200000,  Money=5000 },
    { Name="Exploding Boss",  Level=300, Remote="Exploding Boss",   XP=1200000, Money=5000 },
}

local BossNames = {
    "Bomb","Salad","Icy Hot","Proteinman","Uravity",
    "Lida","Exploding Boss","Mr. Cool","Speed","Monster Lizard"
}

local ZoneData = {
    ["Spawn"]          = { MinLevel=0,   CFrame=CFrame.new(0,5,0)        },
    ["Thugs_Area"]     = { MinLevel=0,   CFrame=CFrame.new(120,5,-80)    },
    ["Criminals_Area"] = { MinLevel=10,  CFrame=CFrame.new(200,5,-120)   },
    ["Villains_Area"]  = { MinLevel=15,  CFrame=CFrame.new(300,5,-180)   },
    ["BRank_Area"]     = { MinLevel=40,  CFrame=CFrame.new(450,5,-250)   },
    ["ARank_Area"]     = { MinLevel=75,  CFrame=CFrame.new(600,5,-350)   },
    ["Pesto_Area"]     = { MinLevel=105, CFrame=CFrame.new(750,5,-450)   },
    ["Carbonara_Area"] = { MinLevel=115, CFrame=CFrame.new(900,5,-500)   },
    ["SquidInk_Area"]  = { MinLevel=125, CFrame=CFrame.new(1050,5,-600)  },
    ["Boss_Area"]      = { MinLevel=140, CFrame=CFrame.new(1200,5,-700)  },
}

-- ============================================================
-- UTILITÁRIOS
-- ============================================================
local function GetCharacter()
    local char = LocalPlayer.Character
    if not char then return nil,nil,nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return nil,nil,nil end
    return char,hrp,hum
end

local function IsAlive()
    local _,_,hum = GetCharacter()
    return hum ~= nil and hum.Health > 0
end

local function GetPlayerLevel()
    for _, fname in ipairs({"leaderstats","Data","Stats","PlayerData"}) do
        local f = LocalPlayer:FindFirstChild(fname)
        if f then
            for _, vname in ipairs({"Level","Rank","Lvl","LVL"}) do
                local v = f:FindFirstChild(vname)
                if v then return tonumber(v.Value) or 1 end
            end
        end
    end
    return 1
end

local function GetFPS()
    return math.floor(1 / RunService.RenderStepped:Wait())
end

local function GetGameTime()
    local t = math.floor(workspace.DistributedGameTime)
    local m = math.floor(t/60)
    local s = t % 60
    return string.format("%02d:%02d", m, s)
end

local function GetBestQuest()
    local lv = GetPlayerLevel()
    local best = QuestData[1]
    for _, q in ipairs(QuestData) do
        if lv >= q.Level then best = q end
    end
    return best
end

local function GetBestRaid()
    local lv = GetPlayerLevel()
    local best = RaidData[1]
    for _, r in ipairs(RaidData) do
        if lv >= r.MinLevel then best = r end
    end
    return best
end

local function GetIdealZone()
    local lv = GetPlayerLevel()
    if lv < 10   then return "Thugs_Area"
    elseif lv < 15   then return "Criminals_Area"
    elseif lv < 40   then return "Villains_Area"
    elseif lv < 75   then return "BRank_Area"
    elseif lv < 105  then return "ARank_Area"
    elseif lv < 115  then return "Pesto_Area"
    elseif lv < 125  then return "Carbonara_Area"
    elseif lv < 140  then return "SquidInk_Area"
    else return "Boss_Area" end
end

local function SafeTeleport(cf)
    local _,hrp = GetCharacter()
    if not hrp then return end
    local off = Vector3.new(math.random(-2,2),0,math.random(-2,2))
    hrp.CFrame = cf + off
    task.wait(0.4)
end

local function TeleportToZone(zoneName)
    local z = ZoneData[zoneName]
    if z then SafeTeleport(z.CFrame) end
end

local function WalkToPosition(pos, timeout)
    local _,hrp,hum = GetCharacter()
    if not hum then return end
    timeout = timeout or 8
    hum:MoveTo(pos)
    local t = 0
    while t < timeout do
        if not _G.MHM_Running then return end
        if (hrp.Position - pos).Magnitude < 7 then break end
        t = t + 0.1
        task.wait(0.1)
    end
end

-- ============================================================
-- SISTEMA DE FLY EQUILIBRADO
-- ============================================================
local FlyParts = {}

local function EnableFly()
    local char, hrp, hum = GetCharacter()
    if not hrp then return end

    -- Remove fly anterior se existir
    for _, p in ipairs(FlyParts) do pcall(function() p:Destroy() end) end
    FlyParts = {}

    hum.PlatformStand = true

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9999,9999,9999)
    bg.P = 9999
    bg.D = 100
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9999,9999,9999)
    bv.Velocity = Vector3.new(0,0,0)
    bv.Parent = hrp

    table.insert(FlyParts, bg)
    table.insert(FlyParts, bv)

    -- Loop de controle do fly
    task.spawn(function()
        while Config.FlyEnabled and _G.MHM_Running do
            local c, h = GetCharacter()
            if not h or not h:FindFirstChild("HumanoidRootPart") then break end
            local hrp2 = h.Parent:FindFirstChild("HumanoidRootPart")
            if not hrp2 then break end

            -- Mantém a altura configurada
            local targetY = hrp2.Position.Y
            local currentY = hrp2.Position.Y

            -- Sobe suavemente até a altura alvo
            local targetPos = Vector3.new(
                hrp2.Position.X,
                math.max(currentY, Config.FlyHeight),
                hrp2.Position.Z
            )

            if bv and bv.Parent then
                -- Velocidade equilibrada — não muito rápido para não kickar
                local dir = (targetPos - hrp2.Position)
                if dir.Magnitude > 1 then
                    bv.Velocity = dir.Unit * (Config.FlySpeed * 20)
                else
                    bv.Velocity = Vector3.new(0,0,0)
                end
                bg.CFrame = Camera.CFrame
            end
            task.wait(0.05)
        end
        -- Desativa fly
        for _, p in ipairs(FlyParts) do pcall(function() p:Destroy() end) end
        FlyParts = {}
        local _,_,hum2 = GetCharacter()
        if hum2 then hum2.PlatformStand = false end
    end)
end

local function DisableFly()
    Config.FlyEnabled = false
    for _, p in ipairs(FlyParts) do pcall(function() p:Destroy() end) end
    FlyParts = {}
    local _,_,hum = GetCharacter()
    if hum then hum.PlatformStand = false end
end

-- ============================================================
-- SISTEMA DE ATAQUE
-- ============================================================
local function DoCombo()
    pcall(function()
        local delay = ComboSpeedMap[Config.ComboSpeed] or 0.15
        CombatRemote:FireServer(Config.ComboIndex)
        Config.ComboIndex = (Config.ComboIndex % 4) + 1
    end)
end

local function DoSkill(targetHRP)
    if not Config.UseSkill then return end
    pcall(function()
        local mhit = targetHRP and CFrame.new(targetHRP.Position) or CFrame.new(0,0,0)
        SkillRemote:InvokeServer(Config.SkillIndex, "Down", {
            ["MouseHit"] = mhit,
            ["Mobile"]   = true,
        })
    end)
end

local function AttackTarget(targetModel, targetHRP)
    DoCombo()
    DoSkill(targetHRP)
    local _,hrp = GetCharacter()
    if hrp and targetHRP then
        pcall(function()
            firetouchinterest(hrp, targetHRP, 0)
            task.wait(0.02)
            firetouchinterest(hrp, targetHRP, 1)
        end)
    end
end

-- ============================================================
-- HITBOX EXPAND (para Auto Kill da Raid)
-- ============================================================
local function SetHitbox(size)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Size = Vector3.new(size, size, size) end
end

local function ResetHitbox()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Size = Vector3.new(2,2,1) end
end

-- ============================================================
-- DETECÇÃO DE NPCs
-- ============================================================
local function IsPlayerModel(model)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == model then return true end
    end
    return false
end

local function IsBossModel(model)
    for _, b in ipairs(BossNames) do
        if model.Name:lower():find(b:lower()) then return true end
    end
    return false
end

local function GetAllNPCs()
    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LocalPlayer.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 and not IsPlayerModel(obj) then
                table.insert(list, {Model=obj, HRP=hrp, Hum=hum})
            end
        end
    end
    return list
end

local function GetNearestNPC(excludeBosses)
    local _,hrp = GetCharacter()
    if not hrp then return nil end
    local nearest, nearDist = nil, math.huge
    for _, npc in ipairs(GetAllNPCs()) do
        if excludeBosses and IsBossModel(npc.Model) then continue end
        local d = (npc.HRP.Position - hrp.Position).Magnitude
        if d < nearDist then nearest = npc nearDist = d end
    end
    return nearest, nearDist
end

local function FindBoss(bossName)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:lower():find(bossName:lower()) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                return {Model=obj, HRP=hrp, Hum=hum}
            end
        end
    end
    return nil
end

-- ============================================================
-- DETECÇÃO DE CINEMÁTICA (Farm Proteção + Boss)
-- ============================================================
local function HasCinematic(model)
    local animator = model:FindFirstChildOfClass("Animator")
        or (model:FindFirstChildOfClass("Humanoid")
            and model:FindFirstChildOfClass("Humanoid")
               :FindFirstChildOfClass("Animator"))
    if not animator then return false end
    local ok, tracks = pcall(function()
        return animator:GetPlayingAnimationTracks()
    end)
    if not ok then return false end
    for _, t in ipairs(tracks) do
        if t.Length >= Config.ProtAnimThresh then return true end
    end
    return false
end

local function HasSpecialState(hum)
    if not hum then return false end
    local s = hum:GetState()
    return s == Enum.HumanoidStateType.Physics
        or s == Enum.HumanoidStateType.FallingDown
        or s == Enum.HumanoidStateType.Ragdoll
end

local function RetreatFrom(targetHRP)
    local _,hrp,hum = GetCharacter()
    if not hrp or not targetHRP then return end
    local dir = (hrp.Position - targetHRP.Position).Unit
    local pos = hrp.Position + (dir * Config.ProtRetreat)
    hum:MoveTo(Vector3.new(pos.X, hrp.Position.Y, pos.Z))
    task.wait(1.5)
end

local function WaitAnimEnd(model)
    Config.ProtWaiting = true
    local t = 0
    while t < 10 do
        if not _G.MHM_Running then break end
        if not HasCinematic(model) then break end
        t = t + 0.3
        task.wait(0.3)
    end
    Config.ProtWaiting = false
end

-- ============================================================
-- MÓDULO 1: AUTO FARM NORMAL
-- ============================================================
task.spawn(function()
    while _G.MHM_Running do
        local delay = ComboSpeedMap[Config.ComboSpeed] or 0.15
        task.wait(math.max(Config.FarmDelay, delay))
        if not Config.AutoFarm then continue end
        if not IsAlive() then
            task.wait(3)
            if Config.ReturnOnDeath then
                TeleportToZone(Config.AutoFarmZone=="Auto" and GetIdealZone() or Config.AutoFarmZone)
            end
            continue
        end
        pcall(function()
            local npc, dist = GetNearestNPC(true)
            if npc then
                if dist > Config.FarmRange and Config.WalkToNPC then
                    WalkToPosition(npc.HRP.Position + Vector3.new(0,0,-3), 5)
                end
                AttackTarget(npc.Model, npc.HRP)
            else
                local zone = Config.AutoFarmZone=="Auto" and GetIdealZone() or Config.AutoFarmZone
                TeleportToZone(zone)
                task.wait(1.5)
            end
        end)
    end
end)

-- ============================================================
-- MÓDULO 2: AUTO FARM PROTEÇÃO (NPCs e Bosses com cinemática)
-- ============================================================
task.spawn(function()
    while _G.MHM_Running do
        task.wait(Config.ProtDelay)
        if not Config.AutoFarmProt then continue end
        if not IsAlive() then task.wait(3) continue end
        pcall(function()
            local _,hrp = GetCharacter()
            -- Busca NPC ou Boss mais próximo
            local target = GetNearestNPC(false) -- inclui bosses
            if not target then
                TeleportToZone(GetIdealZone())
                task.wait(1.5)
                return
            end
            local dist = (target.HRP.Position - hrp.Position).Magnitude
            -- Detecta cinemática ou estado especial
            if HasCinematic(target.Model) or HasSpecialState(target.Hum) then
                RetreatFrom(target.HRP)
                WaitAnimEnd(target.Model)
                return
            end
            -- Mantém distância segura
            if dist > Config.ProtRange then
                local dir = (target.HRP.Position - hrp.Position).Unit
                local safePos = target.HRP.Position - (dir * (Config.ProtRange - 4))
                WalkToPosition(Vector3.new(safePos.X, hrp.Position.Y, safePos.Z), 6)
            elseif dist < 8 then
                local dir = (hrp.Position - target.HRP.Position).Unit
                WalkToPosition(hrp.Position + (dir * 8), 2)
                return
            end
            DoSkill(target.HRP)
            DoCombo()
        end)
    end
end)

-- ============================================================
-- MÓDULO 3: AUTO BOSS
-- ============================================================
task.spawn(function()
    while _G.MHM_Running do
        task.wait(Config.BossDelay)
        if not Config.AutoBoss then continue end
        if not IsAlive() then task.wait(3) continue end
        pcall(function()
            local boss = FindBoss(Config.BossTarget)
            local _,hrp = GetCharacter()
            if not boss then
                TeleportToZone("Boss_Area")
                task.wait(2)
                return
            end
            local dist = (boss.HRP.Position - hrp.Position).Magnitude
            if dist > 16 then
                WalkToPosition(boss.HRP.Position + Vector3.new(0,0,-5), 8)
            end
            AttackTarget(boss.Model, boss.HRP)
        end)
    end
end)

-- ============================================================
-- MÓDULO 4: AUTO RAID
-- ============================================================
-- Detecta quando entrou na raid (mapa muda)
local raidMapConnection
local function DetectRaidStart(callback)
    if raidMapConnection then
        pcall(function() raidMapConnection:Disconnect() end)
    end
    raidMapConnection = Workspace.ChildAdded:Connect(function(child)
        if child.Name:lower():find("raid") or child.Name:lower():find("map") then
            task.wait(2) -- aguarda mapa carregar
            callback()
        end
    end)
end

task.spawn(function()
    while _G.MHM_Running do
        task.wait(0.5)
        if not Config.AutoRaid or Config.RaidInProgress then continue end
        if not IsAlive() then task.wait(3) continue end

        pcall(function()
            -- Inicia a raid pelo remote real
            Config.RaidInProgress = true
            TeleportToRaid:InvokeServer(Config.RaidName, Config.RaidDifficulty)
            task.wait(5) -- aguarda teleporte para o mapa da raid

            -- Ativa hitbox expandida se Auto Kill ligado
            if Config.RaidAutoKill then
                SetHitbox(Config.RaidHitboxSize)
            end

            -- Farm dentro da raid — ataca todos os NPCs
            local raidTimeout = 0
            while raidTimeout < 300 and _G.MHM_Running and Config.AutoRaid do
                task.wait(Config.RaidKillDelay)
                if not IsAlive() then
                    task.wait(3)
                    break
                end

                local npcs = GetAllNPCs()
                if #npcs == 0 then
                    task.wait(3)
                    raidTimeout = raidTimeout + 3
                    -- Verifica se raid terminou
                    if raidTimeout > 30 then break end
                else
                    raidTimeout = 0 -- reseta timeout quando tem NPCs
                    -- Ordena por distância e ataca
                    local _,hrp = GetCharacter()
                    if hrp then
                        table.sort(npcs, function(a,b)
                            return (a.HRP.Position-hrp.Position).Magnitude
                                 < (b.HRP.Position-hrp.Position).Magnitude
                        end)
                        for i = 1, math.min(5, #npcs) do
                            local npc = npcs[i]
                            if npc.Hum.Health > 0 then
                                local dist = (npc.HRP.Position - hrp.Position).Magnitude
                                if dist > 10 then
                                    WalkToPosition(npc.HRP.Position + Vector3.new(0,0,-3), 4)
                                end
                                AttackTarget(npc.Model, npc.HRP)
                                task.wait(Config.RaidKillDelay)
                            end
                        end
                    end
                end
            end

            -- Fim da raid — reseta
            ResetHitbox()
            Config.RaidInProgress = false
            task.wait(5) -- aguarda voltar ao mapa principal

            -- Reinicia raid automaticamente se Auto Raid ainda ligado
        end)
    end
end)

-- ============================================================
-- MÓDULO 5: AUTO MISSÃO
-- ============================================================
task.spawn(function()
    while _G.MHM_Running do
        task.wait(2)
        if not Config.AutoMission then continue end
        if not IsAlive() then continue end
        pcall(function()
            local quest = GetBestQuest()
            QuestRemote:InvokeServer(quest.Remote)
            -- Teleporte automático para zona da missão
            if Config.AutoTeleportQuest then
                TeleportToQuest:InvokeServer()
                task.wait(2)
            end
            local npc, dist = GetNearestNPC(true)
            if npc then
                if dist > Config.FarmRange then
                    WalkToPosition(npc.HRP.Position + Vector3.new(0,0,-3), 5)
                end
                AttackTarget(npc.Model, npc.HRP)
            else
                TeleportToZone(GetIdealZone())
                task.wait(1)
            end
        end)
    end
end)

-- ============================================================
-- MÓDULO 6: NOCLIP
-- ============================================================
RunService.Stepped:Connect(function()
    if not Config.NoClip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- ============================================================
-- MÓDULO 7: WALKSPEED + JUMPOWER
-- ============================================================
task.spawn(function()
    while _G.MHM_Running do
        task.wait(0.5)
        pcall(function()
            local _,_,hum = GetCharacter()
            if hum then
                hum.WalkSpeed = Config.WalkSpeed
                hum.JumpPower = Config.JumpPower
            end
        end)
    end
end)

-- ============================================================
-- MÓDULO 8: AUTO HEAL
-- ============================================================
task.spawn(function()
    while _G.MHM_Running do
        task.wait(0.5)
        if not Config.AutoHeal then continue end
        pcall(function()
            local _,_,hum = GetCharacter()
            if not hum then return end
            if (hum.Health/hum.MaxHealth) < Config.HealThreshold then
                for _, v in ipairs(Workspace:GetDescendants()) do
                    if v:IsA("ProximityPrompt") then
                        local t = (v.ActionText..v.ObjectText):lower()
                        if t:find("heal") or t:find("cure") then
                            fireproximityprompt(v)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end)
    end
end)

-- ============================================================
-- MÓDULO 9: ANTI-AFK
-- ============================================================
task.spawn(function()
    while _G.MHM_Running do
        task.wait(55)
        if Config.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end
end)

-- ============================================================
-- MÓDULO 10: ESP
-- ============================================================
local ESPObjects = {}

local function NewESP(model, color, label)
    if ESPObjects[model] then return end
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local box = Drawing.new("Square")
    box.Visible=false box.Color=color box.Thickness=1.5 box.Filled=false
    local nameTxt = Drawing.new("Text")
    nameTxt.Visible=false nameTxt.Color=color nameTxt.Size=14
    nameTxt.Center=true nameTxt.Outline=true nameTxt.Text=label or model.Name
    local distTxt = Drawing.new("Text")
    distTxt.Visible=false distTxt.Color=Color3.fromRGB(255,255,255)
    distTxt.Size=11 distTxt.Center=true distTxt.Outline=true
    ESPObjects[model]={Box=box,Name=nameTxt,Dist=distTxt,HRP=hrp}
    model.AncestryChanged:Connect(function()
        if not model.Parent then
            pcall(function() box:Remove() nameTxt:Remove() distTxt:Remove() end)
            ESPObjects[model]=nil
        end
    end)
end

local function RemoveESP(model)
    local e=ESPObjects[model]
    if not e then return end
    pcall(function() e.Box:Remove() e.Name:Remove() e.Dist:Remove() end)
    ESPObjects[model]=nil
end

local function PopulateESP()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj~=LocalPlayer.Character then
            local hum=obj:FindFirstChildOfClass("Humanoid")
            local hrp=obj:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health>0 then
                local isP=false
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character==obj then
                        if p~=LocalPlayer and Config.ESPPlayers then
                            NewESP(obj,Config.ESPPlayerColor,"👤 "..p.Name)
                        end
                        isP=true break
                    end
                end
                if not isP then
                    if IsBossModel(obj) and Config.ESPBosses then
                        NewESP(obj,Config.ESPBossColor,"👑 "..obj.Name)
                    elseif Config.ESPNPCs then
                        NewESP(obj,Config.ESPColor,"⚔ "..obj.Name)
                    end
                end
            end
        end
    end
end

Workspace.DescendantAdded:Connect(function(obj)
    if not Config.ESPEnabled or not obj:IsA("Model") then return end
    task.wait(0.1)
    local hum=obj:FindFirstChildOfClass("Humanoid")
    if not hum or not obj:FindFirstChild("HumanoidRootPart") then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character==obj then
            if p~=LocalPlayer and Config.ESPPlayers then
                NewESP(obj,Config.ESPPlayerColor,"👤 "..p.Name)
            end
            return
        end
    end
    if IsBossModel(obj) and Config.ESPBosses then
        NewESP(obj,Config.ESPBossColor,"👑 "..obj.Name)
    elseif Config.ESPNPCs then
        NewESP(obj,Config.ESPColor,"⚔ "..obj.Name)
    end
end)

RunService.RenderStepped:Connect(function()
    local _,hrp=GetCharacter()
    for model,esp in pairs(ESPObjects) do
        if not Config.ESPEnabled then
            esp.Box.Visible=false esp.Name.Visible=false esp.Dist.Visible=false
        else
            pcall(function()
                if not model.Parent then RemoveESP(model) return end
                local hum=model:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health<=0 then RemoveESP(model) return end
                local v2,onScreen=Camera:WorldToViewportPoint(esp.HRP.Position)
                if onScreen then
                    local s=1/v2.Z*100
                    local bW,bH=s*2.5,s*5
                    esp.Box.Size=Vector2.new(bW,bH)
                    esp.Box.Position=Vector2.new(v2.X-bW/2,v2.Y-bH/2)
                    esp.Box.Visible=true
                    esp.Name.Position=Vector2.new(v2.X,v2.Y-bH/2-16)
                    esp.Name.Visible=true
                    if hrp then
                        local d=math.floor((esp.HRP.Position-hrp.Position).Magnitude)
                        esp.Dist.Text=d.." studs"
                        esp.Dist.Position=Vector2.new(v2.X,v2.Y+bH/2+2)
                        esp.Dist.Visible=true
                    end
                else
                    esp.Box.Visible=false esp.Name.Visible=false esp.Dist.Visible=false
                end
            end)
        end
    end
end)

-- ============================================================
-- GUI — RAYFIELD
-- ============================================================
local Rayfield
local rfOk, rfErr = pcall(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not rfOk then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title="MHM Hub",Text="Erro Rayfield: "..tostring(rfErr),Duration=5
        })
    end)
    return
end

-- Notificação imediata de carregamento
Rayfield:Notify({
    Title   = "⏳ My Hero Mania Hub",
    Content = "Carregando módulos...",
    Duration= 2,
})

local Window = Rayfield:CreateWindow({
    Name            = "My Hero Mania — Dark Hub 🦸 v5.0",
    LoadingTitle    = "Dark Hub v5.0",
    LoadingSubtitle = "Remotes reais | Fly | Raid | Proteção",
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "DarkHub_MHM",
        FileName   = "DarkHubv5",
    },
    Discord  = { Enabled=false },
    KeySystem = false,
})

-- ============================================================
-- ABA 1: MAIN
-- ============================================================
local MainTab = Window:CreateTab("🏠 Main", 4483362458)

MainTab:CreateSection("Informações do Jogador")

MainTab:CreateButton({
    Name="📊 Status Completo",
    Callback=function()
        local _,_,hum = GetCharacter()
        local lv  = GetPlayerLevel()
        local hp  = hum and math.floor(hum.Health) or 0
        local mhp = hum and math.floor(hum.MaxHealth) or 0
        local q   = GetBestQuest()
        local r   = GetBestRaid()
        local fps = GetFPS()
        local gt  = GetGameTime()
        Rayfield:Notify({
            Title   = "📊 "..LocalPlayer.Name,
            Content = "Nível: "..lv
                .."\nHP: "..hp.."/"..mhp
                .."\nFPS: "..fps
                .."\nTempo: "..gt
                .."\nZona ideal: "..GetIdealZone()
                .."\nMissão ideal: "..q.Name
                .."\nRaid ideal: "..r.Name,
            Duration= 7,
        })
    end,
})

MainTab:CreateButton({
    Name="🎮 FPS Atual",
    Callback=function()
        Rayfield:Notify({
            Title="🎮 FPS",Content="FPS: "..GetFPS(),Duration=2,
        })
    end,
})

MainTab:CreateButton({
    Name="⏱️ Tempo de Jogo",
    Callback=function()
        Rayfield:Notify({
            Title="⏱️ Tempo",Content="Tempo no servidor: "..GetGameTime(),Duration=2,
        })
    end,
})

MainTab:CreateSection("⚡ Velocidade do Soco")

MainTab:CreateDropdown({
    Name="Velocidade do Ataque",
    Options={"Lento","Normal","Rápido","Super Rápido"},
    CurrentOption={"Normal"}, MultipleOptions=false, Flag="ComboSpeed",
    Callback=function(opt)
        Config.ComboSpeed = opt[1] or "Normal"
        Config.FarmDelay  = ComboSpeedMap[Config.ComboSpeed] or 0.15
        Rayfield:Notify({
            Title="⚡ Velocidade: "..Config.ComboSpeed,
            Content="Delay: "..Config.FarmDelay.."s",
            Duration=2,
        })
    end,
})

MainTab:CreateSlider({
    Name="Delay Manual do Soco (override)",
    Range={0.04,2}, Increment=0.01, Suffix="s", CurrentValue=0.15, Flag="FarmDelayM",
    Callback=function(v) Config.FarmDelay=v end,
})

MainTab:CreateSection("🕊️ Fly")

MainTab:CreateToggle({
    Name="Fly (velocidade equilibrada — sem kick)",
    CurrentValue=false, Flag="FlyEnabled",
    Callback=function(v)
        Config.FlyEnabled=v
        if v then EnableFly()
        else DisableFly() end
        Rayfield:Notify({
            Title=v and "🕊️ Fly ON" or "❌ Fly OFF",
            Content=v and "Velocidade: "..Config.FlySpeed or "Voar desativado.",
            Duration=2,
        })
    end,
})

MainTab:CreateSlider({
    Name="Velocidade do Fly (1.0 = seguro)",
    Range={0.5,3}, Increment=0.1, Suffix="x", CurrentValue=1.0, Flag="FlySpeed",
    Callback=function(v)
        Config.FlySpeed=v
    end,
})

MainTab:CreateSlider({
    Name="Altura do Fly (studs)",
    Range={5,60}, Increment=1, Suffix=" st", CurrentValue=15, Flag="FlyHeight",
    Callback=function(v) Config.FlyHeight=v end,
})

MainTab:CreateSection("📏 Distâncias")

MainTab:CreateSlider({
    Name="Farm Range — distância para atacar NPC",
    Range={4,50}, Increment=1, Suffix=" st", CurrentValue=12, Flag="FarmRangeM",
    Callback=function(v) Config.FarmRange=v end,
})

MainTab:CreateSlider({
    Name="Proteção Range — distância segura",
    Range={8,50}, Increment=1, Suffix=" st", CurrentValue=20, Flag="ProtRangeM",
    Callback=function(v) Config.ProtRange=v end,
})

MainTab:CreateSlider({
    Name="Recuo — distância ao detectar cinemática",
    Range={10,60}, Increment=2, Suffix=" st", CurrentValue=30, Flag="ProtRetreatM",
    Callback=function(v) Config.ProtRetreat=v end,
})

-- ============================================================
-- ABA 2: AUTO FARM
-- ============================================================
local FarmTab = Window:CreateTab("⚔️ Auto Farm", 4483362458)

FarmTab:CreateSection("Farm Normal — NPCs por Missão/Nível")

FarmTab:CreateToggle({
    Name="Auto Farm",
    CurrentValue=false, Flag="AutoFarm",
    Callback=function(v)
        Config.AutoFarm=v
        Rayfield:Notify({
            Title=v and "⚔️ Auto Farm ON" or "❌ Farm OFF",
            Content=v and "Farmando zona: "..GetIdealZone() or "Farm pausado.",
            Duration=2,
        })
    end,
})

FarmTab:CreateDropdown({
    Name="Zona de Farm",
    Options={
        "Auto (por Nível)",
        "Thugs (Lv 0+)",
        "Criminals (Lv 10+)",
        "Weak Villains (Lv 15+)",
        "B-Rank (Lv 40+)",
        "A-Rank (Lv 75+)",
        "Pestos (Lv 105+)",
        "Carbonaras (Lv 115+)",
        "Squid Inks (Lv 125+)",
        "Boss Area (Lv 140+)",
    },
    CurrentOption={"Auto (por Nível)"}, MultipleOptions=false, Flag="FarmZone",
    Callback=function(opt)
        local map={
            ["Auto (por Nível)"]        ="Auto",
            ["Thugs (Lv 0+)"]           ="Thugs_Area",
            ["Criminals (Lv 10+)"]      ="Criminals_Area",
            ["Weak Villains (Lv 15+)"]  ="Villains_Area",
            ["B-Rank (Lv 40+)"]         ="BRank_Area",
            ["A-Rank (Lv 75+)"]         ="ARank_Area",
            ["Pestos (Lv 105+)"]        ="Pesto_Area",
            ["Carbonaras (Lv 115+)"]    ="Carbonara_Area",
            ["Squid Inks (Lv 125+)"]    ="SquidInk_Area",
            ["Boss Area (Lv 140+)"]     ="Boss_Area",
        }
        Config.AutoFarmZone=map[opt[1]] or "Auto"
    end,
})

FarmTab:CreateToggle({
    Name="Usar Skill no Farm", CurrentValue=false, Flag="UseSkill",
    Callback=function(v) Config.UseSkill=v end,
})

FarmTab:CreateDropdown({
    Name="Slot da Skill",
    Options={"1 — Z","2 — X","3 — C","4 — V"},
    CurrentOption={"1 — Z"}, MultipleOptions=false, Flag="SkillSlot",
    Callback=function(opt)
        local map={["1 — Z"]="1",["2 — X"]="2",["3 — C"]="3",["4 — V"]="4"}
        Config.SkillIndex=map[opt[1]] or "1"
    end,
})

FarmTab:CreateToggle({
    Name="Caminhar até NPC (MoveTo)", CurrentValue=true, Flag="WalkToNPC",
    Callback=function(v) Config.WalkToNPC=v end,
})

FarmTab:CreateToggle({
    Name="Voltar após Morte", CurrentValue=true, Flag="ReturnDeath",
    Callback=function(v) Config.ReturnOnDeath=v end,
})

FarmTab:CreateSection("Missões")

FarmTab:CreateToggle({
    Name="Auto Missão (aceita missão pelo nível)", CurrentValue=false, Flag="AutoMission",
    Callback=function(v)
        Config.AutoMission=v
        if v then
            local q=GetBestQuest()
            Rayfield:Notify({
                Title="📋 Missão: "..q.Name,
                Content="XP: "..q.XP.." | $"..q.Money,
                Duration=3,
            })
        end
    end,
})

FarmTab:CreateToggle({
    Name="Auto Teleporte para Missão (TeleportToQuest)",
    CurrentValue=false, Flag="AutoTpQuest",
    Callback=function(v) Config.AutoTeleportQuest=v end,
})

FarmTab:CreateButton({
    Name="📋 Melhor Missão para meu Nível",
    Callback=function()
        local lv=GetPlayerLevel()
        local q=GetBestQuest()
        Rayfield:Notify({
            Title="📋 Nível "..lv.." — "..q.Name,
            Content="Level req: "..q.Level
                .."\nXP: "..q.XP
                .."\n$: "..q.Money,
            Duration=5,
        })
    end,
})

-- ============================================================
-- ABA 3: FARM PROTEÇÃO
-- ============================================================
local ProtTab = Window:CreateTab("🛡️ Farm Proteção", 4483362458)

ProtTab:CreateSection("Farm Inteligente — Anti Cinemática")

ProtTab:CreateLabel("✅ Funciona em NPCs comuns E Bosses")
ProtTab:CreateLabel("✅ Detecta skill/cinemática e recua automaticamente")
ProtTab:CreateLabel("✅ Segue nível do player igual ao Farm Normal")
ProtTab:CreateLabel("✅ Ataca de distância segura com Skill + Soco")

ProtTab:CreateToggle({
    Name="Farm Proteção (detecta cinemática e recua)",
    CurrentValue=false, Flag="AutoFarmProt",
    Callback=function(v)
        Config.AutoFarmProt=v
        Rayfield:Notify({
            Title=v and "🛡️ Farm Proteção ON" or "❌ Proteção OFF",
            Content=v and "Recuando de cinemáticas automaticamente!" or "Proteção pausada.",
            Duration=2,
        })
    end,
})

ProtTab:CreateSlider({
    Name="Threshold de Cinemática (duração mínima)",
    Range={0.5,5}, Increment=0.1, Suffix="s", CurrentValue=1.2, Flag="AnimThresh",
    Callback=function(v) Config.ProtAnimThresh=v end,
})

ProtTab:CreateButton({
    Name="📊 Status da Proteção",
    Callback=function()
        local _,hrp=GetCharacter()
        local npc=GetNearestNPC(false)
        local info="Nenhum alvo próximo."
        if npc and hrp then
            local dist=math.floor((npc.HRP.Position-hrp.Position).Magnitude)
            local cine=HasCinematic(npc.Model)
            local spec=HasSpecialState(npc.Hum)
            info="Alvo: "..npc.Model.Name
                .."\nDistância: "..dist.." studs"
                .."\nCinemática: "..(cine and "⚠️ SIM" or "✅ Não")
                .."\nEstado especial: "..(spec and "⚠️ SIM" or "✅ Não")
                .."\nAguardando: "..(Config.ProtWaiting and "⏳ Sim" or "Não")
        end
        Rayfield:Notify({Title="🛡️ Status Proteção",Content=info,Duration=5})
    end,
})

-- ============================================================
-- ABA 4: BOSS
-- ============================================================
local BossTab = Window:CreateTab("👑 Boss", 4483362458)

BossTab:CreateSection("Auto Boss Farm")

BossTab:CreateToggle({
    Name="Auto Boss",
    CurrentValue=false, Flag="AutoBoss",
    Callback=function(v)
        Config.AutoBoss=v
        Rayfield:Notify({
            Title=v and "👑 Boss ON" or "❌ Boss OFF",
            Content=v and "Caçando: "..Config.BossTarget or "Boss pausado.",
            Duration=2,
        })
    end,
})

BossTab:CreateDropdown({
    Name="Boss Alvo",
    Options={
        "Bomb (Lv 140)",
        "Salad (Lv 170)",
        "Icy Hot (Lv 200)",
        "Exploding Boss (Lv 300)",
        "Proteinman (Lv 30)",
        "Uravity (Lv 60)",
        "Lida (Lv 90)",
        "Mr. Cool (Lv 20)",
        "Monster Lizard (Lv 250)",
    },
    CurrentOption={"Bomb (Lv 140)"}, MultipleOptions=false, Flag="BossTarget",
    Callback=function(opt)
        local map={
            ["Bomb (Lv 140)"]           ="Bomb",
            ["Salad (Lv 170)"]          ="Salad",
            ["Icy Hot (Lv 200)"]        ="Icy Hot",
            ["Exploding Boss (Lv 300)"] ="Exploding Boss",
            ["Proteinman (Lv 30)"]      ="Proteinman",
            ["Uravity (Lv 60)"]         ="Uravity",
            ["Lida (Lv 90)"]            ="Lida",
            ["Mr. Cool (Lv 20)"]        ="Mr. Cool",
            ["Monster Lizard (Lv 250)"] ="Monster Lizard",
        }
        Config.BossTarget=map[opt[1]] or "Bomb"
    end,
})

BossTab:CreateSlider({
    Name="Boss Attack Delay",
    Range={0.05,2}, Increment=0.05, Suffix="s", CurrentValue=0.2, Flag="BossDelay",
    Callback=function(v) Config.BossDelay=v end,
})

BossTab:CreateLabel("💡 Dica: Ative Farm Proteção junto com Boss")
BossTab:CreateLabel("para recuar automaticamente das cinemáticas!")

BossTab:CreateSection("Teleporte")

BossTab:CreateButton({
    Name="📍 Ir para Boss Area",
    Callback=function()
        TeleportToZone("Boss_Area")
        Rayfield:Notify({Title="📍 Teleporte",Content="Indo para Boss Area!",Duration=2})
    end,
})

-- ============================================================
-- ABA 5: RAID
-- ============================================================
local RaidTab = Window:CreateTab("⚡ Raid", 4483362458)

RaidTab:CreateSection("Auto Raid — Início Automático")

RaidTab:CreateLabel("ℹ️ Auto Raid inicia a raid, teleporta,")
RaidTab:CreateLabel("faz o farm dentro e reinicia automaticamente.")
RaidTab:CreateLabel("Selecione a Raid e Dificuldade antes de ligar.")

RaidTab:CreateToggle({
    Name="Auto Raid (completo — inicia + farm + reinicia)",
    CurrentValue=false, Flag="AutoRaid",
    Callback=function(v)
        Config.AutoRaid=v
        Config.RaidInProgress=false
        Rayfield:Notify({
            Title=v and "⚡ Auto Raid ON" or "❌ Raid OFF",
            Content=v and "Raid: "..Config.RaidName.." | "..Config.RaidDifficulty or "Raid pausada.",
            Duration=3,
        })
    end,
})

RaidTab:CreateSection("Escolha da Raid")

RaidTab:CreateDropdown({
    Name="Selecionar Raid",
    Options={
        "Incursão Backstreet (Lv 20+)",
        "Arena Sobrevivência Herói (Lv 60+)",
        "Arena Sobrevivência Vilão (Lv 60+)",
        "Renovar Bossfight (Lv 100+)",
        "Salada 100% Chefes (Lv 100+)",
        "Bomba 100% Bossfight (Lv 120+)",
        "Raid Infernal (Lv 200+)",
        "Chefe Lagarto Monstro (Lv 250+)",
        "Tudo é meu ataque (Lv 300+)",
    },
    CurrentOption={"Incursão Backstreet (Lv 20+)"},
    MultipleOptions=false, Flag="RaidSelect",
    Callback=function(opt)
        local map={
            ["Incursão Backstreet (Lv 20+)"]        ="Backstreet Raid",
            ["Arena Sobrevivência Herói (Lv 60+)"]  ="USJ Raid (Hero)",
            ["Arena Sobrevivência Vilão (Lv 60+)"]  ="USJ Raid (Villain)",
            ["Renovar Bossfight (Lv 100+)"]         ="Nomu Raid",
            ["Salada 100% Chefes (Lv 100+)"]        ="Salad Raid",
            ["Bomba 100% Bossfight (Lv 120+)"]      ="Bomb Raid",
            ["Raid Infernal (Lv 200+)"]              ="Infernal Raid",
            ["Chefe Lagarto Monstro (Lv 250+)"]     ="Monster Lizard Raid",
            ["Tudo é meu ataque (Lv 300+)"]         ="All For One Raid",
        }
        Config.RaidName=map[opt[1]] or "Backstreet Raid"
    end,
})

RaidTab:CreateDropdown({
    Name="Dificuldade",
    Options={"Easy","Medium","Hard"},
    CurrentOption={"Easy"}, MultipleOptions=false, Flag="RaidDiff",
    Callback=function(opt)
        Config.RaidDifficulty=opt[1] or "Easy"
    end,
})

RaidTab:CreateButton({
    Name="▶️ Iniciar Raid Agora (manual)",
    Callback=function()
        pcall(function()
            TeleportToRaid:InvokeServer(Config.RaidName, Config.RaidDifficulty)
        end)
        Rayfield:Notify({
            Title="⚡ Iniciando Raid",
            Content=Config.RaidName.." | "..Config.RaidDifficulty,
            Duration=3,
        })
    end,
})

RaidTab:CreateButton({
    Name="📊 Melhor Raid para meu Nível",
    Callback=function()
        local r=GetBestRaid()
        Rayfield:Notify({
            Title="⚡ Raid Ideal — Lv "..GetPlayerLevel(),
            Content="Raid: "..r.Name.."\nNível req: "..r.MinLevel,
            Duration=4,
        })
    end,
})

RaidTab:CreateSection("Auto Kill — Farm Otimizado na Raid")

RaidTab:CreateLabel("✅ Auto Kill funciona DENTRO da Raid")
RaidTab:CreateLabel("✅ Expande hitbox para eliminar NPCs mais rápido")
RaidTab:CreateLabel("✅ Recompensas são dadas normalmente pelo servidor")
RaidTab:CreateLabel("⚠️ Auto Kill só ativa quando Auto Raid estiver ON")

RaidTab:CreateToggle({
    Name="Auto Kill (hitbox expandida — só na Raid)",
    CurrentValue=false, Flag="RaidAutoKill",
    Callback=function(v)
        Config.RaidAutoKill=v
        if not v then ResetHitbox() end
        Rayfield:Notify({
            Title=v and "💀 Auto Kill ON" or "❌ Auto Kill OFF",
            Content=v and "Hitbox: "..Config.RaidHitboxSize.." | NPCs morrem rápido!" or "Hitbox resetada.",
            Duration=2,
        })
    end,
})

RaidTab:CreateSlider({
    Name="Tamanho da Hitbox (Auto Kill)",
    Range={5,50}, Increment=1, Suffix=" sz", CurrentValue=15, Flag="RaidHitbox",
    Callback=function(v)
        Config.RaidHitboxSize=v
        if Config.RaidAutoKill and Config.RaidInProgress then
            SetHitbox(v)
        end
    end,
})

RaidTab:CreateSlider({
    Name="Delay entre kills na Raid",
    Range={0.05,1}, Increment=0.05, Suffix="s", CurrentValue=0.1, Flag="RaidDelay",
    Callback=function(v) Config.RaidKillDelay=v end,
})

RaidTab:CreateSection("Status da Raid")

RaidTab:CreateButton({
    Name="📊 Status Atual da Raid",
    Callback=function()
        Rayfield:Notify({
            Title="⚡ Status Raid",
            Content="Raid: "..Config.RaidName
                .."\nDificuldade: "..Config.RaidDifficulty
                .."\nAuto Raid: "..(Config.AutoRaid and "✅ ON" or "❌ OFF")
                .."\nEm progresso: "..(Config.RaidInProgress and "⚔️ Sim" or "Não")
                .."\nAuto Kill: "..(Config.RaidAutoKill and "💀 ON" or "❌ OFF")
                .."\nHitbox: "..Config.RaidHitboxSize,
            Duration=5,
        })
    end,
})

-- ============================================================
-- ABA 6: TELEPORTE
-- ============================================================
local TpTab = Window:CreateTab("🗺️ Teleporte", 4483362458)

TpTab:CreateSection("Zonas do Mapa")

local zoneOrder={
    "Spawn","Thugs_Area","Criminals_Area","Villains_Area",
    "BRank_Area","ARank_Area","Pesto_Area","Carbonara_Area",
    "SquidInk_Area","Boss_Area"
}
for _, zName in ipairs(zoneOrder) do
    local z=ZoneData[zName]
    local display=zName:gsub("_"," ")
    TpTab:CreateButton({
        Name="📍 "..display.." (Lv "..z.MinLevel.."+)",
        Callback=function()
            TeleportToZone(zName)
            Rayfield:Notify({Title="📍 Teleporte",Content=display,Duration=2})
        end,
    })
end

TpTab:CreateSection("Missões e Raid")

TpTab:CreateButton({
    Name="📋 Teleportar para Missão (TeleportToQuest)",
    Callback=function()
        pcall(function() TeleportToQuest:InvokeServer() end)
        Rayfield:Notify({Title="📋 TP Missão",Content="Teleportando para zona da missão!",Duration=2})
    end,
})

for _, r in ipairs(RaidData) do
    local rd=r
    TpTab:CreateButton({
        Name="⚡ "..rd.Name.." (Lv "..rd.MinLevel.."+)",
        Callback=function()
            pcall(function()
                TeleportToRaid:InvokeServer(rd.Remote, Config.RaidDifficulty)
            end)
            Rayfield:Notify({Title="⚡ Raid",Content=rd.Name,Duration=2})
        end,
    })
end

-- ============================================================
-- ABA 7: PLAYER
-- ============================================================
local PlayerTab = Window:CreateTab("🧍 Player", 4483362458)

PlayerTab:CreateSection("Movimento")

PlayerTab:CreateSlider({
    Name="JumpPower", Range={50,500}, Increment=5,
    Suffix=" jp", CurrentValue=50, Flag="JumpPower",
    Callback=function(v) Config.JumpPower=v end,
})

PlayerTab:CreateToggle({
    Name="NoClip (atravessa paredes — testado OK)",
    CurrentValue=false, Flag="NoClip",
    Callback=function(v)
        Config.NoClip=v
        if not v then
            local char=LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide=true end
                end
            end
        end
    end,
})

PlayerTab:CreateSection("Survival")

PlayerTab:CreateToggle({
    Name="Auto Heal", CurrentValue=false, Flag="AutoHeal",
    Callback=function(v) Config.AutoHeal=v end,
})

PlayerTab:CreateSlider({
    Name="Heal quando HP < (%)", Range={10,90}, Increment=5,
    Suffix="%", CurrentValue=50, Flag="HealThresh",
    Callback=function(v) Config.HealThreshold=v/100 end,
})

PlayerTab:CreateToggle({
    Name="Anti-AFK", CurrentValue=true, Flag="AntiAFK",
    Callback=function(v) Config.AntiAFK=v end,
})

PlayerTab:CreateSection("Info")

PlayerTab:CreateButton({
    Name="📊 Ver Stats Completos",
    Callback=function()
        local _,_,hum=GetCharacter()
        local lv=GetPlayerLevel()
        local q=GetBestQuest()
        local r=GetBestRaid()
        Rayfield:Notify({
            Title="📊 "..LocalPlayer.Name.." | Lv "..lv,
            Content="HP: "..math.floor(hum and hum.Health or 0)
                    .."/"..math.floor(hum and hum.MaxHealth or 0)
                .."\nFPS: "..GetFPS()
                .."\nZona: "..GetIdealZone()
                .."\nMissão: "..q.Name
                .."\nRaid: "..r.Name,
            Duration=6,
        })
    end,
})

-- ============================================================
-- ABA 8: ESP
-- ============================================================
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

ESPTab:CreateSection("Visibilidade")

ESPTab:CreateToggle({
    Name="ESP Master", CurrentValue=false, Flag="ESPMaster",
    Callback=function(v)
        Config.ESPEnabled=v
        if v then PopulateESP() end
        Rayfield:Notify({
            Title=v and "👁️ ESP ON" or "❌ ESP OFF",
            Content=v and "ESP ativo!" or "ESP desligado.",
            Duration=2,
        })
    end,
})

ESPTab:CreateToggle({
    Name="ESP — Jogadores", CurrentValue=true, Flag="ESPPlayers",
    Callback=function(v) Config.ESPPlayers=v end,
})

ESPTab:CreateToggle({
    Name="ESP — NPCs", CurrentValue=true, Flag="ESPNPCs",
    Callback=function(v) Config.ESPNPCs=v end,
})

ESPTab:CreateToggle({
    Name="ESP — Bosses", CurrentValue=true, Flag="ESPBosses",
    Callback=function(v) Config.ESPBosses=v end,
})

ESPTab:CreateButton({
    Name="🗑️ Limpar Drawings",
    Callback=function()
        for model,esp in pairs(ESPObjects) do
            pcall(function() esp.Box:Remove() esp.Name:Remove() esp.Dist:Remove() end)
        end
        ESPObjects={}
        Rayfield:Notify({Title="🗑️ ESP Limpo",Content="Drawings removidos.",Duration=2})
    end,
})

-- ============================================================
-- ABA 9: CONFIG
-- ============================================================
local CfgTab = Window:CreateTab("⚙️ Config", 4483362458)

CfgTab:CreateSection("Controles Gerais")

CfgTab:CreateButton({
    Name="🛑 DESLIGAR TUDO",
    Callback=function()
        Config.AutoFarm=false
        Config.AutoFarmProt=false
        Config.AutoBoss=false
        Config.AutoRaid=false
        Config.AutoMission=false
        Config.AutoHeal=false
        Config.NoClip=false
        Config.ESPEnabled=false
        Config.FlyEnabled=false
        Config.RaidInProgress=false
        DisableFly()
        ResetHitbox()
        Rayfield:Notify({
            Title="🛑 Tudo Desligado",
            Content="Todos os módulos pausados.\nHitbox e Fly resetados.",
            Duration=3,
        })
    end,
})

CfgTab:CreateButton({
    Name="🔄 Reset Hitbox e Fly",
    Callback=function()
        DisableFly()
        ResetHitbox()
        Config.FlyEnabled=false
        Rayfield:Notify({Title="🔄 Reset",Content="Hitbox e Fly resetados.",Duration=2})
    end,
})

CfgTab:CreateSection("Informações")

CfgTab:CreateLabel("My Hero Mania — Dark Hub v5.0")
CfgTab:CreateLabel("Remotes: Combat | Skill | GetQuest")
CfgTab:CreateLabel("Remotes: TeleportToQuest | TeleportToRaid")
CfgTab:CreateLabel("Fly: BodyVelocity equilibrado (1.0 = seguro)")
CfgTab:CreateLabel("Speed hack removido — não funciona nesse jogo")
CfgTab:CreateLabel("Compatível: Delta, Fluxus, Solara, Arceus X, Codex")
CfgTab:CreateLabel("Guard: _G.MHM_Running — sem execução dupla")

CfgTab:CreateSection("Anti-Cheat Info")

CfgTab:CreateLabel("✅ NoClip — testado OK, sem kick")
CfgTab:CreateLabel("✅ Fly 1.0 — equilibrado, sem hit kill")
CfgTab:CreateLabel("⚠️ Fly > 2.0 — risco de hit kill")
CfgTab:CreateLabel("❌ Speed Hack — não funciona (animações bloqueiam)")
CfgTab:CreateLabel("✅ MoveTo() — seguro contra magnitude check")
CfgTab:CreateLabel("✅ Raid Auto Kill — recompensas normais")

-- ============================================================
-- NOTIFICAÇÃO FINAL
-- ============================================================
task.wait(1.5)
local lv   = GetPlayerLevel()
local q    = GetBestQuest()
local r    = GetBestRaid()

Rayfield:Notify({
    Title   = "✅ Dark Hub v5.0 Pronto!",
    Content = "Olá, "..LocalPlayer.Name.."!"
        .."\nNível: "..lv
        .."\nMissão ideal: "..q.Name
        .."\nRaid ideal: "..r.Name
        .."\nTodos os módulos carregados!",
    Duration= 7,
})
