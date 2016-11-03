uniform sampler2D textureMap;

varying vec2 vUV;
varying float visibility;

void main() {
  if (visibility > 0.95) {
    gl_FragColor = texture2D(textureMap, vUV);
  } else {
    discard;
  }
}
