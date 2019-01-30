
Texture2D shaderTexture : register(t0);
Texture2D depthMapTexture : register(t1);
Texture2D depthMapTexture2 : register(t2);

SamplerState diffuseSampler  : register(s0);
//SamplerState shadowSampler : register(s1);

cbuffer LightBuffer : register(b0)
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
    float4 light1ViewPos : TEXCOORD1;
    float4 light2ViewPos : TEXCOORD2;
	float3 worldPosition : TEXCOORD3;
};

float calculateSpotlight(float3 directionVector, float3 lightVector, float exponent)
{
	float spotFactor = max((dot(directionVector, lightVector)), 0);
	return pow(spotFactor, exponent);
}

// Calculate lighting intensity based on direction and normal. Combine with light colour.
float4 calculateLighting(float3 lightDirection, float3 normal, float4 diffuse, float dist, float constantFactor, float linearFactor, float quadraticFactor)
{
	float attenuation = (1 / (constantFactor + (linearFactor * dist) + (quadraticFactor * pow(dist, 2))));
    float intensity = saturate(dot(normal, lightDirection));
    float4 colour = (diffuse * intensity * attenuation);
    return colour;
}

//calculate the shadow
float4 calculateShadow(Texture2D shadowTexture, float2 tex, float4 lightViewPos, float3 worldPos, float3 normal, int index, float dist)
{
	float depthValue;
	float lightDepthValue;
	float shadowMapBias = 0.005f;
	float4 colour = float4(0.f, 0.f, 0.f, 1.f);

	float4 textureColour = shaderTexture.Sample(diffuseSampler, tex);

	// Calculate the projected texture coordinates.
	float2 pTexCoord = lightViewPos.xy / lightViewPos.w;
	pTexCoord *= float2(0.5, -0.5);
	pTexCoord += float2(0.5f, 0.5f);

	// Determine if the projected coordinates are in the 0 to 1 range.  If not do lighting normally.
	if (pTexCoord.x < 0.f || pTexCoord.x > 1.f || pTexCoord.y < 0.f || pTexCoord.y > 1.f)
	{
		float3 lightVector = normalize(position[index].xyz - worldPos);
		int type = direction[index].w;
		float exponent = position[index].w;
		float spotFactor = (((calculateSpotlight(-direction[index].xyz, lightVector, exponent) * type) + (1 - type)));
		colour = calculateLighting(lightVector, normal, diffuse[index], dist, attenuation[index].x, attenuation[index].y, attenuation[index].z) * spotFactor;
		return colour;
	}

	// Sample the shadow map (get depth of geometry)
	depthValue = shadowTexture.Sample(diffuseSampler, pTexCoord).r;
	// Calculate the depth from the light.
	lightDepthValue = lightViewPos.z / lightViewPos.w;
	lightDepthValue -= shadowMapBias;

	// Compare the depth of the shadow map value and the depth of the light to determine whether to shadow or to light this pixel.
	if (lightDepthValue < depthValue)
	{
		float3 lightVector = normalize(position[index].xyz - worldPos); 
		int type = direction[index].w;
		float exponent = position[index].w;
		float spotFactor = (((calculateSpotlight(-direction[index].xyz, lightVector, exponent) * type) + (1 - type)));
		colour = calculateLighting(lightVector, normal, diffuse[index], dist, attenuation[index].x, attenuation[index].y, attenuation[index].z) * spotFactor;
	}

	return colour;
}

float4 main(InputType input) : SV_TARGET
{
    float4 colour = float4(0.f, 0.f, 0.f, 1.f);
    float4 textureColour = shaderTexture.Sample(diffuseSampler, input.tex);

	//can be implemented into a loop

	float dist = distance(position[0].xyz, input.worldPosition);
	colour += calculateShadow(depthMapTexture, input.tex, input.light1ViewPos, input.worldPosition, input.normal, 0, dist);
	//colour += calculateLighting(normalize(position[0].xyz - input.worldPosition), input.normal, diffuse[0], dist, attenuation[0].x, attenuation[0].y, attenuation[0].z);

	dist = distance(position[1].xyz, input.worldPosition);
	colour += calculateShadow(depthMapTexture2, input.tex, input.light2ViewPos, input.worldPosition, input.normal, 1, dist);
	//colour += calculateLighting(normalize(position[1].xyz - input.worldPosition), input.normal, diffuse[1], dist, attenuation[1].x, attenuation[1].y, attenuation[1].z);

	colour /= 2;
	colour += ambient;
    return saturate(colour) * textureColour;
}