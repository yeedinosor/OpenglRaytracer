#version 330

out vec3 color;
in vec2 textCoord;

uniform sampler2D fb;
void main() {
	color = texture(fb, textCoord).xyz;
}