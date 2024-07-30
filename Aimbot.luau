getgenv().Settings = {
	Keybind = "Q",
    AimPart = "Head", -- Which part you want to be aiming at
	TargetRadius = 100 -- How far the target has to be (maximum)
}

local cloneref = cloneref or function(...)
	return ...
end

-- services
local run_service: RunService = cloneref(game:GetService("RunService"))
local input_service: UserInputService = cloneref(game:GetService("UserInputService"))
local players: Players = cloneref(game:GetService("Players"))
if not players.LocalPlayer then
	players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

-- other
local local_player: Player = cloneref(players.LocalPlayer)
local camera: Camera = cloneref(workspace:FindFirstChildOfClass("Camera"))
local aimbot_target: Player? = nil

-- namecall
local get_children: (self: Players) -> { Player } = game.GetChildren
local find_first_child_of_class: (self: Instance, class_name: string) -> Instance = game.FindFirstChildOfClass
local world_to_viewportpoint: (self: Camera, world_point: Vector3) -> (Vector3, boolean) = camera.WorldToViewportPoint
local get_mouse_location: (self: UserInputService) -> Vector2 = input_service.getMouseLocation

--	data type
local vector2_new: (x: number?, y: number?) -> Vector2 = Vector2.new
local cframe_new: (...any) -> CFrame = CFrame.new
local enum_keycode: Enum = Enum.KeyCode

-- string
local string_upper: (_: string) -> string = string.upper
local string_sub: (self: string, _: number, _: number?) -> string = string.sub

-- math
local inf: number = math.huge

local find_closest_character = function(TARGET_RADIUS: number): Model
	-- Gets Mouse's position on screen
	local MOUSE_POSITION: Vector2 = get_mouse_location(input_service)

	-- Initialize the shortest_distance and the closest_character
	local shortest_distance: number = TARGET_RADIUS or inf
	local closest_character: Player? = nil

	for _, player in next, get_children(players) do

        -- You don't want to aimbot on yourself right
		if player == local_player then
			continue
		end

		local character: Model = player.Character
        -- Makes sure player has a character and humanoid
		if not (character and find_first_child_of_class(character, "Humanoid")) then
			continue
		end

        -- Gets Player position on screen and if player is in client's viewport
		local screen_point: Vector3, in_viewport: boolean = world_to_viewportpoint(camera, character.PrimaryPart.Position)

        -- Makes sure player is in viewport
		if not in_viewport then
			continue
		end

        -- Gets player's distance from client's mouse
		local MAGNITUDE: number = (vector2_new(screen_point.X, screen_point.Y) - MOUSE_POSITION).Magnitude
        -- Makes sure the distance from player is smaller than the old one
		if MAGNITUDE > shortest_distance then
			continue
		end

        -- Assign current character to the closestCharacter and it's distance from client's mouse
		closest_character = character
		shortest_distance = MAGNITUDE
	end

    -- Return the closest character
	return closest_character
end

run_service.RenderStepped:Connect(function(deltaTime: number): RBXScriptSignal

    -- Makes sure aimbot_target exists
	if aimbot_target == nil then
		return
	end

    -- Makes sure aimbot_target character and humanoid exist
	if not (aimbot_target and aimbot_target.Humanoid) then
		return
	end

    -- Edit camera's cframe to new cframe
	camera.CFrame = cframe_new(camera.CFrame.Position, aimbot_target.HumanoidRootPart.Position)
end)

input_service.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean): RBXScriptSignal
    -- Makes sur game didn't process the input
	if gameProcessedEvent then
		return
	end

    -- Makes sure the input's key is the one we want (upper and sub are used in case user set keybind as a lowercase or put multiple characters)
	if input.KeyCode ~= enum_keycode[string_upper(string_sub(Settings.Keybind, 1, 1))] then
		return
	end

    -- Assign a character to the aimbot_target variable or clear it if we already have a character in our variable
	aimbot_target = not aimbot_target and find_closest_character(Settings.TargetRadius)
end)
