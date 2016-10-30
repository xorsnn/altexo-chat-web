attribute vec2 vUv;

uniform sampler2D textureMap;
uniform float wAmount;
uniform float hAmount;

varying vec2 vUV;
varying float visibility;

const float minD = 555.0;
const float maxD = 1005.0;

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
  vUV.x *= 0.5;
  vec3 hsl = rgb2hsl(texture2D(textureMap, vUV).xyz);
  vUV.x += 0.5;
  visibility = hsl.z * 2.0;
  vec3 pos = xyz(position.x/320.0, position.y/320.0, hsl.x);
  pos.y = pos.y + 240.0 - 120.0;
  gl_Position = projectionMatrix * modelViewMatrix * vec4(pos.x, pos.y, pos.z, 1.0);

  vec4 modelMat = modelMatrix * vec4(pos, 1.0);
  if (modelMat.y < -120.0) {
    visibility = 0.0;
  }
}
