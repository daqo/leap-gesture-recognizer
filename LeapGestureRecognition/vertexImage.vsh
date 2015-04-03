#version 410 core

layout (location = 0) in vec3 inPosition;
layout (location = 1) in vec2 inTexCoord;

out vec2 distortionLookup;

void main()
{   
    gl_Position = vec4(inPosition, 1.0);
    distortionLookup = inTexCoord;
}