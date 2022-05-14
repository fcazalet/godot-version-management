# <img src="https://github.com/fcazalet/godot-version-management/blob/main/icon.svg" width="64" height="64"> Godot Version Manager

This addon is for developpers that want a centralized place for version naming / build number and then display it in game.
It allow you to configure version and build in project settings.
These configurations are synchronized to all existing export of your project.
Moreover configurations can be loaded for in game display.

## How to install it

You can find this addon in Godot AssetLibrary
See the Godot Addon install section : https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html

## How to use it for exports

Once the addon activated it add two entry in your project configuration:

- Application / Config / Version as String (application/config/version default to 0.0.1)
- Application / Config / Build as Integer (application/config/build default to 1)

You can change the version and the build numbers.
It will update all your exports versions value to the project config value.
Then you need to reload the project (Project / Reload current project). See below section to know why you need to reload project.

For Android exports:
* version is version/name
* build is version/code

For iOS and MacOS exports:
* version is application/short_version
* build is application/version

For Windows Desktop exports:
* version is application/file_version and application/product_version

For HTML5 and UWP exports no versions specified.

## How to use it for in game display

The version and build numbers can be accessed for in game use like that:


```GDScript
	# To get version string
	var version = ProjectSettings.get_setting("application/config/version")
	# To get build number
	var build = ProjectSettings.get_setting("application/config/build")
```

	


## Why I need to reload project ?

The GodotVersionManager addon update the export-presets.cfg file.
Because of Godot keep in memory ExportsSettings and do not reload it from export-presets.cfg file you will need to reload your project.
When project is loaded Godot load in memory the export-presets.cfg .
