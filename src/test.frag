in vec4 color;
in vec2 texCoord;

uniform sampler2D tex;

uniform float u_time;

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453) * 2.0 - 1.0;
}

float offset(float blocks, vec2 uv) {
  return rand(vec2(u_time, floor(uv.y * blocks)));
}

void main(void)
{
  vec2 uv = texCoord;
  vec4 glitched = texture(tex, uv);
  glitched.r = texture(tex, uv + vec2(offset(16.0, uv) * 0.1, 0.0)).r;	
  glitched.g = texture(tex, uv + vec2(offset(8.0, uv) * 0.1 * 0.16666666, 0.0)).g;
  glitched.b = texture(tex, uv + vec2(offset(8.0, uv) * 0.1, 0.0)).b;
  fragColor = glitched * color;
}
