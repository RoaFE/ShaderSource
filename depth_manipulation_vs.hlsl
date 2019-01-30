cbuffer MatrixBuffer : register(b0)
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
};


cbuffer TimeBuffer: register(b1)
{
	float time;
	float height;
	float frequency;
	float speed;
	float4 offset;
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
	float4 depthPosition : TEXCOORD0;
};


float4 shiftPosition(float3 position, float4 displace, float3 normal)
{
	float dx = position.x + displace.x;
	float dy = position.y + displace.y;
	float dz = position.z + displace.z;

	//shift in Z
	float dx2 = dx * dx, dy2 = dy * dy, dz2 = dz * dz;
	float angleZ = sqrt(dx2 + dy2);
	angleZ = -time * speed + angleZ * frequency;
	position.z = sin(angleZ) * height * normal.z;

	//shift in y
	float angleY = sqrt(dx2 + dz2);
	angleY = -time * speed + angleY * frequency;
	position.y = sin(angleY) * height * normal.y;

	//shift in x
	float angleX = sqrt(dz2 + dy2);
	angleX = -time * speed + angleX * frequency;
	position.x = sin(angleX) * height * normal.x;



	return float4(position.x, position.y, position.z, 1.0);
}

OutputType main(InputType input)
{
	OutputType output;

	output.position = shiftPosition(float3(input.position.x, input.position.y, input.position.z), offset, input.normal) + input.position;

	// Calculate the position of the vertex against the world, view, and projection matrices.
	output.position = mul(output.position, worldMatrix);
	output.position = mul(output.position, viewMatrix);
	output.position = mul(output.position, projectionMatrix);

	// Store the position value in a second input value for depth value calculations.
	output.depthPosition = output.position;

	return output;
}