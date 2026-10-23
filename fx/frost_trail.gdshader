shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// La traînée du Trait de glace (`BoltFx.Trail` en froid) : une traînée de givre photographiée
// (`fx/frost_streak.png`), mêlée comme l'orbe ; l'âge, dans l'alpha du sommet, l'éteint.

#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap, repeat_enable;
instance uniform float opacity = 1.0;

void fragment() {
	vec3 p = texture(photo, UV).rgb;
	float l = max(p.r, max(p.g, p.b));
	ALBEDO = ramp_of(l * 0.85 * mix(0.6, 1.0, COLOR.a));
	ALPHA = clamp(l * 1.6, 0.0, 1.0) * pow(COLOR.a, 1.2) * opacity;
}
