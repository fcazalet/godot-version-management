# By Erasor
tool
extends EditorPlugin


# Constants
const PLUGIN_NAME := "Godot-Version-Manager"
const EXPORTS_MAX := 100
const DEBUG := true
# Use same setting as https://github.com/godotengine/godot/pull/35555
const PROJECT_VERSION_SETTING := "application/config/version"
const PROJECT_BUILD_SETTING := "application/config/build"
const EXPORT_PRESETS_FILE := "res://export_presets.cfg"


# Variables
var current_version: String
var current_build: int


# Built-in overrides
func _enter_tree() -> void:
	if not ProjectSettings.has_setting(PROJECT_VERSION_SETTING):
		ProjectSettings.set_setting(PROJECT_VERSION_SETTING, "0.0.1")

	if not ProjectSettings.has_setting(PROJECT_BUILD_SETTING):
		ProjectSettings.set_setting(PROJECT_BUILD_SETTING, 1)

	current_version = ProjectSettings.get_setting(PROJECT_VERSION_SETTING)
	current_build = ProjectSettings.get_setting(PROJECT_BUILD_SETTING)


func _exit_tree() -> void:
	# Do not remove the verson config, may conflict with https://github.com/godotengine/godot/pull/35555
	pass


func apply_changes() -> void:
	_update_export_presets()


func save_external_data() -> void:
	_update_export_presets()


# Private methods
func _update_export_presets() -> void:
	var version_dict := _parse_version(
		ProjectSettings.get_setting(PROJECT_VERSION_SETTING),
		ProjectSettings.get_setting(PROJECT_BUILD_SETTING)
	)

	var version_setting: String = version_dict.get("version")
	var build_setting: int = version_dict.get("build")

	# If config version not changed, do not update all exports
	if version_setting == current_version:
		return

	var export_config := ConfigFile.new()
	var err := export_config.load(EXPORT_PRESETS_FILE)

	if err != OK:
		_plugin_log('Error opening ' + EXPORT_PRESETS_FILE)
		return

	# Loop limited to 100 exports
	for i in range(EXPORTS_MAX):
		var section := "preset." + str(i)

		if not export_config.has_section(section):
			break

		_plugin_log("Update export: '" + export_config.get_value(section, "name") + "'")

		# Update Android exports configs
		if export_config.get_value(section, "platform") == "Android":
			export_config.set_value(section + ".options", 'version/name', version_setting)
			export_config.set_value(section + ".options", 'version/code', build_setting)

		# Update Apple exports configs
		if export_config.get_value(section, "platform") == "iOS" or export_config.get_value(section, "platform") == "Mac OSX":
			export_config.set_value(section + ".options", 'application/short_version', version_setting)
			export_config.set_value(section + ".options", 'application/version', build_setting)

		# Update UWP exports configs
		if export_config.get_value(section, "platform") == "UWP":
			export_config.set_value(section + ".options", 'version/major', version_dict["major"])
			export_config.set_value(section + ".options", 'version/minor', version_dict["minor"])
			export_config.set_value(section + ".options", 'version/build', version_dict["patch"])
			export_config.set_value(section + ".options", 'version/revision', 0)

		# Update Windows exports configs
		if export_config.get_value(section, "platform") == "Windows Desktop":
			var windows_version_setting := version_setting + ".0" if version_setting.split(".").size() == 3 else version_setting
			export_config.set_value(section + ".options", 'application/file_version', windows_version_setting)
			export_config.set_value(section + ".options", 'application/product_version', windows_version_setting)

	err = export_config.save(EXPORT_PRESETS_FILE)
	ProjectSettings.save()

	if err != OK:
		_plugin_log("Error saving " + EXPORT_PRESETS_FILE + ", exports not updated")
		return

	_plugin_log("All exports updated")


func _plugin_log(message: String) -> void:
	if (DEBUG):
		var time := Time.get_datetime_dict_from_system()
		var date_string := "%02d:%02d" % [time.hour, time.minute]
		print(date_string, " - ", PLUGIN_NAME, " - ", message)


func _parse_version(version: String, build: int) -> Dictionary:
	var dict := {
		"version": version,
		"build": build if build >= 0 else 0,
		"major": 0,
		"minor": 0,
		"patch": 0,
	}

	var version_split := version.split(".")

	# Do not generate major.minor.patch
	if version_split.size() < 3:
		return dict

	var major := int(version_split[0])
	var minor := int(version_split[1])
	var patch := int(version_split[2])

	# Generate build number from version string ('2.3.4' == 20304)
	if not build or build < 0:
		dict["build"] = int(str(major) + str(minor).pad_zeros(2) + str(patch).pad_zeros(2))

	dict.merge({
		"major": major,
		"minor": minor,
		"patch": patch,
	}, true)

	return dict

