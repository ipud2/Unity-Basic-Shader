#ifndef PBRBRDF
#define PBRBRDF

#define PI 3.141592654

//D
float D_DistributionGGX(float3 N, float3 H, float Roughness)
{
    float a = Roughness * Roughness;
    // float a             = Roughness;
    float a2 = a * a;
    float NH = max(dot(N, H), 0);
    float NH2 = NH * NH;
    float nominator = a2;
    float denominator = (NH2 * (a2 - 1.0) + 1.0);
    denominator = PI * denominator * denominator;

    return nominator / max(denominator, 0.0000001); //防止分母为0
    // return              nominator/ (denominator) ;//防止分母为0
}

//G
float GeometrySchlickGGX(float NV, float Roughness)
{
    float r = Roughness + 1.0;
    float k = r * r / 8.0;
    float nominator = NV;
    float denominator = k + (1.0 - k) * NV;
    // return nominator/ max(denominator,0.001) ;//防止分母为0
    return nominator / max(denominator, 0.0000001); //防止分母为0
}

float G_GeometrySmith(float3 N, float3 V, float3 L, float Roughness)
{
    float NV = max(dot(N, V), 0);
    float NL = max(dot(N, L), 0);

    float ggx1 = GeometrySchlickGGX(NV, Roughness);
    float ggx2 = GeometrySchlickGGX(NL, Roughness);

    return ggx1 * ggx2;
}

//F
float3 F_FrenelSchlick(float HV, float3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - HV, 5);
}

float3 FresnelSchlickRoughness(float NV, float3 F0, float Roughness)
{
    return F0 + (max(float3(1.0 - Roughness, 1.0 - Roughness, 1.0 - Roughness), F0) - F0) * pow(1.0 - NV, 5.0);
}

//UE4 Black Ops II modify version
float2 EnvBRDFApprox(float Roughness, float NoV)
{
    // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
    // Adaptation to fit our G term.
    const float4 c0 = {-1, -0.0275, -0.572, 0.022};
    const float4 c1 = {1, 0.0425, 1.04, -0.04};
    float4 r = Roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
    float2 AB = float2(-1.04, 1.04) * a004 + r.zw;
    return AB;
}

float3 Specular_GGX(float3 N, float3 L, float3 H, float3 V, float NV, float NL, float HV, float Roughness, float3 F0)
{
    float D = D_DistributionGGX(N, H, Roughness);
    float3 F = F_FrenelSchlick(HV, F0);
    float G = G_GeometrySmith(N, V, L, Roughness);
    float3 nominator = D * F * G;
    float denominator = max(4 * NV * NL, 0.001);
    float3 Specular = nominator / denominator;
    Specular = max(Specular, 0);
    return Specular;
}

// Black Ops II
// float2 EnvBRDFApprox(float Roughness, float NV)
// {
//     float g = 1 -Roughness;
//     float4 t = float4(1/0.96, 0.475, (0.0275 - 0.25*0.04)/0.96, 0.25);
//     t *= float4(g, g, g, g);
//     t += float4(0, 0, (0.015 - 0.75*0.04)/0.96, 0.75);
//     float A = t.x * min(t.y, exp2(-9.28 * NV)) + t.z;
//     float B = t.w;
//     return float2 ( t.w-A,A);
// }如果

float3 ACESToneMapping(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

float4 ACESToneMapping(float4 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x * (a * x + b)) / (x * (c * x + d) + e));
}

struct MeshData
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float4 tangent :TANGENT;
    float3 normal : NORMAL;
};

struct Vertex2Fragment
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 tangent : TEXCOORD1;
    float3 bitangent : TEXCOORD2;
    float3 normal : TEXCOORD3;
    float3 worldPosition: TEXCOORD4;
    float3 localPostion : TEXCOORD5;
};

Vertex2Fragment vert(MeshData v)
{
    Vertex2Fragment o = (Vertex2Fragment)0;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;
    o.normal = UnityObjectToWorldNormal(v.normal);
    o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
    o.localPostion = v.vertex.xyz;
    o.tangent = UnityObjectToWorldDir(v.tangent);
    //o.bitangent = cross(o.normal,o.tangent) * v.tangent.w;
    return o;
}

float3 SpecularIndirect(float3 N, float3 V, float Roughness, float3 F0)
{
    //Specular
    float3 R = reflect(-V, N);
    float NV = dot(N, V);
    float3 F_IndirectLight = FresnelSchlickRoughness(NV, F0, Roughness);
    // return F_IndirectLight.xyzz;
    // float3 F_IndirectLight = F_FrenelSchlick(NV,F0);
    float mip = Roughness * (1.7 - 0.7 * Roughness) * UNITY_SPECCUBE_LOD_STEPS;
    float4 rgb_mip = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, R, mip);

    //间接光镜面反射采样的预过滤环境贴图
    float3 EnvSpecularPrefilted = DecodeHDR(rgb_mip, unity_SpecCube0_HDR);

    //LUT采样
    // float2 env_brdf = tex2D(_BRDFLUTTex, float2(NV, Roughness)).rg; //0.356
    // float2 env_brdf = tex2D(_BRDFLUTTex, float2(lerp(0, 0.99, NV), lerp(0, 0.99, Roughness))).rg;

    //数值近似
    float2 env_brdf = EnvBRDFApprox(Roughness, NV);
    float3 Specular_Indirect = EnvSpecularPrefilted * (F_IndirectLight * env_brdf.r + env_brdf.g);
    return Specular_Indirect;
}

