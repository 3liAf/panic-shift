--!strict
--[[
    PANIC SHIFT: InputController.lua
    Unified cross-platform input manager (Keyboard, Touch, Gamepad).
    Handles action bindings for Interact, Sprint, Emote, Shop Toggle,
    and Gamepad B/Keyboard Escape modal dismissal.
]]

local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local InputController = {
    Name = "InputController",
}

local controllers: { [string]: any } = {}

local ACTION_INTERACT = "PanicShift_Interact"
local ACTION_SPRINT = "PanicShift_Sprint"
local ACTION_TOGGLE_SHOP = "PanicShift_ToggleShop"
local ACTION_CLOSE_MODAL = "PanicShift_CloseModal"

function InputController:Init(controllerRegistry: { [string]: any })
    controllers = controllerRegistry
end

function InputController:Start()
    print("[PanicShift InputController] Binding cross-platform actions (PC, Touch, Gamepad)...")

    -- 1. Bind Interact (E / ButtonX / Mobile Touch Button)
    ContextActionService:BindAction(
        ACTION_INTERACT,
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                if controllers.InteractionController then
                    controllers.InteractionController:TriggerCurrentInteraction()
                end
            end
            return Enum.ContextActionResult.Pass
        end,
        true, -- Generates mobile touch button
        Enum.KeyCode.E,
        Enum.KeyCode.ButtonX
    )
    ContextActionService:SetTitle(ACTION_INTERACT, "Interact")
    ContextActionService:SetPosition(ACTION_INTERACT, UDim2.new(1, -120, 1, -140))

    -- 2. Bind Sprint (LeftShift / Gamepad L3)
    ContextActionService:BindAction(
        ACTION_SPRINT,
        function(actionName, inputState, inputObject)
            local character = Players.LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if inputState == Enum.UserInputState.Begin then
                    humanoid.WalkSpeed = 24 -- Sprint speed
                elseif inputState == Enum.UserInputState.End then
                    humanoid.WalkSpeed = 16 -- Normal speed
                end
            end
            return Enum.ContextActionResult.Pass
        end,
        false,
        Enum.KeyCode.LeftShift,
        Enum.KeyCode.ButtonL3
    )

    -- 3. Bind Toggle Shop (M / Gamepad ButtonY)
    ContextActionService:BindAction(
        ACTION_TOGGLE_SHOP,
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                local uiCtrl = controllers.UIController
                if uiCtrl and uiCtrl.ToggleShop then
                    uiCtrl:ToggleShop()
                end
            end
            return Enum.ContextActionResult.Pass
        end,
        false,
        Enum.KeyCode.M,
        Enum.KeyCode.ButtonY
    )

    -- 4. Bind Modal Dismissal (Escape / Gamepad ButtonB)
    ContextActionService:BindAction(
        ACTION_CLOSE_MODAL,
        function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
                local gui = playerGui and playerGui:FindFirstChild("PanicShiftGui")
                if gui then
                    local shop = gui:FindFirstChild("ShopModal")
                    if shop and shop.Visible then shop.Visible = false return Enum.ContextActionResult.Sink end
                    local ch = gui:FindFirstChild("ChallengesModal")
                    if ch and ch.Visible then ch.Visible = false return Enum.ContextActionResult.Sink end
                    local st = gui:FindFirstChild("SettingsModal")
                    if st and st.Visible then st.Visible = false return Enum.ContextActionResult.Sink end
                    local res = gui:FindFirstChild("ResultsModal")
                    if res and res.Visible then res.Visible = false return Enum.ContextActionResult.Sink end
                end
            end
            return Enum.ContextActionResult.Pass
        end,
        false,
        Enum.KeyCode.Escape,
        Enum.KeyCode.ButtonB
    )
end

function InputController:IsTouchDevice(): boolean
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function InputController:IsGamepadConnected(): boolean
    return UserInputService.GamepadEnabled
end

return InputController
