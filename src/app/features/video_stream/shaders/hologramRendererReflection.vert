attribute vec2 vUv;

uniform sampler2D textureMap;
uniform float wAmount;
uniform float hAmount;

varying vec2 vUV;
varying float visibility;

const float minD = 555.0;
const float maxD = 1005.0;

// MODIFICATIONS position
uniform float modificationPosX;
// uniform float modificationPosY;
uniform float modificationPosZ;

// MODIFICATIONS rotation
// uniform float modificationRotationX;
uniform float modificationRotationY;
// uniform float modificationRotationZ;

// const float PI = 3.1415926535897932384626433832795;
// const float PI_6 = PI / 6.0;

// taken from freenect example
const float f = 595.0; // devide by wAmoutn to normalize

vec3 rgb2hsl(vec3 color) {
  float h = 0.0;
  float s = 0.0;
  float l = 0.0;
  float r = color.r;
  float g = color.g;
  float b = color.b;
  float cMin = min(r, min(g, b));
  float cMax = max(r, max(g, b));
  l = (cMax + cMin) / 2.0;
  if (cMax > cMin) {
    float cDelta = cMax - cMin;
    // saturation
    if (l < 0.5) {
      s = cDelta / (cMax + cMin);
    } else {
      s = cDelta / (2.0 - (cMax + cMin));
    }
    // hue
    if (r == cMax) {
      h = (g - b) / cDelta;
    } else if (g == cMax) {
      h = 2.0 + (b - r) / cDelta;
    } else {
      h = 4.0 + (r - g) / cDelta;
    }
    if (h < 0.0) {
      h += 6.0;
    }
    h = h / 6.0;
  }
  return vec3(h, s, l);
}

vec3 xyz(float x, float y, float depth) {
  float outputMin = 0.0;
  float outputMax = 1.0;
  float inputMax = maxD;
  float inputMin = minD;
  float zDelta = inputMin + (inputMax - inputMax) / 2.0;

  float z =
      ((depth - outputMin) / (outputMax - outputMin)) * (inputMax - inputMin) +
      inputMin;

  return vec3(x * (wAmount * 2.0) * z / f, // X = (x - cx) * d / fx
              y * (wAmount * 2.0) * z / f, // Y = (y - cy) * d / fy
              -z + zDelta);                // Z = d
}

void main() {
  visibility = 1.0;
  vUV = vUv;
  vUV.y = 1.0 - vUV.y;

  vUV.x *= 0.5;
  vec3 hsl = rgb2hsl(texture2D(textureMap, vUV).xyz);
  vUV.x += 0.5;
  visibility = hsl.z * 2.0;

  // TODO: move to uniforms
  float koef = 2.0 / 3.0;
  vec3 pos = xyz(position.x / wAmount, position.y / wAmount, hsl.x * koef);
  pos.y = pos.y - 240.0 * koef - 120.0;


  // NOTE: moving here
  vec3 newPos;
  newPos.x = pos.x * cos(modificationRotationY) + pos.z * sin(modificationRotationY) + modificationPosX;
  newPos.y = pos.y;
  newPos.z = -pos.x * sin(modificationRotationY) + pos.z * cos(modificationRotationY);

  gl_Position = projectionMatrix * modelViewMatrix * vec4(newPos.xy, newPos.z + modificationPosZ, 1.0);
  // gl_PointSize = 2.5;
  gl_PointSize = 3*3.5;

  vec4 modelMat = modelMatrix * vec4(pos, 1.0);
  if (modelMat.y > -120.0) {
    visibility = 0.0;
  }
}
