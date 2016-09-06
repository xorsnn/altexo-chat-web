uniform sampler2D map;
varying vec2 vUv;
void main() {
	vec4 col = texture2D( map, vUv );
	if (vUv.y > (1.0 - 0.2)) {
		gl_FragColor = vec4( 240.0 / 256.0, 240.0 / 256.0, 240.0 / 256.0, 1.0 );
	} else {
		float alpha = 1.0 - (0.8 - vUv.y) * 0.2;
		gl_FragColor = vec4(
			(col.x * (1.0 - alpha) + ( 240.0 / 256.0) * alpha),
			(col.y * (1.0 - alpha) + ( 240.0 / 256.0) * alpha),
			(col.z * (1.0 - alpha) + ( 240.0 / 256.0) * alpha),
			1.0 );
	}
}
