// Light pixel shader
// Calculate diffuse lighting for a single directional light (also texturing)

Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

cbuffer LightBuffer : register(b0)
{
	float4 ambient;
	float4 diffuse;
	float4 position;
	float4 direction;
};

cbuffer AttenuationBuffer: register(b1)
{
	//x = constant, y = linear, z = quadratic, w = padding
	float4 attenuation[2];
}

struct InputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	float3 worldPosition : TEXCOORD1;
};

// Calculate lighting intensity based on direction and normal. Combine with light colour.
float4 calculateLighting(float3 lightDirection, float3 normal, float4 ldiffuse)
{ 
	float intensity = saturate(dot(normal, lightDirection));
	float4 colour = ldiffuse * intensity;
	return colour;
}

//calculate Attenuation
float calculateAttenuation(float distance, float constantFactor, float linearFactor, float quadraticFactor)
{
	float attenuation = (1 / (constantFactor + (linearFactor * distance) + (quadraticFactor * pow(distance, 2))));
	return attenuation;
}

float4 main(InputType input) : SV_TARGET
{
	// Sample the texture. Calculate light intensity and colour, return light*texture for final pixel colour.
	float4 textureColour = texture0.Sample(sampler0, input.tex);
	float dist;

	float4 lightColour = { 0.0f,0.0f,0.0f,0.0f };
	//dist = distance(position3, input.worldPosition);
	lightColour += ambient + saturate(calculateLighting(position.xyz, input.normal, diffuse));

	return lightColour * textureColour;
}



