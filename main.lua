-- ============================================================
--   KYZENO X PANEL  v3.0  |  LocalScript (FIXED)
--   TEST 
-- ============================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local isMobile  = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ============================================================
--  State
-- ============================================================
local settings = {
    nightMode=false, removeTexture=false, reduceMotion=false,
    disabledAnimation=false, hideVFX=false, removeEffects=false,
    walkSpeed=16, freeze=false, infJump=false, noClip=false,
    shiftLock=false, shiftLockNormal=false, instantPrompt=false,
    antiFling=false, antiVoid=false, antiKnockback=false, godMode=false,
    esp=false, espName=true, espHighlight=true, espStatus=true,
    espHealth=false, espTool=true, espNearbyTools=false,
    smallAvatar=false, fly=false, flySpeed=50,
    shiftLockRange=100,
    aimTarget="off", aimRange=20, aimAssist=false,
    silentAim=false, silentAimRange=20,
    flingTouch=false, antiNPC=false,
}

local originalTextures  = {}
local originalBrightness = Lighting.Brightness
local espObjects        = {}
local espToolObjects    = {}
local noClipConn, antiVoidConn, infJumpConn, flyConn = nil,nil,nil,nil
local shiftLockConn, shiftLockNormalConn             = nil, nil
local antiFlingConn, antiKBConn, flingTouchConn      = nil, nil, nil
local originalPlayerName                             = nil
local crosshairGui, mobileFlyGui, mobileFlyControls  = nil, nil, nil
local originalScales = {}

-- ============================================================
--  Colors  (dark theme)
-- ============================================================
local C_BG       = Color3.fromRGB(10,10,10)
local C_DARK     = Color3.fromRGB(20,20,20)
local C_MID      = Color3.fromRGB(30,30,30)
local C_LIGHT    = Color3.fromRGB(40,40,40)
local C_RED      = Color3.fromRGB(204,0,0)
local C_RED_D    = Color3.fromRGB(153,0,0)
local C_WHITE    = Color3.fromRGB(255,255,255)
local C_GRAY     = Color3.fromRGB(136,136,136)
local C_TEXT     = Color3.fromRGB(224,224,224)

-- ============================================================
--  Crosshair
-- ============================================================
local function createCrosshair()
    if crosshairGui then crosshairGui:Destroy() end
    crosshairGui = Instance.new("ScreenGui")
    crosshairGui.Name="Crosshair"; crosshairGui.ResetOnSpawn=false
    crosshairGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    crosshairGui.Parent=playerGui; crosshairGui.Enabled=false
    local center=Instance.new("Frame"); center.Size=UDim2.new(0,40,0,40)
    center.Position=UDim2.new(0.5,-20,0.5,-20); center.BackgroundTransparency=1; center.Parent=crosshairGui
    local h=Instance.new("Frame"); h.Size=UDim2.new(1,0,0,2); h.Position=UDim2.new(0,0,0.5,-1)
    h.BackgroundColor3=C_RED; h.BorderSizePixel=0; h.Parent=center
    local v=Instance.new("Frame"); v.Size=UDim2.new(0,2,1,0); v.Position=UDim2.new(0.5,-1,0,0)
    v.BackgroundColor3=C_RED; v.BorderSizePixel=0; v.Parent=center
    local dot=Instance.new("Frame"); dot.Size=UDim2.new(0,4,0,4); dot.Position=UDim2.new(0.5,-2,0.5,-2)
    dot.BackgroundColor3=C_WHITE; dot.BorderSizePixel=0; dot.Parent=center
end
createCrosshair()

-- ============================================================
--  Mobile Fly  (UP/DOWN only — movement uses game joystick)
-- ============================================================
local function createMobileFlyControls()
    if mobileFlyGui then mobileFlyGui:Destroy() end
    mobileFlyGui = Instance.new("ScreenGui")
    mobileFlyGui.Name="MobileFly"; mobileFlyGui.ResetOnSpawn=false
    mobileFlyGui.Parent=playerGui; mobileFlyGui.Enabled=false

    local upBtn = Instance.new("TextButton")
    upBtn.Size=UDim2.new(0,65,0,65); upBtn.Position=UDim2.new(1,-90,0.5,-80)
    upBtn.BackgroundColor3=C_RED_D; upBtn.Text="▲ UP"; upBtn.TextColor3=C_WHITE
    upBtn.TextSize=15; upBtn.Font=Enum.Font.GothamBold; upBtn.BorderSizePixel=0
    upBtn.Parent=mobileFlyGui
    Instance.new("UICorner",upBtn).CornerRadius=UDim.new(0,10)

    local downBtn = Instance.new("TextButton")
    downBtn.Size=UDim2.new(0,65,0,65); downBtn.Position=UDim2.new(1,-90,0.5,15)
    downBtn.BackgroundColor3=C_MID; downBtn.Text="▼ DN"; downBtn.TextColor3=C_WHITE
    downBtn.TextSize=15; downBtn.Font=Enum.Font.GothamBold; downBtn.BorderSizePixel=0
    downBtn.Parent=mobileFlyGui
    Instance.new("UICorner",downBtn).CornerRadius=UDim.new(0,10)

    local flyUp,flyDown=false,false
    upBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then flyUp=true end end)
    upBtn.InputEnded:Connect(function() flyUp=false end)
    downBtn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then flyDown=true end end)
    downBtn.InputEnded:Connect(function() flyDown=false end)

    mobileFlyControls = {
        isFlyUp   = function() return flyUp end,
        isFlyDown = function() return flyDown end,
        getMoveDirection = function() return Vector3.zero end,
    }
    return mobileFlyControls
end

-- ============================================================
--  Draggable helper
-- ============================================================
local function makeDraggable(gui)
    local dragging,dragInput,mousePos,framePos=false,nil,nil,nil
    gui.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; mousePos=inp.Position; framePos=gui.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch) then
            local d=inp.Position-mousePos
            gui.Position=UDim2.new(framePos.X.Scale,framePos.X.Offset+d.X,framePos.Y.Scale,framePos.Y.Offset+d.Y)
        end
    end)
end

-- ============================================================
--  ScreenGui
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name="KYZENO_X_PANEL"; screenGui.ResetOnSpawn=false
screenGui.IgnoreGuiInset=true; screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
screenGui.Parent=playerGui

-- ============================================================
--  Loading Screen
-- ============================================================
local loadScreen = Instance.new("Frame")
loadScreen.Name="LoadScreen"; loadScreen.Size=UDim2.new(1,0,1,0)
loadScreen.Position=UDim2.new(0,0,0,0); loadScreen.BackgroundColor3=Color3.fromRGB(0,0,0)
loadScreen.BorderSizePixel=0; loadScreen.ZIndex=100; loadScreen.Parent=screenGui

-- Logo image
local loadLogo = Instance.new("ImageLabel")
loadLogo.Size=UDim2.new(0,90,0,90); loadLogo.Position=UDim2.new(0.5,-45,0.35,-45)
loadLogo.BackgroundTransparency=1; loadLogo.Image="rbxassetid://106158447709741"
loadLogo.ImageTransparency=0; loadLogo.ZIndex=101; loadLogo.Parent=loadScreen

