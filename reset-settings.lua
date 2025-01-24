obs = obslua

local TARGET_SCENE_NAME = "Standart"
local TARGET_NOISE_REDUCTION_FILTER_NAME = "Rauschunterdrückung"

function reset_settings(props, prop)
    reset_scenes()
    reset_aux_filter()
    reset_transition()
end

function reset_scenes()
    obs.script_log(obs.LOG_INFO, "Szenensammlung wird zurückgesetzt...")

    -- Get all scenes
    local scenes = obs.obs_frontend_get_scenes()
    if scenes then
        for _, scene in ipairs(scenes) do
            local scene_name = obs.obs_source_get_name(scene)
            obs.script_log(obs.LOG_INFO, 'Entferne Szene: ' .. scene_name)
            -- Remove the scenes
            obs.obs_source_remove(scene)
        end
        obs.source_list_release(scenes)
    end

    -- Give OBS a moment to process the scene removals before adding new scenes
    obs.os_sleep_ms(100)

    -- Create new default scene
    local new_scene = obs.obs_scene_create(TARGET_SCENE_NAME)
    if new_scene then
        obs.script_log(obs.LOG_INFO, 'Eine neue Standart-Szene wird erstellt')
        -- Set new scene as current scene
        local scene_source = obs.obs_scene_get_source(new_scene)
        obs.obs_frontend_set_current_scene(scene_source)
    end
end

function reset_aux_filter()
    -- Get the AuxAudioDevice1 source
    local source = obs.obs_get_source_by_name("Mikrofon-/AUX-Audio")
    if source == nil then
        obs.script_log(obs.LOG_ERROR, "Konnte die \'Mikrofon-/AUX-Audio\' quelle nicht finden.")
        return
    end

    -- Get the Rauschunterdrückung filter in the source
    local existing_filter = obs.obs_source_get_filter_by_name(source, TARGET_NOISE_REDUCTION_FILTER_NAME)
    -- If the filter exists, remove it
    if existing_filter then 
        obs.obs_source_filter_remove(source, existing_filter)
        obs.obs_source_release(existing_filter)
    end
    
    -- Create a settings object
    local settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "method", "rnnoise")

    -- Create a new noise suppression filter
    local filter = obs.obs_source_create_private("noise_suppress_filter", TARGET_NOISE_REDUCTION_FILTER_NAME, settings)
    if filter then
        obs.obs_source_filter_add(source, filter)
        obs.script_log(obs.LOG_INFO, "Rauschunterdrückungsfilter erfolgreich erstellt.")
    else
        obs.script_log(obs.LOG_ERROR, "Fehler beim erstellen eines neuen Rauschunterdrückungsfilters.")
    end

    -- Free used memory space
    obs.obs_data_release(settings)
    obs.obs_source_release(filter)
    obs.obs_source_release(source)
end

function reset_transition()
    -- Set the duration for the new transition
    local settings = obs.obs_data_create()
    obs.obs_data_set_int(settings, "duration", 300)

    -- Create the new transition
    local new_transition = obs.obs_source_create_private("fade_transition", "Fade", settings)

    if new_transition then
        -- Set the new transition
        obs.obs_frontend_set_current_transition(new_transition)
        obs.script_log(obs.LOG_INFO, "Szenenübergänge erfolgreich gesetzt.")
    else
        obs.script_log(obs.LOG_ERROR, "Fehler beim setzen neuer Szenenübergänge.")
    end

    -- Free used memory space
    obs.obs_data_release(settings)
    obs.obs_source_release(new_transition)
end


function script_description()
    return [[
    Skript zum zurücksetzen aller Einstellungen
    -----------------------------------------------------------------
    Dieses Skript:
        - Setzt alle Szenen zurück
        - Setzt den Rauschunterdrückungsfilter zurück
        - Setzt die Szenenübergänge zurück
    ]]
end


function script_properties()
    local props = obs.obs_properties_create()

    local warning = obs.obs_properties_add_text(props, "warning", "WARNUNG: Dies wird alle Szenen, die aktuell in der Szenensammlung sind löschen!", obs.OBS_TEXT_INFO)

    obs.obs_properties_add_button(props, "reset_button", "Einstellungen zurücksetzen", reset_settings)

    return props
end

function script_load(settings)
    obs.script_log(obs.LOG_INFO, "Skript zum zurücksetzen der Einstellungen erfolgreich geladen.")
end