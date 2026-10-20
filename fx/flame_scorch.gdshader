shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://fx/flame_common.gdshaderinc"

// La brûlure qu'une explosion de `FlameFx` laisse au sol : la terre craquelée de la Ruée
// (`fx/burnt_cracks.png`), noircie, dont les fissures rougeoient puis s'éteignent, le bord
// cassé le long d'une craquelure. Le plan fait 2,2 de côté, mis à l'échelle du rayon.

uniform sampler2D cracks : filter_linear_mipmap, repeat_enable;
uniform vec3 tint = vec3(1.0, 0.36, 0.04);
uniform vec3 deep = vec3(0.72, 0.1, 0.02);
instance uniform float opacity = 1.0;
instance uniform float progress = 0.0;
varying vec2 local;
varying vec2 world;

void vertex() {
	local = VERTEX.xz;
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec3 m = texture(cracks, world / 72.0).rgb;
	float d = length(local) + (noise(local * 4.0) - 0.5) * 0.3 - m.g * 0.25;
	if (d > 1.0) {
		discard;
	}
	float hot = (1.0 - smoothstep(0.0, 0.6, progress)) * pow(m.g, 1.3) * smoothstep(1.0, 0.2, d);
	ALBEDO = vec3(0.035, 0.024, 0.018) * (0.5 + 1.1 * m.r) + mix(deep, tint, hot) * hot;
	ALPHA = smoothstep(1.0, 0.75, d) * (1.0 - 0.5 * progress) * opacity;
}