-- Title
local loadTitle = Instance.new("TextLabel")
loadTitle.Size=UDim2.new(0,400,0,36); loadTitle.Position=UDim2.new(0.5,-200,0.5,-4)
loadTitle.BackgroundTransparency=1; loadTitle.Text="|KYZENO X PANEL|"
loadTitle.TextColor3=Color3.fromRGB(255,255,255); loadTitle.TextSize=28
loadTitle.Font=Enum.Font.GothamBlack; loadTitle.ZIndex=101; loadTitle.Parent=loadScreen

-- Sub line
local loadSub = Instance.new("TextLabel")
loadSub.Size=UDim2.new(0,400,0,20); loadSub.Position=UDim2.new(0.5,-200,0.5,34)
loadSub.BackgroundTransparency=1; loadSub.Text="VER. 3.0  |  TEST EDITION"
loadSub.TextColor3=Color3.fromRGB(204,0,0); loadSub.TextSize=13
loadSub.Font=Enum.Font.GothamBold; loadSub.ZIndex=101; loadSub.Parent=loadScreen

-- Credit line
local loadCredit = Instance.new("TextLabel")
loadCredit.Size=UDim2.new(0,400,0,18); loadCredit.Position=UDim2.new(0.5,-200,0.5,60)
loadCredit.BackgroundTransparency=1; loadCredit.Text="By Zeno  •  Co-pilot: Claude 4.6"
loadCredit.TextColor3=Color3.fromRGB(100,100,100); loadCredit.TextSize=11
loadCredit.Font=Enum.Font.Gotham; loadCredit.ZIndex=101; loadCredit.Parent=loadScreen

-- Loading bar background
local barBg = Instance.new("Frame")
barBg.Size=UDim2.new(0,300,0,4); barBg.Position=UDim2.new(0.5,-150,0.65,0)
barBg.BackgroundColor3=Color3.fromRGB(30,30,30); barBg.BorderSizePixel=0
barBg.ZIndex=101; barBg.Parent=loadScreen
Instance.new("UICorner",barBg).CornerRadius=UDim.new(1,0)

local barFill = Instance.new("Frame")
barFill.Size=UDim2.new(0,0,1,0); barFill.BackgroundColor3=Color3.fromRGB(204,0,0)
barFill.BorderSizePixel=0; barFill.ZIndex=102; barFill.Parent=barBg
Instance.new("UICorner",barFill).CornerRadius=UDim.new(1,0)

-- Status text
local loadStatus = Instance.new("TextLabel")
loadStatus.Size=UDim2.new(0,300,0,16); loadStatus.Position=UDim2.new(0.5,-150,0.65,10)
loadStatus.BackgroundTransparency=1; loadStatus.Text="Initializing..."
loadStatus.TextColor3=Color3.fromRGB(120,120,120); loadStatus.TextSize=11
loadStatus.Font=Enum.Font.Gotham; loadStatus.ZIndex=101; loadStatus.Parent=loadScreen

-- Animate loading bar + status messages then fade out
task.spawn(function()
    local steps = {
        { pct=0.15, msg="Loading modules...",   t=0.18 },
        { pct=0.35, msg="Building UI...",        t=0.18 },
        { pct=0.55, msg="Applying theme...",     t=0.18 },
        { pct=0.75, msg="Hooking services...",   t=0.18 },
        { pct=0.95, msg="Almost ready...",       t=0.18 },
        { pct=1.00, msg="Welcome, "..player.DisplayName.."!", t=0.2 },
    }
    for _,step in ipairs(steps) do
        TweenService:Create(barFill, TweenInfo.new(step.t, Enum.EasingStyle.Quad), {Size=UDim2.new(step.pct,0,1,0)}):Play()
        loadStatus.Text = step.msg
        task.wait(step.t + 0.05)
    end
    task.wait(0.4)
    local targets = {loadScreen, loadLogo, loadTitle, loadSub, loadCredit, barBg, loadStatus}
    local tweens = {}
    for _,obj in ipairs(targets) do
        local prop = obj:IsA("TextLabel") and "TextTransparency"
            or obj:IsA("ImageLabel") and "ImageTransparency"
            or "BackgroundTransparency"
        local t = TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {[prop]=1})
        table.insert(tweens, t); t:Play()
    end
    TweenService:Create(barFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency=1}):Play()
    TweenService:Create(loadScreen, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency=1}):Play()
    task.wait(0.55)
    loadScreen:Destroy()
end)

-- ============================================================
--  Open Button
-- ============================================================
local openButton = Instance.new("ImageButton")
openButton.Name="OpenButton"; openButton.Size=UDim2.new(0,50,0,50)
openButton.Position=UDim2.new(0.5,-25,0.5,-25)
openButton.BackgroundColor3=C_BG; openButton.BorderSizePixel=0
openButton.Image="rbxassetid://106158447709741"
openButton.BackgroundTransparency=0.2; openButton.Parent=screenGui
makeDraggable(openButton)
Instance.new("UICorner",openButton).CornerRadius=UDim.new(0,8)
local openStroke=Instance.new("UIStroke"); openStroke.Color=C_RED
openStroke.Thickness=2; openStroke.Parent=openButton

-- ============================================================
--  Main Frame
-- ============================================================
local mainFrame = Instance.new("Frame")
mainFrame.Name="MainFrame"; mainFrame.Size=UDim2.new(0,700,0,500)
mainFrame.Position=UDim2.new(0.5,-350,0.5,-250)
mainFrame.BackgroundColor3=C_BG; mainFrame.BorderSizePixel=0
mainFrame.Visible=false; mainFrame.Parent=screenGui
makeDraggable(mainFrame)
Instance.new("UICorner",mainFrame).CornerRadius=UDim.new(0,8)
local mainStroke=Instance.new("UIStroke"); mainStroke.Color=C_RED
mainStroke.Thickness=2; mainStroke.Parent=mainFrame

-- Header
local header=Instance.new("Frame"); header.Name="Header"
header.Size=UDim2.new(1,0,0,60); header.BackgroundColor3=Color3.fromRGB(0,0,0)
header.BorderSizePixel=0; header.Parent=mainFrame
Instance.new("UICorner",header).CornerRadius=UDim.new(0,8)
local hGrad=Instance.new("UIGradient")
hGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(26,26,26))})
hGrad.Rotation=90; hGrad.Parent=header

local logoImg=Instance.new("ImageLabel"); logoImg.Size=UDim2.new(0,50,0,50)
logoImg.Position=UDim2.new(0,15,0.5,-25); logoImg.BackgroundTransparency=1
logoImg.Image="rbxassetid://106158447709741"; logoImg.Parent=header

local titleLbl=Instance.new("TextLabel"); titleLbl.Size=UDim2.new(0,280,0,30)
titleLbl.Position=UDim2.new(0,75,0,8); titleLbl.BackgroundTransparency=1
titleLbl.Text="|KYZENO X PANEL|"; titleLbl.TextColor3=C_WHITE
titleLbl.TextSize=20; titleLbl.Font=Enum.Font.GothamBlack
titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.Parent=header

