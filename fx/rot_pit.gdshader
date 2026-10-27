shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Le puits de la Porte pourrissante (`RotGateFx`), couché dans ses lèvres de chair : la bande de gaz de
// Qwen-Image (`fx/rot_gas.png`) qui tourne en spirale vers un fond noir, le jaune maladif à mi-pente.
// Clair au centre, il se lisait comme une flaque fluo et non comme un trou.

uniform sampler2D gas : filter_linear_mipmap, repeat_enable;
uniform vec3 tint = vec3(0.1, 0.38, 0.04);
uniform vec3 deep = vec3(0.04, 0.1, 0.02);
uniform vec3 sick = vec3(0.85, 0.82, 0.25);
instance uniform float opacity = 1.0;

void fragment() {
	vec2 d = UV * 2.0 - 1.0;
	float r = length(d);
	if (r > 1.0) {
		discard;
	}
	float a = atan(d.y, d.x) / 6.2831853;
	vec3 g = texture(gas, vec2(a * 2.0 + r * 0.9 - TIME * 0.22, r * 0.8 + TIME * 0.12)).rgb;
	float w = max(g.r, max(g.g, g.b));
	vec3 c = mix(deep, tint * 0.9, w) * (smoothstep(0.1, 0.95, r) * 0.7 + 0.3 * w * r);
	ALBEDO = mix(c, sick * 0.7, pow(w, 5.0) * smoothstep(0.2, 0.6, r) * 0.6);
	ALPHA = smoothstep(1.0, 0.8, r) * opacity;
}
