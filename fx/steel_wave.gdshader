shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La vague qui vole (`SteelFx.wave`), « croissant et traînées » choisi sur planche : un croissant net — un
// fil clair au bord, un corps strié par la traînée de taille (`fx/steel_slash.png`) qui défile, effilé aux
// pointes, d'où partent deux traînées (`BoltFx.Trail`). UV.x le long, UV.y du dedans (0) au dehors (1).

#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap, repeat_enable;
instance uniform float opacity = 1.0;
instance uniform float dissolve = 0.0;

void fragment() {
	float tips = pow(max(sin(3.14159265 * UV.x), 0.0), 0.8);
	float edge = exp(-pow((UV.y - 0.88) / 0.05, 2.0));
	float body = smoothstep(0.0, 0.88, UV.y) * (1.0 - smoothstep(0.88, 1.0, UV.y));
	float streak = texture(photo, vec2(UV.x * 1.3 - TIME * 2.0, 0.3 + UV.y * 0.4)).r;
	vec3 c = core * edge * 1.4 + tint * body * (0.3 + 0.7 * streak) * 0.9;
	ALBEDO = c * tips * (1.0 - dissolve) * opacity;
}