local subLbl=Instance.new("TextLabel"); subLbl.Size=UDim2.new(0,120,0,15)
subLbl.Position=UDim2.new(0,75,0,38); subLbl.BackgroundTransparency=1
subLbl.Text="VER. 3.0 | FIXED"; subLbl.TextColor3=C_RED
subLbl.TextSize=11; subLbl.Font=Enum.Font.GothamBold
subLbl.TextXAlignment=Enum.TextXAlignment.Left; subLbl.Parent=header

local closeButton=Instance.new("TextButton"); closeButton.Name="CloseButton"
closeButton.Size=UDim2.new(0,35,0,35); closeButton.Position=UDim2.new(1,-45,0.5,-17.5)
closeButton.BackgroundColor3=C_RED; closeButton.Text="✕"; closeButton.TextColor3=C_WHITE
closeButton.TextSize=18; closeButton.Font=Enum.Font.GothamBold; closeButton.Parent=header
Instance.new("UICorner",closeButton).CornerRadius=UDim.new(0,6)

-- ============================================================
--  NAV BAR
-- ============================================================
local navScroll = Instance.new("ScrollingFrame")
navScroll.Name="NavScroll"
navScroll.Size=UDim2.new(1,0,0,38)
navScroll.Position=UDim2.new(0,0,0,60)
navScroll.BackgroundColor3=Color3.fromRGB(26,26,26)
navScroll.BorderSizePixel=0
navScroll.ScrollBarThickness=3
navScroll.ScrollBarImageColor3=C_RED
navScroll.ScrollingDirection=Enum.ScrollingDirection.X
navScroll.CanvasSize=UDim2.new(0,0,0,0)
navScroll.AutomaticCanvasSize=Enum.AutomaticSize.X
navScroll.Parent=mainFrame

local navGrad=Instance.new("UIGradient")
navGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(42,42,42)),ColorSequenceKeypoint.new(1,Color3.fromRGB(26,26,26))})
navGrad.Rotation=90; navGrad.Parent=navScroll

local navLayout=Instance.new("UIListLayout")
navLayout.FillDirection=Enum.FillDirection.Horizontal
navLayout.SortOrder=Enum.SortOrder.LayoutOrder
navLayout.Padding=UDim.new(0,0)
navLayout.Parent=navScroll

-- ============================================================
--  Sidebar (Credits)
-- ============================================================
local sidebar=Instance.new("Frame"); sidebar.Name="Sidebar"
sidebar.Size=UDim2.new(0,200,1,-98); sidebar.Position=UDim2.new(0,0,0,98)
sidebar.BackgroundColor3=Color3.fromRGB(13,13,13); sidebar.BorderSizePixel=0; sidebar.Parent=mainFrame
local sbGrad=Instance.new("UIGradient")
sbGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(26,26,26)),ColorSequenceKeypoint.new(1,Color3.fromRGB(13,13,13))})
sbGrad.Rotation=90; sbGrad.Parent=sidebar
local sbStroke=Instance.new("UIStroke"); sbStroke.Color=Color3.fromRGB(34,34,34); sbStroke.Thickness=1; sbStroke.Parent=sidebar

local sbTitle=Instance.new("TextLabel"); sbTitle.Size=UDim2.new(1,-20,0,30)
sbTitle.Position=UDim2.new(0,10,0,15); sbTitle.BackgroundTransparency=1
sbTitle.Text="CREDITS"; sbTitle.TextColor3=C_RED; sbTitle.TextSize=14
sbTitle.Font=Enum.Font.GothamBlack; sbTitle.TextXAlignment=Enum.TextXAlignment.Left; sbTitle.Parent=sidebar

local sbLine=Instance.new("Frame"); sbLine.Size=UDim2.new(0,40,0,2)
sbLine.Position=UDim2.new(0,10,0,48); sbLine.BackgroundColor3=C_RED
sbLine.BorderSizePixel=0; sbLine.Parent=sidebar

local sbCredits=Instance.new("TextLabel"); sbCredits.Size=UDim2.new(1,-20,0,160)
sbCredits.Position=UDim2.new(0,10,0,60); sbCredits.BackgroundTransparency=1
sbCredits.Text="Design: Me & Claude\nBy: Zeno\nCo-pilot: Claude 4.6\n\nVersion: Fixed Edition"
sbCredits.TextColor3=C_GRAY; sbCredits.TextSize=12; sbCredits.Font=Enum.Font.Gotham
sbCredits.TextXAlignment=Enum.TextXAlignment.Left; sbCredits.TextWrapped=true
sbCredits.LineHeight=1.8; sbCredits.Parent=sidebar

-- ============================================================
--  Content Area
-- ============================================================
local contentArea=Instance.new("ScrollingFrame"); contentArea.Name="ContentArea"
contentArea.Size=UDim2.new(1,-200,1,-98); contentArea.Position=UDim2.new(0,200,0,98)
contentArea.BackgroundColor3=Color3.fromRGB(13,13,13); contentArea.BorderSizePixel=0
contentArea.ScrollBarThickness=6; contentArea.ScrollBarImageColor3=C_RED
contentArea.CanvasSize=UDim2.new(0,0,0,0)
contentArea.ScrollingDirection=Enum.ScrollingDirection.Y
contentArea.Parent=mainFrame

local caGrad=Instance.new("UIGradient")
caGrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(26,26,26)),ColorSequenceKeypoint.new(1,Color3.fromRGB(13,13,13))})
caGrad.Rotation=90; caGrad.Parent=contentArea
local caStroke=Instance.new("UIStroke"); caStroke.Color=Color3.fromRGB(34,34,34); caStroke.Thickness=1; caStroke.Parent=contentArea

local contentLayout=Instance.new("UIListLayout"); contentLayout.SortOrder=Enum.SortOrder.LayoutOrder
contentLayout.Padding=UDim.new(0,10); contentLayout.Parent=contentArea

local contentPad=Instance.new("UIPadding"); contentPad.PaddingTop=UDim.new(0,20)
contentPad.PaddingLeft=UDim.new(0,20); contentPad.PaddingRight=UDim.new(0,20)
contentPad.PaddingBottom=UDim.new(0,20); contentPad.Parent=contentArea

contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    contentArea.CanvasSize=UDim2.new(0,0,0,contentLayout.AbsoluteContentSize.Y+40)
end)

-- ============================================================
--  Content Helpers
-- ============================================================
local function clearContent()
    for _,c in ipairs(contentArea:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding")
          and not c:IsA("UIGradient") and not c:IsA("UIStroke") then
            c:Destroy()
        end
    end
end

local function createSectionTitle(text)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,0,0,50)
    f.BackgroundTransparency=1; f.Parent=contentArea
    local t=Instance.new("TextLabel"); t.Size=UDim2.new(0,150,0,25); t.Position=UDim2.new(0,0,0,0)
    t.BackgroundTransparency=1; t.Text=text; t.TextColor3=C_RED; t.TextSize=11
    t.Font=Enum.Font.GothamBlack; t.TextXAlignment=Enum.TextXAlignment.Left; t.Parent=f
    local h=Instance.new("TextLabel"); h.Size=UDim2.new(1,0,0,28); h.Position=UDim2.new(0,0,0,18)
    h.BackgroundTransparency=1; h.Text=text; h.TextColor3=C_WHITE; h.TextSize=22
    h.Font=Enum.Font.GothamBlack; h.TextXAlignment=Enum.TextXAlignment.Left; h.Parent=f
    local l=Instance.new("Frame"); l.Size=UDim2.new(0,60,0,3); l.Position=UDim2.new(0,0,0,46)
    l.BackgroundColor3=C_RED; l.BorderSizePixel=0; l.Parent=f
    return f
