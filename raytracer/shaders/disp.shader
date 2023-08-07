#version 330

out vec3 color;
in vec2 textCoord;

uniform sampler2D screenTexture;
void main() {
	color = texture(screenTexture, textCoord).xyz;
}