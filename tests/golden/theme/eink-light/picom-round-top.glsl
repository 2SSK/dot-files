#version 330
// Rounds only the top corners of a window (radius 12, like corner-radius in picom.conf). Used for
// i3's tab and stack headers (top corners) and the window below them, so the two read as one card.
in vec2 texcoord;
uniform sampler2D tex;
uniform vec2 effective_size;
vec4 default_post_processing(vec4 c);

const float r = 12.0;

vec4 window_shader() {
	vec2 size = effective_size;
	vec2 p = texcoord;
	vec4 c = default_post_processing(texture2D(tex, p / textureSize(tex, 0), 0));
	if (p.y < r && (p.x < r || p.x > size.x - r)) {
		vec2 centre = vec2(clamp(p.x, r, size.x - r), r);
		c *= clamp(r - distance(p, centre) + 0.5, 0.0, 1.0); // antialiased edge (premultiplied colour)
	}
	return c;
}
