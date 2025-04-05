extends Control


@onready var label: Label = $Label


func set_preview_image(path: String) -> void:
	$PanelContainer/TextureRect.texture = load(path)


func set_preview_title(title: String) -> void:
	label.text = title
