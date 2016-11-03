uniform sampler2D textureMap;

varying vec2 vUV;
varying float visibility;

void main() {
  if (visibility > 0.95) {
  	vec4 col = vec4(68.0/255.0, 68.0/255.0, 68.0/255.0, 1.0);
    if ((vUV.y) > (1.0 - 0.2)) {
      gl_FragColor = vec4( 240.0 / 256.0, 240.0 / 256.0, 240.0 / 256.0, 1.0 );
    } else {
      float alpha = 1.0 - (0.8 - (vUV.y)) * 0.2;
      gl_FragColor = vec4(
        (col.x * (1.0 - alpha) + ( 240.0 / 256.0) * alpha),
        (col.y * (1.0 - alpha) + ( 240.0 / 256.0) * alpha),
        (col.z * (1.0 - alpha) + ( 240.0 / 256.0) * alpha),
        1.0 );
    }
  } else {
    discard;
  }
}
