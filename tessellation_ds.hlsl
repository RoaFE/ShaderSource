// Tessellation domain shader
// After tessellation the domain shader processes the all the vertices

Texture2D texture0 : register(t0);
SamplerState Sampler0 : register(s0);

cbuffer MatrixBuffer : register(b0)
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
};

cbuffer ManipulationBuffer : register(b1)
{
	float time;
	float height;
	float frequency;
	float speed;
}



struct ConstantOutputType
{
    float edges[4] : SV_TessFactor;
    float inside[2] : SV_InsideTessFactor;
};

struct InputType
{
    float3 position : POSITION;
    float4 colour : COLOR;
	float2 tex : TEXCOORD0;
};

struct OutputType
{
    float4 position : SV_POSITION;
    float4 colour : COLOR;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	float3 worldPosition : TEXCOORD1;
};

float3 sobel(float2 texCoord)
{
	//Texel
	float2 heightmapSize;
	texture0.GetDimensions(heightmapSize.x, heightmapSize.y);
	float2 texel = float2(1.0f, 1.0f) / heightmapSize;

	//calculate offsets
	float2 o00 = texCoord + float2(-texel.x, -texel.y);
	float2 o10 = texCoord + float2(0.0f, -texel.y);
	float2 o20 = texCoord + float2(texel.x, -texel.y);

	float2 o01 = texCoord + float2(-texel.x, 0.0f);
	float2 o21 = texCoord + float2(texel.x, 0.0f);

	float2 o02 = texCoord + float2(-texel.x, texel.y);
	float2 o12 = texCoord + float2(0.0f, texel.y);
	float2 o22 = texCoord + float2(texel.x, texel.y);

	// Using sobel filter require eight samples
	float h00 = texture0.SampleLevel(Sampler0, o00, 0);
	float h10 = texture0.SampleLevel(Sampler0, o10, 0);
	float h20 = texture0.SampleLevel(Sampler0, o20, 0);

	float h01 = texture0.SampleLevel(Sampler0, o01, 0);
	float h21 = texture0.SampleLevel(Sampler0, o21, 0);
	
	float h02 = texture0.SampleLevel(Sampler0, o02, 0);
	float h12 = texture0.SampleLevel(Sampler0, o12, 0);
	float h22 = texture0.SampleLevel(Sampler0, o22, 0);

	//Evaluate the Sobel filters
	float Gx = h00 - h20 + 2.0f * h01 - 2.0f * h21 + h02 - h22;
	float Gy = h00 + 2.0f * h10 + h20 - h02 - 2.0f * h12 - h22;

	//Generate the missing Z
	float Gz = 0.01f * sqrt(max(0.0, 1.0f - Gx * Gx - Gy * Gy));

	return normalize(float3(2.0f * Gx, 2.0f * Gy, Gz));
}

[domain("quad")]
OutputType main(ConstantOutputType input, float2 uvwCoord : SV_DomainLocation, const OutputPatch<InputType, 4> patch)
{
    float3 vertexPosition;
    OutputType output;
 
    // Determine the position of the new vertex and tex coord.
	// Invert the y and Z components of uvwCoord as these coords are generated in UV space and therefore y is positive downward.
	// Alternatively you can set the output topology of the hull shader to cw instead of ccw (or vice versa).
	float2 t1 = lerp(patch[0].tex, patch[3].tex, uvwCoord.x);
	float2 t2 = lerp(patch[1].tex, patch[2].tex, uvwCoord.x);
	
	output.tex = lerp(t1, t2, uvwCoord.y);


	float3 v1 = lerp(patch[0].position, patch[1].position, uvwCoord.y);
	float3 v2 = lerp(patch[3].position, patch[2].position, uvwCoord.y);
	vertexPosition = lerp(v1, v2, uvwCoord.x);


	
	//apply displacement
	float offset = texture0.SampleLevel(Sampler0, output.tex,0);
	offset *= max(0, height * sin((vertexPosition.x + (speed*time))*frequency));
	vertexPosition.y += offset;
	vertexPosition.y;


    // Calculate the position of the new vertex against the world, view, and projection matrices.
    output.position = mul(float4(vertexPosition, 1.0f), worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
	

	output.normal = sobel(output.tex);
	if (offset < 0.1)
	{
		output.normal = float3(0.0, 1.0, 0.0);
	}
	output.normal = mul(output.normal, (float3x3)worldMatrix);
	output.normal = normalize(output.normal);

	output.worldPosition = mul(float4(vertexPosition, 1.0f), worldMatrix).xyz;

    return output;
}

