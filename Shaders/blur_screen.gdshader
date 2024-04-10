shader_type canvas_item;

uniform float blur_intensity = 4;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap, repeat_disable;

void fragment() {
    vec3 rgb = textureLod(screen_texture, SCREEN_UV, blur_intensity).xyz;
    COLOR = vec4(rgb, COLOR.a);
}