end

local function createInfoLabel(text)
    local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,0,20)
    lbl.BackgroundTransparency=1; lbl.Text=text; lbl.TextColor3=C_GRAY; lbl.TextSize=11
    lbl.Font=Enum.Font.Gotham; lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextWrapped=true; lbl.Parent=contentArea
end

local function createToggle(labelText, settingKey, callback)
    local defaultState = settings[settingKey] or false
    local container=Instance.new("Frame"); container.Size=UDim2.new(1,0,0,38)
    container.BackgroundColor3=Color3.fromRGB(34,34,34); container.BorderSizePixel=1
    container.BorderColor3=Color3.fromRGB(51,51,51); container.Parent=contentArea
    Instance.new("UICorner",container).CornerRadius=UDim.new(0,5)
    local label=Instance.new("TextLabel"); label.Size=UDim2.new(1,-60,1,0)
    label.Position=UDim2.new(0,15,0,0); label.BackgroundTransparency=1; label.Text=labelText
    label.TextColor3=C_TEXT; label.TextSize=13; label.Font=Enum.Font.Gotham
    label.TextXAlignment=Enum.TextXAlignment.Left; label.Parent=container
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(0,44,0,26)
    btn.Position=UDim2.new(1,-54,0.5,-13)
    btn.BackgroundColor3=defaultState and C_RED or Color3.fromRGB(51,51,51)
    btn.Text=defaultState and "ON" or "OFF"; btn.TextColor3=C_WHITE; btn.TextSize=11
    btn.Font=Enum.Font.GothamBlack; btn.Parent=container
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4)
    local state=defaultState
    btn.MouseButton1Click:Connect(function()
        state=not state; settings[settingKey]=state
        btn.Text=state and "ON" or "OFF"
        btn.BackgroundColor3=state and C_RED or Color3.fromRGB(51,51,51)
        callback(state)
    end)
    return container
end

local function createSlider(labelText, minVal, maxVal, settingKey, callback)
    local defaultVal=settings[settingKey] or minVal
    local container=Instance.new("Frame"); container.Size=UDim2.new(1,0,0,58)
    container.BackgroundColor3=Color3.fromRGB(34,34,34); container.BorderSizePixel=1
    container.BorderColor3=Color3.fromRGB(51,51,51); container.Parent=contentArea
    Instance.new("UICorner",container).CornerRadius=UDim.new(0,5)
    local label=Instance.new("TextLabel"); label.Size=UDim2.new(1,-20,0,22)
    label.Position=UDim2.new(0,15,0,5); label.BackgroundTransparency=1; label.Text=labelText
    label.TextColor3=C_TEXT; label.TextSize=13; label.Font=Enum.Font.Gotham
    label.TextXAlignment=Enum.TextXAlignment.Left; label.Parent=container
    local sliderBg=Instance.new("Frame"); sliderBg.Size=UDim2.new(1,-100,0,6)
    sliderBg.Position=UDim2.new(0,15,0,34); sliderBg.BackgroundColor3=Color3.fromRGB(51,51,51)
    sliderBg.BorderSizePixel=0; sliderBg.Parent=container
    Instance.new("UICorner",sliderBg).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame"); fill.Size=UDim2.new((defaultVal-minVal)/(maxVal-minVal),0,1,0)
    fill.BackgroundColor3=C_RED; fill.BorderSizePixel=0; fill.Parent=sliderBg
    Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)
    local inputBox=Instance.new("TextBox"); inputBox.Size=UDim2.new(0,58,0,24)
    inputBox.Position=UDim2.new(1,-68,0,32); inputBox.BackgroundColor3=Color3.fromRGB(34,34,34)
    inputBox.BorderColor3=Color3.fromRGB(51,51,51); inputBox.Text=tostring(defaultVal)
    inputBox.TextColor3=C_WHITE; inputBox.TextSize=12; inputBox.Font=Enum.Font.Gotham; inputBox.Parent=container
    Instance.new("UICorner",inputBox).CornerRadius=UDim.new(0,4)
    local curVal=defaultVal
    local function updateVal(v)
        v=math.clamp(math.floor(v),minVal,maxVal); curVal=v; settings[settingKey]=v
        fill.Size=UDim2.new((v-minVal)/(maxVal-minVal),0,1,0); inputBox.Text=tostring(v); callback(v)
    end
    sliderBg.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            local function upd()
                local mp=UserInputService:GetMouseLocation().X
                local sp=sliderBg.AbsolutePosition.X; local ss=sliderBg.AbsoluteSize.X
                updateVal(minVal+(maxVal-minVal)*math.clamp((mp-sp)/ss,0,1))
            end; upd()
            local conn; conn=UserInputService.InputChanged:Connect(function(i2)
                if i2.UserInputType==Enum.UserInputType.MouseMovement or i2.UserInputType==Enum.UserInputType.Touch then upd() end
            end)
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then conn:Disconnect() end end)
        end
    end)
    inputBox.FocusLost:Connect(function() local v=tonumber(inputBox.Text) if v then updateVal(v) else inputBox.Text=tostring(curVal) end end)
    return container
end

local function createButton(text, callback)
    local btn=Instance.new("TextButton"); btn.Size=UDim2.new(1,0,0,40)
    btn.BackgroundColor3=C_RED; btn.Text=text; btn.TextColor3=C_WHITE; btn.TextSize=13
    btn.Font=Enum.Font.GothamBlack; btn.Parent=contentArea
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    btn.MouseButton1Click:Connect(callback); return btn
end

local function createAimSelector(callback)
    local container=Instance.new("Frame"); container.Size=UDim2.new(1,0,0,42)
    container.BackgroundColor3=Color3.fromRGB(34,34,34); container.BorderSizePixel=1
    container.BorderColor3=Color3.fromRGB(51,51,51); container.Parent=contentArea
    Instance.new("UICorner",container).CornerRadius=UDim.new(0,5)
    local label=Instance.new("TextLabel"); label.Size=UDim2.new(0.38,0,1,0)
    label.Position=UDim2.new(0,15,0,0); label.BackgroundTransparency=1
    label.Text="AIM Target"; label.TextColor3=C_TEXT; label.TextSize=13
    label.Font=Enum.Font.Gotham; label.TextXAlignment=Enum.TextXAlignment.Left; label.Parent=container
    local opts={"Head","Body","Off"}
    for i,opt in ipairs(opts) do
        local b=Instance.new("TextButton"); b.Size=UDim2.new(0,68,0,26)
        b.Position=UDim2.new(0.38,(i-1)*72,0.5,-13)
        b.BackgroundColor3=settings.aimTarget==opt:lower() and C_RED or Color3.fromRGB(51,51,51)
        b.Text=opt; b.TextColor3=C_WHITE; b.TextSize=11; b.Font=Enum.Font.GothamBold; b.Parent=container
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
        b.MouseButton1Click:Connect(function()
            settings.aimTarget=opt:lower()
            for _,child in ipairs(container:GetChildren()) do
                if child:IsA("TextButton") then child.BackgroundColor3=Color3.fromRGB(51,51,51) end
            end
            b.BackgroundColor3=C_RED; callback(settings.aimTarget)
        end)
    end
