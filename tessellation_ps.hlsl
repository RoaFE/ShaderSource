// Tessellation pixel shader
// Output colour passed to stage.

Texture2D texture0 : register(t0);
SamplerState Sampler0 : register(s0);

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
    float4 colour : COLOR;
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
// Calculate lighting intensity based on direction and normal. Combine with light colour.

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
	float4 colour = float4(0.3,0.3,0.3,1.0);
	colour = texture0.Sample(Sampler0, input.tex);
	float4 lightColour = { 0.0,0.0,0.0,1.0 };
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
		lightColour += calculateLighting(lightVector, input.normal, diffuse[i], dist, attenuation[i].x, attenuation[i].y, attenuation[i].z) * spotFactor;
	}
	colour += ambient;
    return colour * saturate(lightColour);
}