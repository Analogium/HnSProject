shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Le sol de `BurntPath` : la terre craquelée d'un scan, noircie, dont les fissures rougeoient et
// pulsent ; son bord casse le long d'une craquelure ; à sa fin, rongé par un bruit au liseré brûlant,
// plutôt que fondu (la barre de Last Epoch). Le plan fait 2 de côté, mis à l'échelle du couloir :
// `half_len` et `radius` le redonnent en pixels.

#include "res://fx/flame_common.gdshaderinc"

// Le scan : clarté en R, fissures en G (`tools/fx_textures.py cracks`).
uniform sampler2D cracks : filter_linear_mipmap, repeat_enable;
uniform vec3 tint = vec3(1.0, 0.36, 0.04);
uniform vec3 deep = vec3(0.72, 0.1, 0.02);
uniform vec3 core = vec3(1.0, 0.75, 0.3);
instance uniform float half_len = 0.0;
instance uniform float radius = 16.0;
// 0 à la pose, 1 quand le couloir s'éteint.
instance uniform float life = 0.0;
instance uniform float opacity = 1.0;
// Le scan se répète tous les TILE px.
const float TILE = 72.0;
varying vec2 local;
varying vec2 world;

void vertex() {
	local = VERTEX.xz * vec2(half_len + radius, radius);
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec3 m = texture(cracks, world / TILE).rgb;
	vec2 q = vec2(max(abs(local.x) - half_len, 0.0), local.y);
	float j = (noise(local * 0.1) - 0.5) * 0.35 + (noise(local * 0.3) - 0.5) * 0.2;
	float d = length(q) / radius + j - m.g * 0.3;
	if (d > 1.0) {
		discard;
	}
	float n = 0.55 + 0.45 * noise(world * 0.07 + vec2(TIME * 0.5, -TIME * 0.8));
	float c = pow(m.g, 1.3) * smoothstep(1.0, 0.35, d) * n;
	vec3 lit = mix(deep, mix(tint, core, smoothstep(0.6, 1.0, c * 1.4)), smoothstep(0.1, 0.7, c));
	vec3 burnt = vec3(0.035, 0.024, 0.018) * (0.5 + 1.1 * m.r);
	float glow = 1.0 - smoothstep(0.55, 1.0, life);
	ALBEDO = burnt + (lit * c * 0.9 + deep * pow(1.0 - d, 2.0) * 0.06 * n) * glow;
	float eat = smoothstep(0.78, 1.0, life);
	float e = noise(world * 0.12) * 0.6 + noise(world * 0.4) * 0.4;
	if (e < eat) {
		discard;
	}
	float edge = (1.0 - smoothstep(eat, eat + 0.08, e)) * step(0.01, eat);
	ALBEDO += tint * edge * 1.3;
	ALPHA = max(smoothstep(1.0, 0.82, d), edge) * opacity;
}
