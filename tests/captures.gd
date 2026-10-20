extends RefCounted
## Where the test tools write their images.
##
## Three tools capture pixels: the responsive matrix, the cooking-stage test and the
## general visual capture. Each used to name an absolute path inside one developer's
## temp folder. That path existed on no other machine, so the documented command did
## nothing for anyone else, and it died with the temp folder, so the screenshots the
## presentation and the board need disappeared between runs.
##
## The folder now comes from the project itself: `build/screenshots/<name>` sits next
## to the code that produced the image, is ignored by git like the rest of `build/`,
## and `build/*` is in every export preset's exclude filter, so captures never travel
## inside a build.

## Creates `build/screenshots/<name>` if it is missing and returns its absolute OS
## path, ready for `Image.save_png` or `FileAccess.open`.
static func open(folder: String) -> String:
	var path := ProjectSettings.globalize_path("res://build/screenshots/%s" % folder)
	DirAccess.make_dir_recursive_absolute(path)
	return path
