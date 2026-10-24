shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Les arcs qui crépitent autour de l'orbe de `BoltFx` : un ruban tourné vers la caméra autour de
// son axe, cassé en `kinks` coudes et en crans fins, retiré au hasard à chaque battement. Il porte
// le tronc d'un éclair photographié (`fx/lightning_bolt.png`) : Qwen ne sort que des arcs plumeux au
// tronc presque droit, et la photo seule, réduite, n'avait plus de coudes.

#include "res://fx/lightning_common.gdshaderinc"

uniform sampler2D photo : filter_linear_mipmap, repeat_enable;
uniform float boost = 1.2;
uniform float hz = 18.0;
uniform float kinks = 7.0;
// L'écart des coudes, en largeurs de ruban.
uniform float amp = 0.8;
// La part du ruban, depuis sa queue, qui s'allume : un arc autour de l'orbe naît de rien, un saut de
// la Chaîne d'éclairs part plein de sa source.
uniform float tail = 0.5;
instance uniform float opacity = 1.0;
// Par tir : deux éclairs côte à côte ne se cassent pas aux mêmes coudes.
instance uniform float seed = 0.0;
// La part du ruban, depuis sa queue, déjà éteinte : la Ruée d'orage s'éteint du départ vers l'arrivée.
instance uniform float gone = 0.0;

float hash(float n) {
	return fract(sin(n * 12.9898 + seed * 78.233) * 43758.5453);
}

void vertex() {
	// Le ruban va de la queue (0) à la tête (1).
	float t = VERTEX.x + 1.0;
	float frame = floor(TIME * hz);
	float k = t * kinks;
	float i = floor(k);
	float a = i < 0.5 ? 0.0 : hash(i + frame * 17.0) * 2.0 - 1.0;
	float b = i + 1.0 > kinks - 0.5 ? 0.0 : hash(i + 1.0 + frame * 17.0) * 2.0 - 1.0;
	// Des crans fins entre les grands coudes : droits entre deux coudes, ils faisaient un tube.
	float k2 = k * 3.0;
	float j = floor(k2);
	float c = hash(j * 3.1 + frame * 5.0 + 40.0) * 2.0 - 1.0;
	float d = hash((j + 1.0) * 3.1 + frame * 5.0 + 40.0) * 2.0 - 1.0;
	float edge = smoothstep(0.0, 0.08, t) * smoothstep(1.0, 0.92, t);
	VERTEX.y += (mix(a, b, fract(k)) + mix(c, d, fract(k2)) * 0.3) * amp * edge;
	vec3 along = MODEL_MATRIX[0].xyz;
	vec3 eye = normalize(INV_VIEW_MATRIX[3].xyz - MODEL_MATRIX[3].xyz);
	vec3 side = normalize(cross(eye, normalize(along))) * length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(along, 0.0), vec4(side, 0.0), vec4(eye, 0.0), MODEL_MATRIX[3]);
}

void fragment() {
	vec3 p = texture(photo, vec2(UV.x * 0.5 + seed * 0.37, UV.y)).rgb;
	float alive = gone > 0.0 ? smoothstep(gone, gone + 0.25, UV.x) : 1.0;
	ALBEDO = ramp_of(max(p.r, max(p.g, p.b))) * boost * smoothstep(0.0, tail, UV.x) * alive * opacity;
}
