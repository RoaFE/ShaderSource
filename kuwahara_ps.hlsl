// Kuwahara pixel shader
// Calculate diffuse lighting for a single directional light (also texturing)

Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

cbuffer KuwarahaFilterBuffer: register(b0)
{
	int radi;
	float3 padding;
}





struct InputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
};

float4 main(InputType input) : SV_TARGET
{
	float radius = radi;
	float4 colour;
	colour = texture0.Sample(sampler0, input.tex);

	//Get the size of the texture
	float2 textureSize;
	texture0.GetDimensions(textureSize.x,textureSize.y);
	float2 uv = float2(1.0,1.0) / textureSize;
	//Number of pixels per sub region
	float numberOfPixels = ((radius + 1) * (radius + 1));

	//Setup variables for the mean colour and varience for each sub region
	float4 meanColour[4] = {float4(0.0,0.0,0.0,0.0), float4(0.0,0.0, 0.0, 0.0), float4(0.0,0.0, 0.0, 0.0), float4(0.0,0.0,0.0,0.0) };
	float4 varienceColour[4] = { float4(0.0,0.0,0.0,0.0), float4(0.0,0.0, 0.0, 0.0), float4(0.0,0.0, 0.0, 0.0), float4(0.0,0.0,0.0,0.0) };
	
	//declare 4 window subregions
	int4 window[4] = { int4(-radius,-radius,0,0),int4(0,-radius,radius,0),int4(0,0,radius,radius),int4(-radius,0,0,radius) };

	//For Each window
	float4 curColour;
	for (int curWindow = 0; curWindow < 4; curWindow++)
	{
		for (int j = window[curWindow].y; j <= window[curWindow].w; j++)
		{
			for (int i = window[curWindow].x; i <= window[curWindow].z; i++)
			{
				//Find the mean value of the all the pixels in the subWindow
				curColour = texture0.Sample(sampler0, input.tex + (float2(uv.x * i,uv.y * j)));
				meanColour[curWindow] += curColour;
				//And the varience
				varienceColour[curWindow] += (curColour * curColour);
			}
		}
		//Calculate the mean
		meanColour[curWindow] /= numberOfPixels;
		varienceColour[curWindow] = abs((varienceColour[curWindow] / numberOfPixels) - (meanColour[curWindow] * meanColour[curWindow]));
	}

	//1e + 2
	float minVarience = 4.71828182846;

	//Find the window with the minimum varience and return the mean colour of the window with the minimum varience
	for (int curWindow = 0; curWindow < 4; curWindow++)
	{
		float curVarience = varienceColour[curWindow].r + varienceColour[curWindow].g + varienceColour[curWindow].b;
		if (curVarience < minVarience)
		{
			minVarience = curVarience;
			colour = meanColour[curWindow];
		}
	}



	return colour;
}