shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Une créature de la Porte pourrissante (`RotGateFx`), par instance d'un `MultiMesh` : une bulle de chair
// **éclairée** — un objet, pas de la lumière —, une peau pourrie de Qwen-Image (`fx/rot_flesh.png`) en
// triplanaire, bosselée par un bruit qui bat, deux yeux sombres devant (le jaune de la 2D ne tranchait pas sur
// le vert), un reflet humide.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D skin : source_color, filter_linear_mipmap, repeat_enable;
// Sans yeux : la chair de la faille.
uniform bool eyed = true;
uniform float bumps = 1.0;
instance uniform float opacity = 1.0;
varying vec3 spot;
varying float seed;

void vertex() {
	seed = INSTANCE_CUSTOM.r;
	float bump = noise(VERTEX.xz * 2.5 + VERTEX.y * 1.7 + seed * 11.0 + TIME * 1.5);
	VERTEX *= 1.0 + 0.2 * bumps * (bump - 0.5);
	spot = VERTEX;
}

void fragment() {
	vec3 w = abs(spot);
	w /= w.x + w.y + w.z;
	vec3 p = spot * 0.45 + seed;
	vec3 c = texture(skin, p.yz).rgb * w.x + texture(skin, p.xz).rgb * w.y + texture(skin, p.xy).rgb * w.z;
	// Deux yeux sur le dessus, vers l'avant — la caméra plonge : des creux sombres où brille un point.
	float eyes = 1.0;
	float glint = 0.0;
	for (int s = -1; s <= 1 && eyed; s += 2) {
		vec3 at = normalize(vec3(float(s) * 0.4, 0.75, 0.55));
		float d = length(normalize(spot) - at);
		eyes = min(eyes, smoothstep(0.24, 0.31, d));
		glint = max(glint, 1.0 - smoothstep(0.0, 0.07, length(normalize(spot) - at - vec3(0.04, 0.05, 0.0))));
	}
	// Chair verdâtre et humide : teintée au vert sombre, elle sortait en chou ; grise, en caillou.
	vec3 flesh = c * vec3(0.95, 1.15, 0.7);
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 3.0);
	ALBEDO = mix(vec3(0.03, 0.02, 0.02), flesh, eyes);
	EMISSION = vec3(0.85, 0.82, 0.25) * glint * 0.8 + vec3(0.25, 0.45, 0.06) * rim * eyes;
	ROUGHNESS = mix(0.15, 0.45, eyes);
	SPECULAR = 0.7;
	ALPHA = opacity;
}
