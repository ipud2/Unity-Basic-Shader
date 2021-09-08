--writein 3dsmax2019

string ParamID = "0x003";

float Script : STANDARDSGLOBAL <
    string UIWidget = "none";
    string ScriptClass = "object";
    string ScriptOrder = "standard";
    string ScriptOutput = "color";
    string Script = "Technique=Main;";
> = 0.8;

//// UN-TWEAKABLES - AUTOMATICALLY-TRACKED TRANSFORMS ////////////////

float4x4 World : World < string UIWidget="None"; >;
float4x4 View : View < string UIWidget="None"; >;
float4x4 PROJECTION : PROJECTION < string UIWidget="None"; >;
float4x4 WorldViewInverseTranspose : WORLDVIEWIT < string UIWidget="None"; >;
float4x4 ProjInverse : PROJECTIONI < string UIWidget="None"; >;
float4x4 MVP : WORLDVIEWPROJ < string UIWidget="None"; >;
float4x4 WorldIT : WorldIT < string UIWidget="None"; >;


#ifdef _MAX_
int texcoord1 : Texcoord
<
	int Texcoord = 1;
	int MapChannel = 0;
	string UIWidget = "None";
>;

int texcoord2 : Texcoord
<
	int Texcoord = 2;
	int MapChannel = -2;
	string UIWidget = "None";
>;

int texcoord3 : Texcoord
<
	int Texcoord = 3;
	int MapChannel = -1;
	string UIWidget = "None";
>;
#endif

//// Get 3ds Max Builting Variables ////////////////////

// light direction (view space)
float3 lightDir : Direction <  
  string UIName = "Light Direction";
  string Object = "TargetLight";
  int RefID = 1;
> = {1,0,0};

/* data from application vertex buffer */
struct appdata 
{
	float4 Position		: POSITION;
	float3 Normal		: NORMAL;
	float3 Tangent		: TANGENT;
	float3 Binormal		: BINORMAL;
	float2 UV0			: TEXCOORD0;	
	float3 Color		: TEXCOORD1;
	float3 Alpha		: TEXCOORD2;
	float3 Illum		: TEXCOORD3;
	float3 UV1			: TEXCOORD4;
	float3 UV2			: TEXCOORD5;
	float3 UV3			: TEXCOORD6;
	float3 UV4			: TEXCOORD7;
};

struct vertexOutput
{
    float4 Pos       : SV_POSITION;
	float3 Color     : COLOR;
	float4 UV 		 : TEXCOORD0;
	float3 L		 : TEXCOORD1;
    float3 N		 : TEXCOORD2;
	float3 Alpha	 : TEXCOORD3;
	float3 LocalN	 : TEXCOORD4;
};

/// OutlinePass /
// parameters
float OutlineWidth<
	string UIName = "Outline Width";
	string UIWidget = "slider";
	float UIMin = 0.01f;
	float UIMax = 100.0f;	
>  = 0.24f;

float RampOffset<
	string UIName = "Ramp Offset";
	string UIWidget = "slider";
	float UIMin = -2.0f;
	float UIMax = 2.0f;	
>  = 0.0f;

float4 OutLineColor  <
	string UIName = "OutLine Color";
	string UIWidget = "Color";
> = float4( 0.0f, 0.0f, 0.0f, 1.0f );


bool g_BaseMapEnable <
	string UIName = "Enable BaseMap ";
> = false;

Texture2D <float4> g_BaseTexture : DiffuseMap< 
	string UIName = "Base Map";
	string ResourceType = "2D";
	int Texcoord = 0;
	int MapChannel = 1;
>;

SamplerState g_BaseSampler
{
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Wrap;
    AddressV = Wrap;
};

Texture2D <float4> g_ShadowTexture : DiffuseMap< 
	string UIName = "Shadow Map";
	string ResourceType = "2D";
	int Texcoord = 0;
	int MapChannel = 1;
>;

SamplerState g_ShadowSampler
{
	MinFilter = Linear;
	MagFilter = Linear;
	MipFilter = Linear;
	AddressU = Wrap;
    AddressV = Wrap;
};