end

local function createTextInput(labelText, placeholder, callback)
    local container=Instance.new("Frame"); container.Size=UDim2.new(1,0,0,42)
    container.BackgroundColor3=Color3.fromRGB(34,34,34); container.BorderSizePixel=1
    container.BorderColor3=Color3.fromRGB(51,51,51); container.Parent=contentArea
    Instance.new("UICorner",container).CornerRadius=UDim.new(0,5)
    local label=Instance.new("TextLabel"); label.Size=UDim2.new(0.35,0,1,0)
    label.Position=UDim2.new(0,15,0,0); label.BackgroundTransparency=1; label.Text=labelText
    label.TextColor3=C_TEXT; label.TextSize=12; label.Font=Enum.Font.Gotham
    label.TextXAlignment=Enum.TextXAlignment.Left; label.Parent=container
    local tb=Instance.new("TextBox"); tb.Size=UDim2.new(0.42,0,0,26)
    tb.Position=UDim2.new(0.36,0,0.5,-13); tb.BackgroundColor3=Color3.fromRGB(20,20,20)
    tb.BorderSizePixel=0; tb.Text=""; tb.PlaceholderText=placeholder
    tb.TextColor3=C_WHITE; tb.PlaceholderColor3=C_GRAY; tb.TextSize=12; tb.Font=Enum.Font.Gotham
    tb.ClearTextOnFocus=false; tb.Parent=container
    Instance.new("UICorner",tb).CornerRadius=UDim.new(0,4)
    local goBtn=Instance.new("TextButton"); goBtn.Size=UDim2.new(0,44,0,26)
    goBtn.Position=UDim2.new(0.8,0,0.5,-13); goBtn.BackgroundColor3=C_RED
    goBtn.Text="GO"; goBtn.TextColor3=C_WHITE; goBtn.TextSize=11; goBtn.Font=Enum.Font.GothamBlack
    goBtn.Parent=container; Instance.new("UICorner",goBtn).CornerRadius=UDim.new(0,4)
    goBtn.MouseButton1Click:Connect(function() callback(tb.Text) end)
    return container,tb
end

-- ============================================================
--  Section Logic
-- ============================================================
local currentSection=nil
local sectionFunctions={}

