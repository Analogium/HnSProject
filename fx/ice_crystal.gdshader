shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, shadows_disabled;

// Un pic de `IceSpikesFx` : de la glace claire qui laisse voir le sol au travers, déformé et teinté
// par la rampe de sa nature ; les veines de `fx/ice_veins.png` plaquées en triplanaire, un reflet de
// soleil sur les arêtes, la pointe plus claire. Éclairé : sans lumière, un pic sortait plat.
// `dissolve` le ronge, un liseré de givre sur le bord : les esquilles de la Nova s'en vont ainsi.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D veins : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 heart;
uniform vec3 tint;
uniform vec3 deep;
uniform vec3 rime;
instance uniform float opacity = 1.0;
instance uniform float dissolve = 0.0;

varying vec3 world;
varying vec3 world_normal;
varying float height;
varying vec3 local;

void vertex() {
	height = VERTEX.y;
	local = VERTEX;
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 w = abs(world_normal);
	w /= w.x + w.y + w.z;
	float s = 0.03;
	float l = dot(texture(veins, world.zy * s).rgb * w.x + texture(veins, world.xz * s).rgb * w.y
			+ texture(veins, world.xy * s).rgb * w.z, vec3(0.333));
	float eaten = noise(local.xy * 6.0 + local.z * 3.0) * 0.45 + noise(local.yz * 13.0) * 0.25 + l * 0.3;
	if (eaten < dissolve) {
		discard;
	}
	float glow = (1.0 - smoothstep(dissolve, dissolve + 0.08, eaten)) * step(0.01, dissolve);
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	vec3 behind = textureLod(screen, SCREEN_UV + NORMAL.xy * 0.06 + (l - 0.5) * 0.03, 1.5).rgb;
	float lum = dot(behind, vec3(0.3, 0.55, 0.15));
	vec3 body = mix(behind * vec3(0.4, 0.7, 1.0), mix(deep, tint, smoothstep(0.0, 0.6, lum)) * (0.3 + lum * 0.7), 0.45);
	ALBEDO = tint * 0.08;
	ROUGHNESS = 0.06;
	SPECULAR = 1.0;
	EMISSION = body * 0.85 + heart * l * 0.12 + rime * edge * 0.7 + heart * smoothstep(0.45, 1.0, height) * 0.25
			+ mix(tint, rime, 0.5) * glow * 1.6;
	ALPHA = opacity;
}
