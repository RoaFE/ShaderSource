// Light pixel shader
// Calculate diffuse lighting for a single directional light (also texturing)

Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

cbuffer MultiLightBuffer : register(b0)
{
	float4 ambient;
	float4 diffuse[2];
	float4 position[2];
	float4 direction[2];

};

cbuffer AttenuationBuffer: register(b1)
{
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
float4 calculateLighting(float3 lightDirection, float3 normal, float4 ldiffuse, float distance, float constantFactor, float linearFactor, float quadraticFactor)
{
	float attenuation = (1 / (constantFactor + (linearFactor * distance) + (quadraticFactor * pow(distance, 2))));
	float intensity = saturate(dot(normal, lightDirection));
	float4 colour = saturate(ldiffuse * attenuation * intensity);

	return colour;
}

//overloaded calculate lighting 
float4 calculateLighting(float3 lightDirection, float3 normal, float4 ldiffuse)
{
	float intensity = saturate(dot(normal, lightDirection));
	float4 colour = ldiffuse * intensity;
	return colour;
}

//calcualte spotlight factor
float calculateSpotlight(float3 directionVector, float3 lightVector, float exponent)
{
	float spotFactor = max((dot(directionVector, lightVector)), 0);
	return pow(spotFactor, exponent);
}

float4 main(InputType input) : SV_TARGET
{
	// Sample the texture. Calculate light intensity and colour, return light*texture for final pixel colour.
	float4 textureColour = texture0.Sample(sampler0, input.tex);
	float dist;
	float4 lightColour = { 0.0f,0.0f,0.0f,0.0f };
	//dist = distance(position3, input.worldPosition);

	for (int i = 0; i < 2; i++)
	{
		//get the distance from the light to the point
		float dist = distance(position[i].xyz, input.worldPosition);
		//get the vector
		float3 lightVector = normalize(position[i].xyz - input.worldPosition);
		//point or spot
		int type = direction[i].w;
		float exponent = position[i].w;
		//calculate the spot factor
		float spotFactor = (((calculateSpotlight(-direction[i].xyz, lightVector, exponent) * type) + (1 - type)));
		//apply spot factor if point it will multiply by 1
		lightColour += calculateLighting(lightVector, input.normal, diffuse[i], dist, attenuation[i].x, attenuation[i].y, attenuation[i].z) * spotFactor;
	}

	lightColour += ambient;
	lightColour = saturate(lightColour);
	return lightColour * textureColour;
}


