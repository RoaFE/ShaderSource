cbuffer MatrixBuffer : register(b0)
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
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
	float3 worldPosition : TEXCOORD1;
};


[maxvertexcount(3)]
void main(triangle InputType input[3], inout TriangleStream<OutputType> triStream)
{
	OutputType output;

	float3 normals[3];

	//get normals between verticies
	float3 vector0a = normalize(input[1].position.xyz - input[0].position.xyz);
	float3 vector0b = normalize(input[2].position.xyz - input[0].position.xyz);
	normals[0] = cross(vector0b, vector0a);

	float3 vector1a = normalize(input[0].position.xyz - input[1].position.xyz);
	float3 vector1b = normalize(input[2].position.xyz - input[1].position.xyz);
	normals[1] = cross(vector1b, -vector1a);

	float3 vector2a = normalize(input[0].position.xyz - input[2].position.xyz);
	float3 vector2b = normalize(input[1].position.xyz - input[2].position.xyz);
	normals[2] = cross(vector2b, vector2a);

	
	//loop through the vertexs updating the normal and transforming to world space
	for (int i = 0; i < 3; i++)
	{
			output.position = input[i].position;
			output.position = mul(output.position, worldMatrix);
			output.position = mul(output.position, viewMatrix);
			output.position = mul(output.position, projectionMatrix);
			output.tex = input[i].tex;
			output.normal = mul(normals[i], (float3x3) worldMatrix);
			output.normal = normalize(output.normal);
			output.worldPosition = mul(input[i].position, worldMatrix).xyz;
			triStream.Append(output);
	}
	triStream.RestartStrip();
}


