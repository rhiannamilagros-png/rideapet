-- =========================================================
-- SCOOPHUB RIDE A PET PREMIUM - REMOTE LOW GRAPHICS MODULE
-- =========================================================
-- GitHub-ready remote module.
-- Required bridge created by the Premium core:
--   getgenv().ScoopHubRideAPetPremiumLowGraphicsBridge
--
-- Load this file from the Premium script with game:HttpGet + loadstring.
-- This file may be obfuscated separately before uploading if desired.
-- =========================================================

local function __SCOOPHUB_RUN_PREMIUM_LOW_GRAPHICS()
    local Environment = _G

    pcall(function()
        if type(getgenv) == "function" then
            Environment = getgenv()
        end
    end)

    local Bridge =
        Environment.ScoopHubRideAPetPremiumLowGraphicsBridge

    if type(Bridge) ~= "table" then
        warn(
            "[SCOOPHUB PREMIUM] Low Graphics append module could not find the core bridge. "
            .. "Run it after the separated Premium Ride A Pet core."
        )
        return
    end

    if type(Bridge.DestroyModule) == "function" then
        pcall(function()
            Bridge.DestroyModule()
        end)
    end

    local Workspace = game:GetService("Workspace")

    local LowGraphicsOriginals = {}
    local LowGraphicsConnection = nil
    local LowGraphicsRunId = 0
    local LowGraphicsEnabled = false
    local Destroyed = false

    local function clearTable(target)
        if type(target) ~= "table" then
            return
        end

        for key in pairs(target) do
            target[key] = nil
        end
    end

    local function coreIsClosed()
        if type(Bridge.IsClosed) ~= "function" then
            return false
        end

        local ok, result = pcall(function()
            return Bridge.IsClosed()
        end)

        return ok and result == true
    end

    local function rememberLowGraphicsState(
        object,
        state
    )
        if not LowGraphicsOriginals[object] then
            LowGraphicsOriginals[object] = state
        end
    end

    local function stripWorkspaceTexture(object)
        if Destroyed
            or not object
            or not object.Parent
        then
            return
        end

        local className = object.ClassName

        -- Flatten textured materials while preserving object/model colors.
        if object:IsA("BasePart") then
            local currentMaterial = object.Material

            local currentVariant = nil
            pcall(function()
                currentVariant = object.MaterialVariant
            end)

            local currentReflectance = 0
            pcall(function()
                currentReflectance = object.Reflectance
            end)

            local needsFlatten =
                currentMaterial
                    ~= Enum.Material.SmoothPlastic
                or (
                    type(currentVariant) == "string"
                    and currentVariant ~= ""
                )
                or currentReflectance ~= 0

            if needsFlatten then
                local state = LowGraphicsOriginals[object]

                if not state then
                    state = {
                        Kind = "BasePart",
                        Material = currentMaterial,
                        MaterialVariant = currentVariant,
                        Reflectance = currentReflectance,
                    }

                    LowGraphicsOriginals[object] = state
                else
                    if state.Material == nil then
                        state.Material = currentMaterial
                    end

                    if state.MaterialVariant == nil then
                        state.MaterialVariant = currentVariant
                    end

                    if state.Reflectance == nil then
                        state.Reflectance = currentReflectance
                    end
                end

                pcall(function()
                    object.Material =
                        Enum.Material.SmoothPlastic
                end)

                pcall(function()
                    object.MaterialVariant = ""
                end)

                pcall(function()
                    object.Reflectance = 0
                end)
            end
        end

        -- Normal Roblox Decal/Texture objects.
        if className == "Decal"
            or className == "Texture"
        then
            if object.Transparency < 1 then
                rememberLowGraphicsState(
                    object,
                    {
                        Kind = "ImageTexture",
                        Transparency = object.Transparency,
                    }
                )

                object.Transparency = 1
            end

            return
        end

        -- MeshPart baked/albedo texture.
        if className == "MeshPart" then
            local textureId = object.TextureID

            if textureId ~= "" then
                local state = LowGraphicsOriginals[object]

                if not state then
                    state = {
                        Kind = "MeshPart",
                        TextureID = textureId,
                    }

                    LowGraphicsOriginals[object] = state
                elseif state.TextureID == nil then
                    state.TextureID = textureId
                end

                object.TextureID = ""
            end

            return
        end

        -- Legacy meshes.
        if className == "SpecialMesh" then
            local textureId = object.TextureId

            if textureId ~= "" then
                rememberLowGraphicsState(
                    object,
                    {
                        Kind = "SpecialMesh",
                        TextureId = textureId,
                    }
                )

                object.TextureId = ""
            end

            return
        end

        -- PBR SurfaceAppearance maps.
        if className == "SurfaceAppearance" then
            local colorMap = object.ColorMap
            local metalnessMap = object.MetalnessMap
            local normalMap = object.NormalMap
            local roughnessMap = object.RoughnessMap

            if colorMap ~= ""
                or metalnessMap ~= ""
                or normalMap ~= ""
                or roughnessMap ~= ""
            then
                rememberLowGraphicsState(
                    object,
                    {
                        Kind = "SurfaceAppearance",
                        ColorMap = colorMap,
                        MetalnessMap = metalnessMap,
                        NormalMap = normalMap,
                        RoughnessMap = roughnessMap,
                    }
                )

                object.ColorMap = ""
                object.MetalnessMap = ""
                object.NormalMap = ""
                object.RoughnessMap = ""
            end

            return
        end

        -- Decorative VFX only; gameplay objects themselves remain intact.
        if className == "ParticleEmitter"
            or className == "Trail"
            or className == "Beam"
            or className == "Smoke"
            or className == "Fire"
            or className == "Sparkles"
            or className == "Highlight"
            or className == "PointLight"
            or className == "SpotLight"
            or className == "SurfaceLight"
        then
            local ok, enabled = pcall(function()
                return object.Enabled
            end)

            if ok and enabled ~= false then
                rememberLowGraphicsState(
                    object,
                    {
                        Kind = "VisualEffect",
                        Enabled = enabled,
                    }
                )

                pcall(function()
                    object.Enabled = false
                end)
            end

            return
        end
    end

    local function restoreWorkspaceTextures()
        for object, state in pairs(
            LowGraphicsOriginals
        ) do
            if object
                and object.Parent
                and type(state) == "table"
            then
                local kind = state.Kind

                if kind == "BasePart" then
                    pcall(function()
                        object.Material = state.Material
                    end)

                    pcall(function()
                        object.MaterialVariant =
                            state.MaterialVariant or ""
                    end)

                    pcall(function()
                        object.Reflectance =
                            state.Reflectance or 0
                    end)

                elseif kind == "ImageTexture" then
                    pcall(function()
                        object.Transparency =
                            state.Transparency
                    end)

                elseif kind == "MeshPart" then
                    pcall(function()
                        object.TextureID =
                            state.TextureID or ""
                    end)

                elseif kind == "SpecialMesh" then
                    pcall(function()
                        object.TextureId =
                            state.TextureId or ""
                    end)

                elseif kind == "SurfaceAppearance" then
                    pcall(function()
                        object.ColorMap =
                            state.ColorMap or ""

                        object.MetalnessMap =
                            state.MetalnessMap or ""

                        object.NormalMap =
                            state.NormalMap or ""

                        object.RoughnessMap =
                            state.RoughnessMap or ""
                    end)

                elseif kind == "VisualEffect" then
                    pcall(function()
                        object.Enabled = state.Enabled
                    end)
                end
            end
        end

        clearTable(LowGraphicsOriginals)
    end

    local function disconnectLowGraphicsWatcher()
        if LowGraphicsConnection then
            pcall(function()
                LowGraphicsConnection:Disconnect()
            end)

            LowGraphicsConnection = nil
        end
    end

    local function startLowGraphicsPass(runId)
        local descendants = Workspace:GetDescendants()

        -- Same behavior as the original embedded implementation:
        -- process every existing Workspace object immediately.
        for index = 1, #descendants do
            if Destroyed
                or coreIsClosed()
                or not LowGraphicsEnabled
                or LowGraphicsRunId ~= runId
            then
                return
            end

            stripWorkspaceTexture(descendants[index])
        end
    end

    local function setLowGraphicsMode(enabled)
        if Destroyed then
            return false
        end

        enabled = enabled == true

        if LowGraphicsEnabled == enabled then
            return true
        end

        LowGraphicsEnabled = enabled
        LowGraphicsRunId = LowGraphicsRunId + 1

        disconnectLowGraphicsWatcher()

        if not enabled then
            restoreWorkspaceTextures()
            return true
        end

        if coreIsClosed() then
            LowGraphicsEnabled = false
            return false
        end

        local runId = LowGraphicsRunId

        startLowGraphicsPass(runId)

        if not LowGraphicsEnabled
            or Destroyed
            or coreIsClosed()
        then
            return false
        end

        -- Strip textures/VFX from objects that appear after the initial pass.
        LowGraphicsConnection =
            Workspace.DescendantAdded:Connect(
                function(object)
                    if LowGraphicsEnabled
                        and not Destroyed
                        and not coreIsClosed()
                        and LowGraphicsRunId == runId
                    then
                        stripWorkspaceTexture(object)
                    end
                end
            )

        return true
    end

    local function destroyModule()
        if Destroyed then
            return
        end

        -- Restore before marking destroyed because setLowGraphicsMode checks it.
        setLowGraphicsMode(false)
        Destroyed = true
        LowGraphicsRunId = LowGraphicsRunId + 1
        disconnectLowGraphicsWatcher()

        if Bridge.SetEnabled == setLowGraphicsMode then
            Bridge.SetEnabled = nil
        end

        if Bridge.DestroyModule == destroyModule then
            Bridge.DestroyModule = nil
        end

        Bridge.ModuleReady = false
    end

    -- Export only the tiny public surface the obfuscated core needs.
    Bridge.SetEnabled = setLowGraphicsMode
    Bridge.DestroyModule = destroyModule
    Bridge.ModuleReady = true
    Bridge.ModuleVersion = "RideAPet-Premium-LowGraphics-V1"

    -- Consume a toggle action that happened while this readable module was not
    -- loaded yet. If there is no pending action, mirror the core's saved state.
    local desired = Bridge.PendingEnabled

    if desired == nil
        and type(Bridge.GetEnabled) == "function"
    then
        pcall(function()
            desired = Bridge.GetEnabled()
        end)
    end

    Bridge.PendingEnabled = nil
    setLowGraphicsMode(desired == true)
end

__SCOOPHUB_RUN_PREMIUM_LOW_GRAPHICS()

