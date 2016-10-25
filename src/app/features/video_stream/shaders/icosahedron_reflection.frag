
varying float vUvy;

void main(void) {
	vec4 col = vec4(68.0/255.0, 68.0/255.0, 68.0/255.0, 1.0);
  if (vUvy > (1.0 - 0.2)) {
    gl_FragColor = vec4( 240.0 / 256.0, 240.0 / 256.0, 240.0 / 256.0, 1.0 );
  } else {
    float alpha = 1.0 - (0.8 - vUvy) * 0.2;
    gl_FragColor = vec4(
      (col.x * (1.0 - alpha) + ( 240.0 / 256.0) * alpha),
      (col.y * (1.0 - alpha) + ( 240.0 / 256.0) * alpha),
      (col.z * (1.0 - alpha) + ( 240.0 / 256.0) * alpha),
      1.0 );
  }
}