// Texture2D <float4> g_LightMapTexture : DiffuseMap< 
// 	string UIName = "Light Map";
// 	string ResourceType = "2D";
// 	int Texcoord = 0;
// 	int MapChannel = 1;
// >;

// SamplerState g_LightMapSampler
// {
// 	MinFilter = Linear;
// 	MagFilter = Linear;
// 	MipFilter = Linear;
// 	AddressU = Wrap;
//     AddressV = Wrap;
// };

bool g_DebugVertexColorEnable <
	string UIName = "DebugVertexColor";
> = false;

bool g_DebugNormalEnable <
	string UIName = "Debug Normal ";
> = false;

bool g_DebugUVEnable <
	string UIName = "Debug UV";
> = false;

vertexOutput VS_Toon(appdata IN)
{
    vertexOutput Out = (vertexOutput)0;

	Out.Pos = mul(float4(IN.Position.xyz,1),MVP);
	Out.UV.xy = IN.UV0.xy;
	Out.LocalN.xyz = IN.Normal.xyz;

    float3 WorldPos = mul(float4(IN.Position.xyz,1),World).xyz;
    // Out.L = normalize(Lamp0Pos - WorldPos);

	Out.N = mul(IN.Normal,WorldIT).xyz;
	Out.Color = IN.Color;
	
	/*
    // 顶点色R控制描边
	// Alpha通道(W) 控制描边的宽度，默认值为1，值越小描边越细。
	// B通道(Z)控制深度偏移，默认为1，值越小内描边可以逐渐隐藏。
	float VertexColor_Width = IN.Alpha.x;
	//float VertexColor_PixelDepth = IN.Colour.b;

	// 像素深度偏移
	float4 WorldPos = mul(IN.Position,World);
	//float3 WorldViewDir = normalize(ViewInverse[3].xyz-WorldPos.xyz);
	//IN.Pos += -WorldViewDir * VertexColor_PixelDepth * PixelDepth * VertexColor_PixelDepth; 

    //float4 Pos = mul(float4(IN.Pos,1),WorldViewProj);
	float4 ViewPos = mul(WorldPos,View);
	float4 Pos = mul(ViewPos,Projection);

	// 为了让勾边与物体距离相机远近无关，描边粗细保持不变
    float3 ViewNormal = mul(IN.Normal,(float3x3)WorldViewInverseTranspose);
    // 乘以Pos.w，将法线变换到NDC空间
    float3 NDCNormal = normalize(mul(float4(ViewNormal,1),Projection)) * Pos.w;
    // 将近裁剪面右上角位置的顶点变换到观察空间
    float4 NearUpperRight = mul(float4(1,1,0,1),ProjInverse);
    // 求得屏幕宽高比
    float Aspect = abs(NearUpperRight.y / NearUpperRight.x);
    NDCNormal.x *= Aspect;
    Pos.xy += NDCNormal * OutlineWidth * 0.1f * IN.Alpha.x;
    Out.Pos = Pos;
	*/

    return Out;
}

float4 PS_Toon(vertexOutput IN) : COLOR
{   
	if(g_DebugUVEnable) return float4(IN.UV.xy,0,1);
	if(g_DebugNormalEnable) return float4(IN.LocalN.rgb,1);

	if(g_DebugVertexColorEnable) return float4(IN.Color.rrr,1);

    float4 Color;
	Color =  OutLineColor;
	float3 N = normalize(IN.N);
	float3 L = normalize(lightDir);
	float NL  = dot(N,L);

	// return float4(N.xyz,1);
	
	float4 Diffuse =float4(0,0,0,1);
	
	if(g_BaseMapEnable)
	{
		float4 BaseMap = g_BaseTexture.Sample(g_BaseSampler,IN.UV.xy);
		float4 ShadowMap = g_ShadowTexture.Sample(g_ShadowSampler,IN.UV.xy);
		// float4 LightMap = g_LightMapTexture.Sample(g_LightMapSampler,IN.UV.xy);
		float ShadowMask = BaseMap.a;
		
		float4 BrightSide = BaseMap;
		float4 DarkSide = ShadowMap*BaseMap;
		// Diffuse = lerp(DarkSide, BrightSide,step(RampOffset + IN.Color.g*2-1 ,NL) );
		Diffuse = lerp(DarkSide, BrightSide,step(RampOffset,NL)*ShadowMask);
		//Diffuse = ShadowMask;
	}
	else
	{
		return NL;
	}
	
	return float4(Diffuse.xyz,1);

}

