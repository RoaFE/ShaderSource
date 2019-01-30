cbuffer MatrixBuffer : register(b0)
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
};

//quad to be generated at vertex
cbuffer GeometryBuffer : register(b1)
{
	static float3 g_position[4] =
	{
		float3(-0.02, 0.02, 0),
		float3(-0.02, -0.02, 0),
		float3(0.02, 0.02, 0),
		float3(0.02, -0.02, 0)
	};
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
};

//rotation function to make the particle face outwards
matrix <float, 4, 4> rotation(float xAngle, float yAngle, float3 position)
{
	//rotate in y
	matrix <float, 4, 4> yRotation =
	{
		cos(-xAngle), 0.0f, -sin(-xAngle), 0.0f,
		0.0f, 1.0f, 0.0f, 0.0f,
		sin(-xAngle), 0.0f, cos(-xAngle), 0.0f,
		0.0f, 0.0f, 0.0f, 1.0f
	};
	//rotate in z
	matrix <float, 4, 4> xRotation =
	{
		1.0f, 0.0f, 0.0f, 0.0f,
		0.0f, cos(yAngle), sin(yAngle), 0.0f,
		0.0f, -sin(yAngle), cos(yAngle), 0.0f,
		0.0f, 0.0f, 0.0f, 1.0f
	};

	//transform back to origin
	matrix <float, 4, 4> translation =
	{
		1.0f, 0.0f, 0.0f, 0.0f,
		0.0f, 1.0f, 0.0f, 0.0f,
		0.0f, 0.0f, 1.0f, 0.0f,
		position.x, -position.y, -position.z, 1.0f
	};

	//transform back to orignal spot
	matrix <float, 4, 4> unTranslation =
	{
		1.0f, 0.0f, 0.0f, 0.0f,
		0.0f, 1.0f, 0.0f, 0.0f,
		0.0f, 0.0f, 1.0f, 0.0f,
		position.x, position.y, position.z, 1.0f
	};

	//combine matricies
	matrix <float, 4, 4> composition;
	composition = mul(yRotation, translation);
	composition = mul(xRotation, composition);
	composition = mul(unTranslation, composition);

	return composition;
}


[maxvertexcount(4)]
void main(triangle InputType input[3], inout TriangleStream<OutputType> triStream)
{
	OutputType output;

	//calculate normals
	float3 normals[3];
	
	float3 vector0a = normalize(input[1].position.xyz - input[0].position.xyz);
	float3 vector0b = normalize(input[2].position.xyz - input[0].position.xyz);
	normals[0] = cross(vector0b, vector0a);

	float3 vector1a = normalize(input[0].position.xyz - input[1].position.xyz);
	float3 vector1b = normalize(input[2].position.xyz - input[1].position.xyz);
	normals[1] = cross(vector1b, -vector1a);

	float3 vector2a = normalize(input[0].position.xyz - input[2].position.xyz);
	float3 vector2b = normalize(input[1].position.xyz - input[2].position.xyz);
	normals[2] = cross(vector2b, vector2a);

	float3 avgNormal = normals[0] + normals[1] + normals[2];


	//find the average
	avgNormal /= 3;

	//normalise the average normal;
	avgNormal = normalize(avgNormal);

	//Find the xAngle
	float dotProduct = -avgNormal.z;
	float determinantProduct = -avgNormal.x;
	float xAngle = atan2(determinantProduct, dotProduct);

	//Fine the Y angle
	dotProduct = -avgNormal.z;
	determinantProduct = -avgNormal.y;
	float yAngle = atan2(determinantProduct, dotProduct);

	//if less than - 90 shift to cancel double rotation
	if (yAngle < -1.5708 && yAngle > -3.14)
	{
		yAngle += 3.14;
	}
	//if greater than 90 shift to cancel double rotation
	if (yAngle > 1.5708 && yAngle < 3.14)
	{
		yAngle -= 3.14;
	}
	float4 midPoint = { 0.0,0.0,0.0,0.0 };
	float2 midTex = { 0.0,0.0 };
	//for each vertex
	for (int i = 0; i < 3; i++)
	{	
		midPoint += input[i].position;
		midTex += input[i].tex;

		//draw a quad
		for (int j = 0; j < 4; j++)
		{
			matrix <float, 4, 4> composition = rotation(xAngle, yAngle, g_position[j]);
			output.position = input[i].position + mul(composition, float4(g_position[j], 1.0));
			output.position = mul(output.position, worldMatrix);
			output.position = mul(output.position, viewMatrix);
			output.position = mul(output.position, projectionMatrix);
			output.tex = input[i].tex + float2(g_position[j].x / 2, -g_position[j].y / 2);
			output.normal = mul(avgNormal, (float3x3) worldMatrix);
			output.normal = normalize(output.normal);
			triStream.Append(output);
		}
	}
	midPoint /= 3;
	midTex /= 3;
	triStream.RestartStrip();
}


