shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// La fumée d'une explosion de `FlameFx` : mêlée et non ajoutée, bord assombri.
#define RAGGED 0.8
#define SOFT 0.3
#define BOOST 1.0
#define RIM(edge) mix(0.45, 1.0, smoothstep(0.0, 0.12, edge))

#include "res://fx/flame_wisp.gdshaderinc"
