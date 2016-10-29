attribute float alFFTIndex;
uniform float spectrum[ 16 ];
uniform float distanceK;
// uniform float t;

vec3 getNewPos(vec3 currentPos) {
  float aVertexFFT = 0.0;
  if (alFFTIndex > 10.0) {
    aVertexFFT = spectrum[11];
  } else if (alFFTIndex > 9.0) {
    aVertexFFT = spectrum[10];
  } else if (alFFTIndex > 8.0) {
    aVertexFFT = spectrum[9];
  } else if (alFFTIndex > 7.0) {
    aVertexFFT = spectrum[8];
  } else if (alFFTIndex > 6.0) {
    aVertexFFT = spectrum[7];
  } else if (alFFTIndex > 5.0) {
    aVertexFFT = spectrum[6];
  } else if (alFFTIndex > 4.0) {
    aVertexFFT = spectrum[5];
  } else if (alFFTIndex > 3.0) {
    aVertexFFT = spectrum[4];
  } else if (alFFTIndex > 2.0) {
    aVertexFFT = spectrum[3];
  } else if (alFFTIndex > 1.0) {
    aVertexFFT = spectrum[2];
  } else if (alFFTIndex > 0.0) {
    aVertexFFT = spectrum[1];
  } else  {
    aVertexFFT = spectrum[0];
  }
  return vec3(
    currentPos.x*(1.0 + aVertexFFT/255.0*distanceK),
    currentPos.y*(1.0 + aVertexFFT/255.0*distanceK),
    currentPos.z*(1.0 + aVertexFFT/255.0*distanceK));
    // currentPos.x*(distanceK + aVertexFFT/255.0),
    // currentPos.y*(distanceK + aVertexFFT/255.0),
    // currentPos.z*(distanceK + aVertexFFT/255.0));
}

void main(void) {
  vec3 pos = getNewPos(position);
  gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
}