//Outline

vertexOutput VS_Outline(appdata IN)
{
    vertexOutput Out = (vertexOutput)0;

	// IN.Position.xyz += normalize( IN.Normal.xyz) * OutlineWidth*IN.Alpha.x;
	IN.Position.xyz += normalize( IN.Normal.xyz) * OutlineWidth*IN.Color.r;
	Out.Pos = mul(float4(IN.Position.xyz,1),MVP);
	//Out.Alpha = IN.Alpha;
	// Out.UV.xy = IN.UV0;

    // float3 WorldPos = mul(float4(IN.Position.xyz,1),World).xyz;
    // Out.L = normalize(Lamp0Pos - WorldPos);

	// Out.N = mul(IN.Normal,WorldIT).xyz;

	/*
    // 顶点色R控制描边
	// Alpha通道(W) 控制描边的宽度，默认值为1，值越小描边越细。
	// B通道(Z)控制深度偏移，默认为1，值越小内描边可以逐渐隐藏。
	float VertexColor_Width = IN.Alpha.x;
	//float VertexColor_PixelDepth = IN.Colour.b;

	// 像素深度偏移
	float4 WorldPos = mul(IN.Position,World);
	//float3 WorldViewDir = normalize(ViewInverse[3].xyz-WorldPos.xyz);
	//IN.Pos += -WorldViewDir * VertexColor_PixelDepth * PixelDepth * VertexColor_PixelDepth; 

    //float4 Pos = mul(float4(IN.Pos,1),WorldViewProj);
	float4 ViewPos = mul(WorldPos,View);
	float4 Pos = mul(ViewPos,Projection);

	// 为了让勾边与物体距离相机远近无关，描边粗细保持不变
    float3 ViewNormal = mul(IN.Normal,(float3x3)WorldViewInverseTranspose);
    // 乘以Pos.w，将法线变换到NDC空间
    float3 NDCNormal = normalize(mul(float4(ViewNormal,1),Projection)) * Pos.w;
    // 将近裁剪面右上角位置的顶点变换到观察空间
    float4 NearUpperRight = mul(float4(1,1,0,1),ProjInverse);
    // 求得屏幕宽高比
    float Aspect = abs(NearUpperRight.y / NearUpperRight.x);
    NDCNormal.x *= Aspect;
    Pos.xy += NDCNormal * OutlineWidth * 0.1f * IN.Alpha.x;
    Out.Pos = Pos;
	*/

    return Out;
}

float4 PS_Outline(vertexOutput IN) : COLOR
{   
	return OutLineColor;
}


// RasterizerStateS /
RasterizerState RS_CullBack
{
    //FillMode = WIREFRAME; 
    CullMode = Back;
};

RasterizerState RS_CullFront
{
    CullMode = Front;
};

///// TECHNIQUES /////////////////////////////
fxgroup dx11
{
// technique11 Main_11 <string Script = "Pass=p0;Pass=p1";>
technique11 Main_11 <string Script = "Pass=p0;Pass=p1";>
{
	pass p0 <string Script = "Draw=geometry;";> 
    {
		SetRasterizerState(RS_CullBack);
        SetVertexShader(CompileShader(vs_5_0,VS_Toon()));
        SetGeometryShader( NULL );
		SetPixelShader(CompileShader(ps_5_0,PS_Toon()));
    }
	pass p1 <string Script = "Draw=geometry;";> 
    {
        SetRasterizerState(RS_CullFront);
        SetVertexShader(CompileShader(vs_5_0,VS_Outline()));
        SetGeometryShader( NULL );
	    SetPixelShader(CompileShader(ps_5_0,PS_Outline()));
    }
}
}


