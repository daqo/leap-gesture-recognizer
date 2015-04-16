#version 410 core

in vec2 distortionLookup;

out vec3 color;

uniform sampler2D rawData;
uniform sampler2D distortion;

void main(void) {

    vec2 distortionIndex = texture(distortion, distortionLookup).xy;
    float hIndex = distortionIndex.r;
    float vIndex = distortionIndex.g;

    if(vIndex > 0.0 && vIndex < 1.0
        && hIndex > 0.0 && hIndex < 1.0)
    {
        color = texture(rawData, distortionIndex).rrr;
    }
    else
    {
        color = vec3(0, 0, 0);
    }
}
