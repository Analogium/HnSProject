shader_type spatial;

// Le fer du Brasero (`BrazierFx`) : le scan rouillé de Poly Haven et son relief, plaqués en triplanaire —
// la coupe et ses pieds n'ont pas d'UV qui se suivent. Éteint, il se ronge par un bruit au liseré
// rougeoyant (`dissolve`) : il disparaissait d'un coup. Il ne lit pas le voile des sorts : c'est un objet.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D iron : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D relief : hint_normal, filter_linear_mipmap, repeat_enable;
// Le liseré à la nature du brasero : le fer est un pour tous.
instance uniform vec3 tint = vec3(1.0, 0.36, 0.04);
instance uniform float dissolve = 0.0;
// Le scan se répète tous les TILE px.
const float TILE = 12.0;
varying vec3 world;
varying vec3 face;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	face = abs(normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz));
}

void fragment() {
	float e = noise(world.xz * 0.6 + world.y * 0.4) * 0.6 + noise(world.xz * 1.7 - world.y) * 0.4;
	if (e < dissolve) {
		discard;
	}
	vec3 w = pow(face, vec3(4.0));
	w /= w.x + w.y + w.z;
	vec3 p = world / TILE;
	// Le scan, brun clair, sortait cuivré sous le soleil du sol.
	ALBEDO = (texture(iron, p.yz).rgb * w.x + texture(iron, p.xz).rgb * w.y + texture(iron, p.xy).rgb * w.z) * 0.42;
	NORMAL_MAP = texture(relief, p.yz).rgb * w.x + texture(relief, p.xz).rgb * w.y + texture(relief, p.xy).rgb * w.z;
	METALLIC = 0.55;
	ROUGHNESS = 0.65;
	float edge = (1.0 - smoothstep(dissolve, dissolve + 0.1, e)) * step(0.01, dissolve);
	EMISSION = tint * edge * 1.6;
}
