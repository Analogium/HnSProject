shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Une langue de feu posée au sol (`FireRing`) : debout, tournée vers la caméra autour de la
// verticale, large en bas, tordue vers la pointe, rongée en vieillissant. Ronde comme les
// flammèches de la boule, elle ne se lisait pas : vue d'en haut, monter ne se voit pas.

#include "res://fx/flame_common.gdshaderinc"

instance uniform float opacity = 1.0;
varying float age;
varying float seed;

void vertex() {
	age = INSTANCE_CUSTOM.y;
	seed = fract(float(INSTANCE_ID) * 0.6180339);
	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right = normalize(cross(up, INV_VIEW_MATRIX[2].xyz));
	float size = length(MODEL_MATRIX[0].xyz);
	mat4 world = mat4(vec4(right * size, 0.0), vec4(up * size, 0.0), vec4(cross(right, up) * size, 0.0),
		MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * world;
}

void fragment() {
	float y = 1.0 - UV.y;
	float n = noise(vec2(UV.x * 2.0 + seed * 40.0, y * 2.0 - TIME * 5.0 + seed * 9.0));
	float m = noise(vec2(UV.x * 7.0 + seed * 13.0, y * 6.0 - TIME * 11.0));
	float x = (UV.x - 0.5) * 2.0 + (n - 0.5) * 1.3 * y + sin(TIME * 7.0 + seed * 30.0) * 0.15 * y;
	float w = pow(1.0 - y, 0.6) * smoothstep(0.0, 0.2, y + 0.08) * (1.0 - age * 0.5) + (m - 0.5) * 0.35;
	float body = w - abs(x);
	if (body <= 0.0 || y > 1.0 - age * 0.45) {
		discard;
	}
	float h = clamp(body * 2.4, 0.0, 1.0) * (1.0 - y * 0.5);
	// Le bord trois fois plus sombre que le cœur : poussé vers le blanc, il sortait crème.
	ALBEDO = COLOR.rgb * mix(0.3, 1.0, pow(h, 1.4)) * 0.5;
	ALPHA = smoothstep(0.0, 0.25, body) * COLOR.a * opacity;
}