float4 GodPBR(in Vertex2Fragment i,in SurfaceOutputStandard o)
{
    //Variable
    float3 T = normalize(i.tangent);
    float3 N = normalize(i.normal);
    float3 B = normalize(cross(N, T));
    // float3 B = normalize( i.bitangent);
    float3 L = normalize(UnityWorldSpaceLightDir(i.worldPosition.xyz));
    float3 V = normalize(UnityWorldSpaceViewDir(i.worldPosition.xyz));
    float3 H = normalize(V + L);

    //================== Normal Map  ============================================== //
    float3 NormalMap = o.Normal;
    float3x3 TBN = float3x3(T, B, N);
    N = normalize(mul(NormalMap, TBN));
    N = normalize(N);

    float4 FinalColor = 0;
    //================== PBR  ============================================== //
    float3 BaseColor = o.Albedo;
    float Roughness = 1 - o.Smoothness;
    float Metallic = o.Metallic;

    float3 Emission = o.Emission;
    float3 AO = o.Occlusion;
    float3 F0 = lerp(0.04, BaseColor, Metallic);
    float3 Radiance = _LightColor0.xyz;

    //================== Direct Light  ============================================== //
    //Specular
    //Cook-Torrance BRDF
    float HV = max(dot(H, V), 0);
    float NV = max(dot(N, V), 0);
    float NL = max(dot(N, L), 0);

    // float D = D_DistributionGGX(N,H,Roughness);
    float3 F = F_FrenelSchlick(HV, F0);
    // float G = G_GeometrySmith(N,V,L,Roughness);
    float3 KS = F;
    float3 KD = 1 - KS;
    KD *= 1 - Metallic;
    // float3 nominator = D*F*G;
    // float denominator = max(4*NV*NL,0.001);
    // float3 Specular = nominator/denominator;
    // Specular =max( Specular,0);

    float3 Specular = Specular_GGX(N, L, H, V, NV, NL, HV, Roughness, F0);

    //Diffuse
    // float3 Diffuse = KD * BaseColor / PI;
    float3 Diffuse = KD * BaseColor; //没有除以 PI

    float3 DirectLight = (Diffuse + Specular) * NL * Radiance;
    //================== ClearCoat  ============================================== //
    // float LH = dot(L,H);
    // float NH = dot(N,H);
    // float D_CleatCoat = D_DistributionGGX(N,H,_RoughnessClearCoat);
    // float G_CleatCoat = G_GeometrySmith(N,V,L,_RoughnessClearCoat);
    // float F_ClearCoat = F_FrenelSchlick(HV,0.04)*_ClearCoat;

    // D_CleatCoat = max(0,D_CleatCoat);
    // F_ClearCoat = max(0,F_ClearCoat);
    // G_CleatCoat = max(0,G_CleatCoat);   
    // float Specular_ClearCoat = D_CleatCoat*G_CleatCoat*F_ClearCoat/ max(4*NV*NL,0.001);
  
    //================== Indirect Light  ============================================== //
    float3 IndirectLight = 0;

    //Specular
    float3 R = reflect(-V, N);
    float3 F_IndirectLight = FresnelSchlickRoughness(NV, F0, Roughness);
    // return F_IndirectLight.xyzz;
    // float3 F_IndirectLight = F_FrenelSchlick(NV,F0);
    float mip = Roughness * (1.7 - 0.7 * Roughness) * UNITY_SPECCUBE_LOD_STEPS;
    float4 rgb_mip = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, R, mip);

    //间接光镜面反射采样的预过滤环境贴图
    float3 EnvSpecularPrefilted = DecodeHDR(rgb_mip, unity_SpecCube0_HDR);

    //LUT采样
    // float2 env_brdf = tex2D(_BRDFLUTTex, float2(NV, Roughness)).rg; //0.356
    // float2 env_brdf = tex2D(_BRDFLUTTex, float2(lerp(0, 0.99, NV), lerp(0, 0.99, Roughness))).rg;

    //数值近似
    float2 env_brdf = EnvBRDFApprox(Roughness, NV);
    float3 Specular_Indirect = EnvSpecularPrefilted * (F_IndirectLight * env_brdf.r + env_brdf.g);

    //Diffuse           
    float3 KD_IndirectLight = float3(1, 1, 1) - F_IndirectLight;
    // return KD_IndirectLight.xyzz;
    KD_IndirectLight *= 1 - Metallic;

    float3 irradianceSH = ShadeSH9(float4(N, 1));
    // return irradianceSH.rgbb;
    // float3 Diffuse_Indirect = irradianceSH * BaseColor *KD_IndirectLight / PI;
    float3 Diffuse_Indirect = irradianceSH * BaseColor * KD_IndirectLight; //没有除以 PI

    IndirectLight = (Diffuse_Indirect + Specular_Indirect) * AO;

    FinalColor.rgb = DirectLight + IndirectLight;
    FinalColor.rgb += Emission;
    FinalColor.a = o.Alpha;
    //HDR => LDR aka ToneMapping
    // return G;
    // FinalColor.rgb = ACESToneMapping(FinalColor.rgb);

    //Linear => Gamma
    // FinalColor = pow(FinalColor,1/2.2);

    return FinalColor;
}


#endif
