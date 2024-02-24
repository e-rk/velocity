extends Node
class_name DirectoryWatcher

enum WatcherMode {
	ALL,
	DIRECTORIES_ONLY,
	FILES_ONLY,
}

@export_dir var directory: String
@export var mode: WatcherMode

var files: Array[String]:
	set(value):
		files = value
	get:
		return files

signal content_changed;

func _ready():
	self._refresh_contents.call_deferred()

func _refresh_contents():
	var files: Array[String] = []
	var dir = DirAccess.open(directory)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		match mode:
			WatcherMode.ALL:
				files.append(file_name)
			WatcherMode.DIRECTORIES_ONLY when dir.current_is_dir():
				files.append(file_name)
			WatcherMode.FILES_ONLY when not dir.current_is_dir():
				files.append(file_name)
		file_name = dir.get_next()
	if self.files != files:
		self.files = files
		self.content_changed.emit()
