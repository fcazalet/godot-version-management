# By Erasor
tool
extends EditorPlugin

const PLUGIN_NAME = "Godot-Version-Manager"
const DEBUG = true
# Use same name as https://github.com/godotengine/godot/pull/35555
const PROJECT_VERSION_SETTING = "application/config/version"
const PROJECT_BUILD_SETTING = "application/config/build"
const EXPORT_PRESETS_FILE = "res://export_presets.cfg" 
var current_version
var current_build

func _enter_tree():
	if not ProjectSettings.has_setting(PROJECT_VERSION_SETTING):
		ProjectSettings.set_setting(PROJECT_VERSION_SETTING, "0.0.1")
	if not ProjectSettings.has_setting(PROJECT_BUILD_SETTING):
		ProjectSettings.set_setting(PROJECT_BUILD_SETTING, 1)
	current_version = ProjectSettings.get_setting(PROJECT_VERSION_SETTING)
	current_build = ProjectSettings.get_setting(PROJECT_BUILD_SETTING)


func _exit_tree():
	# Do not remove the verson config, may conflict with https://github.com/godotengine/godot/pull/35555
	pass


func apply_changes():
	_update_export_presets()


func save_external_data():
	_update_export_presets()


func _update_export_presets():
	# If config version changed, update all exports
	if ProjectSettings.get_setting(PROJECT_VERSION_SETTING) != current_version:
		var export_config: ConfigFile = ConfigFile.new()
		var err = export_config.load(EXPORT_PRESETS_FILE)
		if err == OK:
			# Loop limited to 100 exports
			for i in range(0, 100):
				var section = "preset." + str(i)
				if export_config.has_section(section):
					plugin_log("Update Export " + export_config.get_value(section, "platform"))
					# Update Android exports configs
					if export_config.get_value(section, "platform") == "Android":
						export_config.set_value(section + ".options", 'version/name', ProjectSettings.get_setting(PROJECT_VERSION_SETTING))
						export_config.set_value(section + ".options", 'version/code', ProjectSettings.get_setting(PROJECT_BUILD_SETTING))
					if export_config.get_value(section, "platform") == "iOS" or export_config.get_value(section, "platform") == "Mac OSX":
						export_config.set_value(section + ".options", 'application/short_version', ProjectSettings.get_setting(PROJECT_VERSION_SETTING))
						export_config.set_value(section + ".options", 'application/version', ProjectSettings.get_setting(PROJECT_BUILD_SETTING))
					if export_config.get_value(section, "platform") == "UWP":
						# TODO parsing of version to minor/major
						pass
					if export_config.get_value(section, "platform") == "Windows Desktop":
						export_config.set_value(section + ".options", 'application/file_version', ProjectSettings.get_setting(PROJECT_VERSION_SETTING))
						export_config.set_value(section + ".options", 'application/product_version', ProjectSettings.get_setting(PROJECT_VERSION_SETTING))
				else:
					break
			err = export_config.save(EXPORT_PRESETS_FILE)
			ProjectSettings.save()
			if err == OK:
				plugin_log("All exports updated")
			else:
				plugin_log("Error saving " + EXPORT_PRESETS_FILE + ", exports not updated")
		else:
			plugin_log('Error open ' + EXPORT_PRESETS_FILE)


func plugin_log(message):
	if (DEBUG):
		var time : Dictionary = OS.get_datetime()
		var date_string : String = "%02d:%02d" % [time.hour, time.minute]
		print(date_string, " - ", PLUGIN_NAME, " - ", message)
	

