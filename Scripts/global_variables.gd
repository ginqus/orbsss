extends Node


const CONFIG_DIR: String = "user://settings.ini"

var is_just_started: bool = true

# This is needed for the back gesture on Android. Normally, every single script
# in the scene would detect this gesture and trigger something simultaneously,
# which is not good. For this reason, we introduce a new array that should keep
# track of the order that the popups were activated so that we can trigger the
# back gesture only for the topmost element in the scene.
var popup_order: Array = []

var blue_orb_color:   Color = Color.from_rgba8(120, 165, 215)
var purple_orb_color: Color = Color.from_rgba8(192, 128, 255)
var green_orb_color:  Color = Color.from_rgba8(128, 255, 192)
var yellow_orb_color: Color = Color.from_rgba8(240, 200, 0)
var player_color:     Color = Color.from_rgba8(230, 240, 255)


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)


func blur_image(image: Image) -> Image:
	image.generate_mipmaps()  # Needed for the resizing, would look worse without
	var aspect_ratio: float = float(image.get_height()) / float(image.get_width())

	# Yep, that's how we blur the image. Just resize it multiple times.
	#image.resize(16, int(16 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	#image.resize(24, int(24 * aspect_ratio), Image.INTERPOLATE_BILINEAR)
	#image.resize(32, int(32 * aspect_ratio), Image.INTERPOLATE_BILINEAR)
	#image.resize(48, int(48 * aspect_ratio), Image.INTERPOLATE_BILINEAR)
	#image.resize(64, int(64 * aspect_ratio), Image.INTERPOLATE_BILINEAR)
	#image.resize(96, int(96 * aspect_ratio), Image.INTERPOLATE_BILINEAR)
	#image.resize(128, int(128 * aspect_ratio), Image.INTERPOLATE_BILINEAR)
	#image.resize(192, int(192 * aspect_ratio), Image.INTERPOLATE_BILINEAR)

	image.resize(256, int(256 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(192, int(192 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(128, int(128 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(96, int(96 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(64, int(64 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(48, int(48 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(32, int(32 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(24, int(24 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(16, int(16 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(24, int(24 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(32, int(32 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(48, int(48 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(64, int(64 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(96, int(96 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(128, int(128 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(192, int(192 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	image.resize(256, int(256 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)

	#image.resize(32, int(32 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	#image.resize(24, int(24 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	#image.resize(16, int(16 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	#image.resize(24, int(24 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	#image.resize(32, int(32 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	#image.resize(128, int(128 * aspect_ratio), Image.INTERPOLATE_TRILINEAR)
	return image
