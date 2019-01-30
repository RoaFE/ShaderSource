//manipulation vertex sshader



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
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	float3 worldPosition : TEXCOORD1;
};

float4 shiftPosition(float3 position, float4 displace ,float3 normal)
{
	//Offset ripple centre
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


//Failed normals attempts
//float3 normal(float4 position, float4 newPosition, float4 displace, float3 normal)
//{
//	float4 pos1 = shiftPosition(position.xyz + float3(1, 0, 0), displace, normal);
//	float4 pos2 = shiftPosition(position + float3(0, 1, 0), displace, normal);
//	//float4 pos3 = shiftPosition(position + float3(0, 0, 1), displace, normal);
//	pos1 = newPosition - pos1;
//	pos2 = newPosition - pos2;
//	//pos3 = newPosition - pos3;
//	
//	normal = cross(pos1, pos2).xyz;
//	return normal;
//}

//float3 normalTangentTechnique(float4 position, float3 normal, float4 displace)
//{
//	float dx = position.x + displace.x;
//	float dy = position.y + displace.y;
//	float dz = position.z + displace.z;
//
//	float dx2 = dx * dx, dy2 = dy * dy, dz2 = dz * dz;
//
//	float freqZ = sqrt(dx2 + dy2);
//	float angleZ = -time * speed + freqZ * frequency;
//
//	float freqY = sqrt(dx2 + dz2);
//	float angleY = -time * speed + freqY * frequency;
//
//	float freqX = sqrt(dz2 + dy2);
//	float angleX = -time * speed + freqX * frequency;
//
//
//	float dfdx = height * -time * speed * cos(angleX) * sin(angleY) * sin(angleZ);
//	float dfdy = height * -time * speed * sin(angleX) * cos(angleY) * sin(angleZ);
//	float dfdz = height * -time * speed * sin(angleX) * sin(angleY) * cos(angleZ);
//	float3 tx = float3(dx, dy, dfdx);
//	float3 ty = float3(dx, dy, dfdy);
//
//	float3 newNormal = cross(tx, ty);
//
//	return (newNormal);
//}

//passing to geometry shader no need to multiply by world matrix or anything
InputType main(InputType input)
{
	input.position = shiftPosition(float3(input.position.x, input.position.y, input.position.z), offset, input.normal) + input.position;
	//input.normal = normal(input.position, newPosition, offset, input.normal);
	//input.position = newPosition;

	// Store the texture coordinates for the pixel shader.
	input.tex.x = input.tex.x + (time);
	//output.tex = input.tex;

	//modify normals
	//input.normal.x = 1 - (height * cos(input.position.x + (time*speed)));
	//input.normal.y = abs(height * cos((frequency * input.position.y) + (time*speed)));


	// Calculate the position of the vertex against the world, view, and projection matrices.
	/*output.position = mul(input.position, worldMatrix);
	output.position = mul(output.position, viewMatrix);
	output.position = mul(output.position, projectionMatrix);*/
	//output.position = input.position;


	// Calculate the normal vector against the world matrix only and normalise.
	/*output.normal = mul(input.normal, (float3x3)worldMatrix);
	output.normal = normalize(output.normal);*/

	//output.normal = input.normal;

	//output.worldPosition = mul(input.position, worldMatrix).xyz;

	return input;
}