shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// La traînée de `BoltFx` : un ruban posé sur les positions passées de l'orbe, tourné vers la
// caméra, qui garde la forme du zigzag comme celle de Kinetic Bolt. Il porte le tronc de l'éclair
// photographié (`fx/lightning_bolt.png`), répété le long du chemin ; l'âge, dans l'alpha du
// sommet, l'assombrit puis l'éteint.

#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap, repeat_enable;
uniform float boost = 1.1;
instance uniform float opacity = 1.0;

void fragment() {
	vec3 p = texture(photo, vec2(UV.x, mix(0.05, 0.95, UV.y))).rgb;
	float l = max(p.r, max(p.g, p.b));
	ALBEDO = ramp_of(l * mix(0.6, 1.0, COLOR.a)) * boost * pow(COLOR.a, 1.4) * opacity;
}
