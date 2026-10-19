shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

#include "res://fx/flame_common.gdshaderinc"

// La brûlure qu'une explosion de `FlameFx` laisse au sol : un bord rongé qui rougeoie au
// début, puis une tache sombre qui pâlit. Le plan fait 2,4 de côté, mis à l'échelle du rayon.

uniform vec3 tint = vec3(1.0, 0.36, 0.04);
instance uniform float opacity = 1.0;
instance uniform float progress = 0.0;
varying vec2 local;

void vertex() {
	local = VERTEX.xz;
}

void fragment() {
	float d = length(local);
	float edge = 0.8 + (noise(local * 5.2) - 0.5) * 0.5;
	if (d > edge) {
		discard;
	}
	float glow = (1.0 - smoothstep(0.0, 0.4, progress)) * smoothstep(edge - 0.3, edge, d);
	ALBEDO = mix(vec3(0.06, 0.04, 0.035), tint, glow);
	ALPHA = (0.7 - 0.3 * progress) * smoothstep(edge, edge - 0.15, d) * opacity;
}