local function updateNavStyle(selectedName)
    for _,btn in ipairs(navScroll:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.BackgroundColor3 = btn.Name==selectedName and C_RED or Color3.fromRGB(26,26,26)
            btn.TextColor3 = C_WHITE
        end
    end
end

local function showSection(name)
    clearContent(); updateNavStyle(name)
    contentArea.CanvasPosition=Vector2.new(0,0)
    if sectionFunctions[name] then sectionFunctions[name]() end
end

-- ============================================================
--  SECTION: SETTINGS
-- ============================================================
sectionFunctions["SETTINGS"]=function()
    createSectionTitle("SETTINGS")
    createToggle("Night Mode","nightMode",function(on)
        if on then originalBrightness=Lighting.Brightness; Lighting.Brightness=0.5; Lighting.Ambient=Color3.fromRGB(50,50,50)
        else Lighting.Brightness=originalBrightness; Lighting.Ambient=Color3.fromRGB(128,128,128) end
    end)
    createToggle("Remove Texture","removeTexture",function(on)
        if on then for _,o in ipairs(workspace:GetDescendants()) do if o:IsA("Part") and not(player.Character and o:IsDescendantOf(player.Character)) then originalTextures[o]=o.Material; o.Material=Enum.Material.SmoothPlastic end end
        else for o,m in pairs(originalTextures) do if o and o.Parent then o.Material=m end end end
    end)
    createToggle("Reduce Motion","reduceMotion",function() end)
    createToggle("Disabled Animation","disabledAnimation",function(on)
        for _,p in ipairs(Players:GetPlayers()) do if p~=player and p.Character then local h=p.Character:FindFirstChildOfClass("Humanoid") if h then local a=h:FindFirstChildOfClass("Animator") if a then for _,t in ipairs(a:GetPlayingAnimationTracks()) do if on then t:Stop() end end end end end end
    end)
    createToggle("Hide VFX","hideVFX",function() end)
    createToggle("Remove Effects","removeEffects",function(on)
        for _,e in ipairs(Lighting:GetChildren()) do if e:IsA("PostEffect") then e.Enabled=not on end end
    end)
end

-- ============================================================
--  SECTION: LOCAL PLAYER
-- ============================================================
sectionFunctions["LOCALPLAYER"]=function()
    createSectionTitle("LOCAL PLAYER")
    createSlider("Walkspeed",16,200,"walkSpeed",function(v) if player.Character and player.Character:FindFirstChild("Humanoid") then player.Character.Humanoid.WalkSpeed=v end end)
    createToggle("Freeze","freeze",function(on) if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then player.Character.HumanoidRootPart.Anchored=on end end)
    createToggle("InfJump","infJump",function(on)
        if on then if infJumpConn then infJumpConn:Disconnect() end
            infJumpConn=UserInputService.JumpRequest:Connect(function() if player.Character then local h=player.Character:FindFirstChild("Humanoid") if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end)
        else if infJumpConn then infJumpConn:Disconnect(); infJumpConn=nil end end
    end)
    createToggle("No Clip","noClip",function(on)
        if on then if noClipConn then noClipConn:Disconnect() end
            noClipConn=RunService.Stepped:Connect(function() if player.Character then for _,p in ipairs(player.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end)
        else if noClipConn then noClipConn:Disconnect(); noClipConn=nil end
            if player.Character then for _,p in ipairs(player.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end end
    end)
    createToggle("Small Avatar","smallAvatar",function(on)
        if player.Character then local hum=player.Character:FindFirstChildOfClass("Humanoid") if hum then
            if on then
                originalScales={BodyHeightScale=hum.BodyHeightScale.Value,BodyWidthScale=hum.BodyWidthScale.Value,BodyDepthScale=hum.BodyDepthScale.Value,HeadScale=hum.HeadScale.Value}
                hum.BodyHeightScale.Value=0.3;hum.BodyWidthScale.Value=0.3;hum.BodyDepthScale.Value=0.3;hum.HeadScale.Value=0.3
            elseif originalScales.BodyHeightScale then
                hum.BodyHeightScale.Value=originalScales.BodyHeightScale;hum.BodyWidthScale.Value=originalScales.BodyWidthScale
                hum.BodyDepthScale.Value=originalScales.BodyDepthScale;hum.HeadScale.Value=originalScales.HeadScale
            end
        end end
    end)
    createToggle("Fly","fly",function(on)
        if on then
            if flyConn then flyConn:Disconnect() end
            local char=player.Character; if not char then return end
            local hum=char:FindFirstChild("Humanoid"); local hrp=char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            local bv=Instance.new("BodyVelocity"); bv.Name="FlyVelocity"; bv.MaxForce=Vector3.new(4e5,4e5,4e5); bv.Velocity=Vector3.zero; bv.Parent=hrp
            local bg=Instance.new("BodyGyro"); bg.Name="FlyGyro"; bg.MaxTorque=Vector3.new(4e5,4e5,4e5); bg.CFrame=hrp.CFrame; bg.Parent=hrp
            if isMobile then mobileFlyControls=createMobileFlyControls(); mobileFlyGui.Enabled=true end
            flyConn=RunService.Heartbeat:Connect(function()
                if not player.Character or not hrp or not hrp.Parent then return end
                local moveDir=Vector3.zero
                if isMobile and mobileFlyControls then
                    local md=hum.MoveDirection
                    if md.Magnitude>0 then moveDir=Vector3.new(md.X,0,md.Z).Unit*settings.flySpeed end
                    if mobileFlyControls.isFlyUp()  then moveDir=Vector3.new(moveDir.X,settings.flySpeed,moveDir.Z) end
                    if mobileFlyControls.isFlyDown() then moveDir=Vector3.new(moveDir.X,-settings.flySpeed,moveDir.Z) end
                else
                    local cam=workspace.CurrentCamera
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir+=cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir-=cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir-=cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir+=cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir+=Vector3.new(0,1,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir-=Vector3.new(0,1,0) end
                    if moveDir.Magnitude>0 then moveDir=moveDir.Unit*settings.flySpeed end
                end
                if bv and bv.Parent then bv.Velocity=moveDir end
                if bg and bg.Parent then bg.CFrame=workspace.CurrentCamera.CFrame end
                hum.PlatformStand=true
            end)
        else
            if flyConn then flyConn:Disconnect(); flyConn=nil end
            if mobileFlyGui then mobileFlyGui.Enabled=false; mobileFlyGui:Destroy(); mobileFlyGui=nil; mobileFlyControls=nil end
            if player.Character then
                local hrp=player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then for _,n in ipairs({"FlyVelocity","FlyGyro"}) do local o=hrp:FindFirstChild(n) if o then o:Destroy() end end end
                local h=player.Character:FindFirstChild("Humanoid") if h then h.PlatformStand=false end
            end
        end
    end)
    createSlider("Fly Speed",10,500,"flySpeed",function() end)
end

-- ============================================================
--  SECTION: ASSIST
-- ============================================================
sectionFunctions["ASSIST"]=function()
    createSectionTitle("ASSIST")

    createSlider("Lock Range",20,700,"shiftLockRange",function() end)
    createToggle("ShiftLock (Target)","shiftLock",function(on)
        if on then
            if shiftLockConn then shiftLockConn:Disconnect() end
            if crosshairGui then crosshairGui.Enabled=true end
            if not isMobile then UserInputService.MouseBehavior=Enum.MouseBehavior.LockCenter end
            shiftLockConn=RunService.RenderStepped:Connect(function()
                if not player.Character then return end
                local myRoot=player.Character:FindFirstChild("HumanoidRootPart")
                local hum=player.Character:FindFirstChild("Humanoid")
                if not myRoot or not hum then return end
                local nearest,nearDist=nil,settings.shiftLockRange
                for _,p in ipairs(Players:GetPlayers()) do
                    if p~=player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local oh=p.Character:FindFirstChild("Humanoid")
                        if oh and oh.Health>0 then
                            local d=(myRoot.Position-p.Character.HumanoidRootPart.Position).Magnitude
                            if d<=settings.shiftLockRange and d<nearDist then nearDist=d; nearest=p end
                        end
                    end
                end
                if nearest and nearest.Character then
                    local tHRP=nearest.Character:FindFirstChild("HumanoidRootPart")
                    if tHRP then
                        hum.AutoRotate=false
                        myRoot.CFrame=CFrame.new(myRoot.Position,Vector3.new(tHRP.Position.X,myRoot.Position.Y,tHRP.Position.Z))
                        workspace.CurrentCamera.CFrame=CFrame.new(workspace.CurrentCamera.CFrame.Position,tHRP.Position)
                    end
                else hum.AutoRotate=true end
            end)
        else
            if shiftLockConn then shiftLockConn:Disconnect(); shiftLockConn=nil end
            if crosshairGui then crosshairGui.Enabled=false end
            if not isMobile then UserInputService.MouseBehavior=Enum.MouseBehavior.Default end
            if player.Character then local h=player.Character:FindFirstChild("Humanoid") if h then h.AutoRotate=true end end
        end
    end)

    createToggle("ShiftLock (N)","shiftLockNormal",function(on)
        if on then
            if shiftLockNormalConn then shiftLockNormalConn:Disconnect() end
            if not isMobile then UserInputService.MouseBehavior=Enum.MouseBehavior.LockCenter end
            shiftLockNormalConn=RunService.RenderStepped:Connect(function()
                if not player.Character then return end
                local myRoot=player.Character:FindFirstChild("HumanoidRootPart")
                local hum=player.Character:FindFirstChild("Humanoid")
                if not myRoot or not hum then return end
                hum.AutoRotate=false
                local camLook=workspace.CurrentCamera.CFrame.LookVector
                myRoot.CFrame=CFrame.new(myRoot.Position,myRoot.Position+Vector3.new(camLook.X,0,camLook.Z))
            end)
        else
            if shiftLockNormalConn then shiftLockNormalConn:Disconnect(); shiftLockNormalConn=nil end
            if not isMobile then UserInputService.MouseBehavior=Enum.MouseBehavior.Default end
            if player.Character then local h=player.Character:FindFirstChild("Humanoid") if h then h.AutoRotate=true end end
        end
    end)

    createSlider("Silent AIM Range",20,110,"silentAimRange",function() end)
    createToggle("Silent AIM","silentAim",function(on)
        if on then
            RunService:BindToRenderStep("SilentAim",Enum.RenderPriority.Input.Value+1,function()
                if not settings.silentAim then return end
                if not player.Character then return end
                local myHRP=player.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
                local cam=workspace.CurrentCamera
                local nearest,nearDist=nil,settings.silentAimRange
                for _,p in ipairs(Players:GetPlayers()) do
                    if p~=player and p.Character then
                        local pHRP=p.Character:FindFirstChild("HumanoidRootPart")
                        local pHum=p.Character:FindFirstChild("Humanoid")
                        if pHRP and pHum and pHum.Health>0 then
                            local dist=(myHRP.Position-pHRP.Position).Magnitude
                            if dist<nearDist then
                                local toTarget=(pHRP.Position-cam.CFrame.Position).Unit
                                local camLook=cam.CFrame.LookVector
                                if toTarget:Dot(camLook)>0.3 then
                                    nearDist=dist; nearest=p
                                end
                            end
                        end
                    end
                end
                if nearest and nearest.Character then
                    local targetPart = nearest.Character:FindFirstChild("Head")
                        or nearest.Character:FindFirstChild("HumanoidRootPart")
                    if targetPart then
                        pcall(function()
                            local mouse=player:GetMouse()
                            local tool=player.Character:FindFirstChildOfClass("Tool")
                            if tool then
                                for _,v in ipairs(tool:GetDescendants()) do
                                    if v:IsA("RemoteEvent") then
                                        _G.SilentAimTarget=targetPart
                                        return
                                    end
                                end
                            end
                            _G.SilentAimTarget=targetPart
                        end)
                        if crosshairGui and crosshairGui.Enabled then
                            local screenPos,onScreen=cam:WorldToScreenPoint(targetPart.Position)
                            if onScreen then
                                local crossCenter=crosshairGui:FindFirstChildOfClass("Frame")
                                if crossCenter then
                                    crossCenter.Position=UDim2.new(0,screenPos.X-20,0,screenPos.Y-20)
                                end
                            end
                        end
                    end
                else
                    _G.SilentAimTarget=nil
                    if crosshairGui then
                        local crossCenter=crosshairGui:FindFirstChildOfClass("Frame")
                        if crossCenter then
                            crossCenter.Position=UDim2.new(0.5,-20,0.5,-20)
                        end
                    end
                end
            end)
        else
            pcall(function() RunService:UnbindFromRenderStep("SilentAim") end)
            _G.SilentAimTarget=nil
            if crosshairGui then
                local crossCenter=crosshairGui:FindFirstChildOfClass("Frame")
                if crossCenter then crossCenter.Position=UDim2.new(0.5,-20,0.5,-20) end
            end
        end
    end)

    createAimSelector(function(_) end)
    createSlider("AIM Range",1,700,"aimRange",function() end)
    createToggle("AIM Assist","aimAssist",function(on)
        if on then
            RunService:BindToRenderStep("AimAssist",Enum.RenderPriority.Camera.Value+1,function()
                if not settings.aimAssist then return end
                if settings.aimTarget=="off" then return end
                if not player.Character then return end
                local myHRP=player.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
                local nearest,nearDist=nil,settings.aimRange
                for _,p in ipairs(Players:GetPlayers()) do
                    if p~=player and p.Character then
                        local pHRP=p.Character:FindFirstChild("HumanoidRootPart")
                        local pHum=p.Character:FindFirstChild("Humanoid")
                        if pHRP and pHum and pHum.Health>0 then
                            local d=(myHRP.Position-pHRP.Position).Magnitude
                            if d<nearDist then nearDist=d; nearest=p end
                        end
                    end
                end
                if nearest and nearest.Character then
                    local targetPart
                    if settings.aimTarget=="head" then targetPart=nearest.Character:FindFirstChild("Head")
                    elseif settings.aimTarget=="body" then targetPart=nearest.Character:FindFirstChild("HumanoidRootPart") end
                    if targetPart then
                        local cam=workspace.CurrentCamera
                        local dir=(targetPart.Position-cam.CFrame.Position).Unit
                        cam.CFrame=CFrame.new(cam.CFrame.Position,cam.CFrame.Position+dir)
                    end
                end
            end)
        else
            pcall(function() RunService:UnbindFromRenderStep("AimAssist") end)
        end
    end)
end

-- ============================================================
--  SECTION: MENUS (Simplified - No Remote Functions)
-- ============================================================
sectionFunctions["MENUS"]=function()
    createSectionTitle("MENUS")
    createButton("REJOIN",function() game:GetService("TeleportService"):Teleport(game.PlaceId,player) end)
    createButton("CLOSE MENU",function() mainFrame.Visible=false end)
    createToggle("Instant Prompt","instantPrompt",function(on)
        for _,o in ipairs(workspace:GetDescendants()) do if o:IsA("ProximityPrompt") then o.HoldDuration=on and 0.1 or 1 end end
    end)

    createInfoLabel("── Save Features ──")
    createInfoLabel("Save/Load disabled - Remote functions not found")
    createInfoLabel("All other features work normally")
    
    createInfoLabel("── Theme ──")
    createInfoLabel("Theme customization available in full version")
end

-- ============================================================
--  SECTION: DEFENDER
-- ============================================================
sectionFunctions["DEFENDER"]=function()
    createSectionTitle("DEFENDER")
    createToggle("Anti-Fling","antiFling",function(on)
        if antiFlingConn then antiFlingConn:Disconnect(); antiFlingConn=nil end
        if on then antiFlingConn=RunService.Heartbeat:Connect(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp=player.Character.HumanoidRootPart
                if hrp.AssemblyLinearVelocity.Magnitude>100 then hrp.AssemblyLinearVelocity=Vector3.zero end
            end
        end) end
    end)
    createToggle("Anti-Void","antiVoid",function(on)
        if antiVoidConn then antiVoidConn:Disconnect(); antiVoidConn=nil end
        if on then antiVoidConn=RunService.Heartbeat:Connect(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp=player.Character.HumanoidRootPart
                if hrp.Position.Y<-50 then hrp.CFrame=CFrame.new(hrp.Position.X,50,hrp.Position.Z) end
            end
        end) end
    end)
    createToggle("Anti-KnockBack","antiKnockback",function(on)
        if antiKBConn then antiKBConn:Disconnect(); antiKBConn=nil end
        if on then antiKBConn=RunService.Heartbeat:Connect(function()
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp=player.Character.HumanoidRootPart; local v=hrp.AssemblyLinearVelocity
                if math.abs(v.X)>30 or math.abs(v.Z)>30 then hrp.AssemblyLinearVelocity=Vector3.new(0,v.Y,0) end
            end
        end) end
    end)
    createToggle("God Mode","godMode",function(on)
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.MaxHealth=on and 9e9 or 100
            player.Character.Humanoid.Health=on and 9e9 or 100
        end
    end)
end

-- ============================================================
--  SECTION: VISUAL
-- ============================================================
local function clearESP()
    for _,d in pairs(espObjects) do
        if d.highlight then d.highlight:Destroy() end
        if d.billboard then d.billboard:Destroy() end
    end; espObjects={}
end

local function buildESPFor(p)
    if p==player then return end
    local char=p.Character; if not char then return end
    local d={}
    if settings.espHighlight then
        local hl=Instance.new("Highlight"); hl.FillColor=Color3.fromRGB(255,0,0)
        hl.OutlineColor=Color3.fromRGB(255,255,0); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Parent=char; d.highlight=hl
    end
    local head=char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
    if head and (settings.espName or settings.espStatus or settings.espHealth or settings.espTool) then
        local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,200,0,100)
        bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.Parent=head
        local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1
        tl.TextColor3=C_WHITE; tl.TextSize=14; tl.Font=Enum.Font.GothamBold
        tl.TextStrokeTransparency=0.5; tl.TextWrapped=true; tl.Parent=bb
        local function ut()
            local t=""
            if settings.espName then t=t..p.DisplayName.."\n" end
            if settings.espStatus then local h=char:FindFirstChild("Humanoid") t=t..(h and h.Health>0 and "● Alive" or "✕ Dead").."\n" end
            if settings.espHealth then local h=char:FindFirstChild("Humanoid") t=t.."HP: "..(h and math.floor(h.Health) or "0").."\n" end
            if settings.espTool then local tool=char:FindFirstChildOfClass("Tool") if tool then t=t.."[HAS] "..tool.Name end end
            tl.Text=t
        end
        ut(); task.spawn(function() while bb and bb.Parent and settings.esp do ut() task.wait(0.5) end end)
        d.billboard=bb
    end
    espObjects[p]=d
end

local function clearToolESP()
    for _,v in pairs(espToolObjects) do if v and v.Parent then v:Destroy() end end; espToolObjects={}
end

local toolESPConn
local function startToolESP()
    clearToolESP()
    toolESPConn=RunService.Heartbeat:Connect(function()
        if not settings.espNearbyTools then return end
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") and not obj:IsDescendantOf(Players) and not espToolObjects[obj] then
                local hrp2=obj:FindFirstChild("Handle") or obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                if hrp2 then
                    local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,140,0,40)
                    bb.StudsOffset=Vector3.new(0,2,0); bb.AlwaysOnTop=true; bb.Parent=hrp2
                    local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,0,1,0)
                    tl.BackgroundTransparency=1; tl.Text="🔧 "..obj.Name
                    tl.TextColor3=Color3.fromRGB(255,220,80); tl.TextSize=13
                    tl.Font=Enum.Font.GothamBold; tl.TextStrokeTransparency=0.4; tl.Parent=bb
                    espToolObjects[obj]=bb
                end
            end
        end
        for obj,bb in pairs(espToolObjects) do
            if not obj or not obj.Parent then if bb and bb.Parent then bb:Destroy() end espToolObjects[obj]=nil end
        end
    end)
end

sectionFunctions["VISUAL"]=function()
    createSectionTitle("VISUAL")
    createInfoLabel("[INFO: ESP helps in hide-and-seek mode!]")
    createToggle("ESP","esp",function(on)
        if on then for _,p in ipairs(Players:GetPlayers()) do buildESPFor(p) end
        else clearESP() end
    end)
    createToggle("ESP Name","espName",function() end)
    createToggle("ESP Highlight","espHighlight",function() end)
    createToggle("ESP Status","espStatus",function() end)
    createToggle("ESP Health","espHealth",function() end)
    createToggle("ESP Tool","espTool",function() end)
    createToggle("ESP Nearby Tools","espNearbyTools",function(on)
        if on then startToolESP()
        else
            if toolESPConn then toolESPConn:Disconnect(); toolESPConn=nil end
            clearToolESP()
        end
    end)
end

-- ============================================================
--  SECTION: GAME CONTROLLER
-- ============================================================
sectionFunctions["GAME CTRL"]=function()
    createSectionTitle("GAME CONTROLLER")

    createInfoLabel("── Teleport ──")
    local _,userBox=createTextInput("Teleport to","Username",function(name)
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Name:lower()==name:lower() or p.DisplayName:lower()==name:lower() then
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local myChar=player.Character
                    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
                        myChar.HumanoidRootPart.CFrame=p.Character.HumanoidRootPart.CFrame+Vector3.new(0,3,0)
                    end
                end
                return
            end
        end
    end)

    createInfoLabel("── Troll & Prank ──")
    createToggle("Fling Touch","flingTouch",function(on)
        if flingTouchConn then flingTouchConn:Disconnect(); flingTouchConn=nil end
        if on then
            local char=player.Character
            if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            flingTouchConn=hrp.Touched:Connect(function(hit)
                if not settings.flingTouch then return end
                local hitChar=hit.Parent
                local hitHum=hitChar and hitChar:FindFirstChildOfClass("Humanoid")
                if hitHum and hitChar~=char then
                    local hitHRP=hitChar:FindFirstChild("HumanoidRootPart")
                    if hitHRP then
                        local dir=(hitHRP.Position-hrp.Position).Unit
                        hitHRP.AssemblyLinearVelocity=dir*250+Vector3.new(0,120,0)
                    end
                end
            end)
        end
    end)

    createInfoLabel("── Anti-Attack (NPC) ──")
    createToggle("Anti-Attack NPC","antiNPC",function(on)
        if player.Character then
            local hum=player.Character:FindFirstChild("Humanoid")
            if hum then
                if on then
                    originalPlayerName=hum.DisplayDistanceType
                    hum.Name="npc"
                else
                    hum.Name="Humanoid"
                end
            end
        end
    end)
end

-- ============================================================
--  SECTION: OTHERS
-- ============================================================
sectionFunctions["OTHERS"]=function()
    createSectionTitle("OTHERS")
    createInfoLabel("Design: Me & Claude")
    createInfoLabel("By: Zeno")
    createInfoLabel("Co-pilot: Claude 4.6")
    createInfoLabel("Version: Fixed Edition")
    createInfoLabel("")
    createInfoLabel("All features working except cloud saves")
    createInfoLabel("(Remote functions not found in game)")
end

-- ============================================================
--  Nav Button Factory
-- ============================================================
local navSections={
    {name="SETTINGS",  order=1},
    {name="LOCALPLAYER",order=2},
    {name="ASSIST",    order=3},
    {name="MENUS",     order=4},
    {name="DEFENDER",  order=5},
    {name="VISUAL",    order=6},
    {name="GAME CTRL", order=7},
    {name="OTHERS",    order=8},
}

for _,sec in ipairs(navSections) do
    local btn=Instance.new("TextButton")
    btn.Name=sec.name; btn.Size=UDim2.new(0,105,1,0)
    btn.BackgroundColor3=Color3.fromRGB(26,26,26); btn.Text=sec.name
    btn.TextColor3=C_WHITE; btn.TextSize=11; btn.Font=Enum.Font.GothamBold
    btn.LayoutOrder=sec.order; btn.BorderSizePixel=0; btn.Parent=navScroll
    local s=Instance.new("UIStroke"); s.Color=Color3.fromRGB(51,51,51); s.Thickness=1; s.Parent=btn
    btn.MouseButton1Click:Connect(function() showSection(sec.name) end)
end

-- ============================================================
--  Open / Close
-- ============================================================
openButton.MouseButton1Click:Connect(function()
    mainFrame.Visible=not mainFrame.Visible
    if mainFrame.Visible then showSection("SETTINGS") end
end)
closeButton.MouseButton1Click:Connect(function() mainFrame.Visible=false end)

-- ============================================================
--  Respawn handler — re-apply active states
-- ============================================================
player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if settings.smallAvatar then
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum then hum.BodyHeightScale.Value=0.3;hum.BodyWidthScale.Value=0.3;hum.BodyDepthScale.Value=0.3;hum.HeadScale.Value=0.3 end
    end
    if settings.godMode then local h=char:FindFirstChild("Humanoid") if h then h.MaxHealth=9e9;h.Health=9e9 end end
    if settings.esp then task.wait(0.5) for _,p in ipairs(Players:GetPlayers()) do buildESPFor(p) end end
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() task.wait(0.5) if settings.esp then buildESPFor(p) end end)
end)
Players.PlayerRemoving:Connect(function(p)
    if espObjects[p] then
        if espObjects[p].highlight then espObjects[p].highlight:Destroy() end
        if espObjects[p].billboard then espObjects[p].billboard:Destroy() end
        espObjects[p]=nil
    end
end)

print("KYZENO X PANEL v3.0 FIXED - Loaded successfully!")
