// Tessellation Hull Shader
// Prepares control points for tessellation
Texture2D texture0 : register(t0);
SamplerState Sampler0 : register(s0);



cbuffer TesselationBuffer : register(b0)
{
	float distFactor;
	int minTessValue;
	int maxTessValue;
	int padding;
}

cbuffer cameraBuffer: register(b1)
{
	float4 cameraPos;
}

cbuffer MatrixBuffer : register(b2)
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
};

cbuffer ManipulationBuffer : register(b3)
{
	float time;
	float height;
	float frequency;
	float speed;
}


struct InputType
{
    float3 position : POSITION;
    float4 colour : COLOR;
	float2 tex : TEXCOORD0;

};

struct ConstantOutputType
{
    float edges[4] : SV_TessFactor;
    float inside[2] : SV_InsideTessFactor;
};

struct OutputType
{
    float3 position : POSITION;
    float4 colour : COLOR;
	float2 tex : TEXCOORD0;
};

int distanceMultiplier(float3 camPos, float3 vertPos, float2 texPos)
{
	//Sample height map
	float displacementVal = texture0.SampleLevel(Sampler0, texPos, 0);
	//Multiple height value by wave value
	displacementVal *= max(0, height * sin((vertPos.x + (speed*time))*frequency));
	vertPos.y += displacementVal;
	//transform to world space
	vertPos = mul(float4(vertPos, 1.0f), worldMatrix).xyz;
	//Find the distance between camera and the current position
	int dist = distance(camPos,vertPos);
	//Calculate the tesselation value depending on the distance
	dist = distFactor - dist;
	dist /= distFactor/maxTessValue;
	//make sure the tesselation is between the max and min
	int tessellationFactor = max(minTessValue, dist);
	tessellationFactor = min(maxTessValue, tessellationFactor);
	//If no tesselation don't do any displacement other wise do
	displacementVal = ceil(saturate(displacementVal));
	tessellationFactor = tessellationFactor * displacementVal + (1 - displacementVal);

	return tessellationFactor;
}


ConstantOutputType PatchConstantFunction(InputPatch<InputType, 4> inputPatch, uint patchId : SV_PrimitiveID)
{    
    ConstantOutputType output;


    // Set the tessellation factors for the four edges of the square.
	output.edges[0] = distanceMultiplier(cameraPos.xyz, lerp(inputPatch[0].position, inputPatch[1].position, 0.5), lerp(inputPatch[0].tex, inputPatch[1].tex, 0.5));	// tessellationFactor;
	output.edges[1] = distanceMultiplier(cameraPos.xyz, lerp(inputPatch[0].position, inputPatch[3].position, 0.5), lerp(inputPatch[0].tex, inputPatch[3].tex, 0.5));	// tessellationFactor;
	output.edges[2] = distanceMultiplier(cameraPos.xyz, lerp(inputPatch[2].position, inputPatch[3].position, 0.5), lerp(inputPatch[2].tex, inputPatch[3].tex, 0.5));	// tessellationFactor;
	output.edges[3] = distanceMultiplier(cameraPos.xyz, lerp(inputPatch[1].position, inputPatch[2].position, 0.5), lerp(inputPatch[1].tex, inputPatch[2].tex, 0.5));	// tessellationFactor;

    // Set the tessellation factor for tessallating inside the square.
	float3 midPoint = lerp(lerp(inputPatch[0].position, inputPatch[1].position, 0.5), lerp(inputPatch[2].position, inputPatch[3].position, 0.5),0.5);
	float2 midTex = lerp(lerp(inputPatch[0].tex, inputPatch[1].tex, 0.5), lerp(inputPatch[2].tex, inputPatch[3].tex, 0.5), 0.5);
	output.inside[0] =  distanceMultiplier(cameraPos.xyz, midPoint, midTex);// tessellationFactor;
	output.inside[1] =  distanceMultiplier(cameraPos.xyz, midPoint, midTex);// tessellationFactor;

    return output;
}


[domain("quad")]
[partitioning("integer")]
[outputtopology("triangle_ccw")]
[outputcontrolpoints(4)]
[patchconstantfunc("PatchConstantFunction")]

OutputType main(InputPatch<InputType, 4> patch, uint pointId : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
{
    OutputType output;


    // Set the position for this control point as the output position.
    output.position = patch[pointId].position;

    // Set the input colour as the output colour.
    output.colour = patch[pointId].colour;

	output.tex = patch[pointId].tex;

    return output;
}