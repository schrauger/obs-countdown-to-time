obs           = obslua
source_name   = ""

start_time_hours = 0
start_time_minutes = 0
start_time_seconds = 0

last_text     = ""
stop_text     = ""
prefix_text   = ""
postfix_text  = ""
activated     = false

-- Function to set the time text
function set_time_text()

	local remaining_time = calculate_time(start_time_hours, start_time_minutes, start_time_seconds)
	
	local text = ""
	local time_text = ""
	
	if remaining_time.hours > 0 then
		-- Format hours without leading zeros.
		-- Minutes and seconds should be padded.
		time_text          = string.format("%01d:%02d:%02d", remaining_time.hours, remaining_time.minutes, remaining_time.seconds)
		
	elseif remaining_time.minutes > 0 then
		-- If no hours, just minutes left, we don't want to pad the minutes with extra zeroes.
		time_text          = string.format("%01d:%02d", remaining_time.minutes, remaining_time.seconds)

	else
		-- Only seconds to go. Don't zero pad the final seconds.
		time_text          = string.format("%01d", remaining_time.seconds)

	end
	
	text = prefix_text .. time_text .. postfix_text
	
	if remaining_time.total_seconds <= 0 then
		text = stop_text
	end

	if text ~= last_text then
		local source = obs.obs_get_source_by_name(source_name)
		if source ~= nil then
			local settings = obs.obs_data_create()
			obs.obs_data_set_string(settings, "text", text)
			obs.obs_source_update(source, settings)
			obs.obs_data_release(settings)
			obs.obs_source_release(source)
		end
	end

	last_text = text
end

-- assume we always want top of the minute (00 seconds)
function calculate_time(hour, minute, second)

	-- current_time = os.date("*t")
	current_time = os.time()
	desired_start_time = os.time{hour = hour, min = minute, sec = second, day = os.date('%d'), month = os.date('%m'), year = os.date('%Y')}
	
	remaining_total_seconds = desired_start_time - current_time
	remaining_hours = math.floor(remaining_total_seconds / 60 / 60)
	remaining_minutes = math.floor(remaining_total_seconds / 60 % 60)
	remaining_seconds = math.floor(remaining_total_seconds % 60 % 60)
	return {hours = remaining_hours, minutes = remaining_minutes, seconds = remaining_seconds, total_seconds = remaining_total_seconds}
	
end

function timer_callback()
	remaining_time = calculate_time(start_time_hours, start_time_minutes, start_time_seconds)
	
	if remaining_time.total_seconds < 0 then
		obs.remove_current_callback()
	end

	set_time_text()
end

function activate(activating)
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		set_time_text()
		obs.timer_add(timer_callback, 100)
	else
		obs.timer_remove(timer_callback)
	end
end

-- Called when a source is activated/deactivated
function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source")
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		end
	end
end

function source_activated(cd)
	activate_signal(cd, true)
end

function source_deactivated(cd)
	activate_signal(cd, true)
end

function reset(pressed)
	if not pressed then
		return
	end

	activate(false)
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local active = obs.obs_source_active(source)
		obs.obs_source_release(source)
		activate(active)
	end
end

function reset_button_clicked(props, p)
	reset(true)
	return false
end

----------------------------------------------------------

-- A function named script_properties defines the properties that the user
-- can change for the entire script module itself
function script_properties()
	local props = obs.obs_properties_create()
	obs.obs_properties_add_int(props, "timetostarthour", "Event Start Time Hour (military)", 0, 23, 1)
	obs.obs_properties_add_int(props, "timetostartminute", "Event Start Time Minute", 0, 59, 1)
	obs.obs_properties_add_int(props, "timetostartsecond", "Event Start Time Second", 0, 59, 1)

	local p = obs.obs_properties_add_list(props, "source", "Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_unversioned_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)

	obs.obs_properties_add_text(props, "prefix_text", "Prefix Text", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "postfix_text", "Postfix Text", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "stop_text", "Final Text", obs.OBS_TEXT_DEFAULT)

	return props
end

-- A function named script_description returns the description shown to
-- the user
function script_description()
	return "Sets a text source to act as a countdown timer to a specific time when the source is active.\n\nMade by Stephen Schrauger, adapted from countdown script made by Jim"
end

-- A function named script_update will be called when settings are changed
function script_update(settings)
	activate(false)

	start_time_hours = obs.obs_data_get_int(settings, "timetostarthour")
	start_time_minutes = obs.obs_data_get_int(settings, "timetostartminute")
	start_time_seconds = obs.obs_data_get_int(settings, "timetostartsecond")
	
	source_name = obs.obs_data_get_string(settings, "source")
	stop_text = obs.obs_data_get_string(settings, "stop_text")
	prefix_text = obs.obs_data_get_string(settings, "prefix_text")
	postfix_text = obs.obs_data_get_string(settings, "postfix_text")

	reset(true)
end

-- A function named script_defaults will be called to set the default settings
function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "timetostarthour", 10)
	obs.obs_data_set_default_int(settings, "timetostartminute", 45)
	obs.obs_data_set_default_int(settings, "timetostartsecond", 0)
	obs.obs_data_set_default_string(settings, "prefix_text", "The stream will begin in ")
	obs.obs_data_set_default_string(settings, "postfix_text", "")
	obs.obs_data_set_default_string(settings, "stop_text", "The stream will begin momentarily")
end

-- a function named script_load will be called on startup
function script_load(settings)
	-- Connect hotkey and activation/deactivation signal callbacks
	--
	-- NOTE: These particular script callbacks do not necessarily have to
	-- be disconnected, as callbacks will automatically destroy themselves
	-- if the script is unloaded.  So there's no real need to manually
	-- disconnect callbacks that are intended to last until the script is
	-- unloaded.
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_activate", source_activated)
	obs.signal_handler_connect(sh, "source_deactivate", source_deactivated)

end
