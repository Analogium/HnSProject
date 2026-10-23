shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled, specular_disabled, diffuse_lambert_wrap;

// Une bosse du Nuage d'orage (`StormCloudFx`) : une photo de cumulus tournée vers la caméra, qui
// **prend la lumière du jeu** par son relief (`fx/storm_puff.png`, relief en RGB, densité en A).
// Plaquée sans lumière, une photo de nuage sortait autocollant, sans volume.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D puffs : filter_linear_mipmap, repeat_disable;
uniform vec3 color = vec3(0.2, 0.195, 0.22);
instance uniform float opacity = 1.0;
// La case de l'atlas (0, 1, 2), l'angle de départ, et le ventre plus sombre que le dôme.
instance uniform float cell = 0.0;
instance uniform float turn = 0.0;
instance uniform float shade = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * facing(MODEL_MATRIX, INV_VIEW_MATRIX);
}

void fragment() {
	float a = turn + TIME * 0.06;
	mat2 r = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a)));
	vec2 uv = clamp(r * (UV - 0.5) + 0.5, 0.0, 1.0);
	vec4 t = texture(puffs, vec2((cell + uv.x) / 3.0, uv.y));
	// Le relief tourne avec la photo.
	vec3 n = t.rgb * 2.0 - 1.0;
	n.xy = transpose(r) * n.xy;
	NORMAL = normalize(n);
	ALBEDO = color * shade;
	ALPHA = t.a * opacity;
}
