
cbuffer MatrixBuffer : register(b0)
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
	matrix lightViewMatrix[2];
	matrix lightProjectionMatrix[2];
};

struct InputType
{
    float4 position : POSITION;
    float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
};

struct OutputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
    float4 light1ViewPos : TEXCOORD1;
    float4 light2ViewPos : TEXCOORD2;
    float3 worldPosition : TEXCOORD3;
};


OutputType main(InputType input)
{
    OutputType output;

	// Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);
    
	// Calculate the position of the vertice as viewed by the first light source.
    output.light1ViewPos = mul(input.position, worldMatrix);
    output.light1ViewPos = mul(output.light1ViewPos, lightViewMatrix[0]);
    output.light1ViewPos = mul(output.light1ViewPos, lightProjectionMatrix[0]);

	// Calculate the position of the vertice as viewed by the second light source.
	output.light2ViewPos = mul(input.position, worldMatrix);
    output.light2ViewPos = mul(output.light2ViewPos, lightViewMatrix[1]);
    output.light2ViewPos = mul(output.light2ViewPos, lightProjectionMatrix[1]);

    output.tex = input.tex;
    output.normal = mul(input.normal, (float3x3)worldMatrix);
    output.normal = normalize(output.normal);

	//get world position for lighting
	output.worldPosition = mul(input.position, worldMatrix).xyz;

	return output;
}