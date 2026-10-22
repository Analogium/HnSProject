shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Le lit de braises dans la coupe de `BrazierFx` : les fissures de la Ruée (`fx/burnt_cracks.png`)
// à petite échelle, qui rougeoient et pulsent. Répétées à 72 px comme au sol, dans une coupe de
// 13 px elles ne faisaient qu'une craquelure : une assiette, pas des braises.

#include "res://fx/flame_common.gdshaderinc"

uniform sampler2D cracks : filter_linear_mipmap, repeat_enable;
uniform vec3 core = vec3(1.0, 0.75, 0.3);
uniform vec3 tint = vec3(1.0, 0.36, 0.04);
uniform vec3 deep = vec3(0.72, 0.1, 0.02);
instance uniform float opacity = 1.0;
const float TILE = 8.0;
varying vec2 local;
varying vec2 world;

void vertex() {
	local = VERTEX.xz;
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	float d = length(local);
	if (d > 1.0) {
		discard;
	}
	vec3 m = texture(cracks, world / TILE).rgb;
	float n = 0.5 + 0.5 * noise(world * 0.3 + vec2(TIME * 0.8, -TIME * 1.2));
	float c = clamp(pow(m.g, 1.15) * n * 1.3 + (1.0 - d) * 0.2, 0.0, 1.1);
	vec3 lit = mix(deep, mix(tint, core, smoothstep(0.6, 1.0, c)), smoothstep(0.1, 0.6, c));
	ALBEDO = vec3(0.04, 0.025, 0.02) * (0.5 + m.r) + lit * c;
	ALPHA = smoothstep(1.0, 0.85, d) * opacity;
}
