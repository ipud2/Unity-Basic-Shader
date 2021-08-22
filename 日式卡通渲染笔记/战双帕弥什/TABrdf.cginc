#ifndef TABRDF
#define TABRDF

#ifndef PI
    #define PI 3.141592654
#endif

//D
float D_DistributionGGX(float3 N,float3 H,float Roughness)
{
    float a             = Roughness*Roughness;
    // float a             = Roughness;
    float a2            = a*a;
    float NH            = max(dot(N,H),0);
    float NH2           = NH*NH;
    float nominator     = a2;
    float denominator   = (NH2 * (a2-1.0) +1.0);
    denominator         = PI * denominator*denominator;
    
    return              nominator/ max(denominator,0.0000001) ;//防止分母为0
    // return              nominator/ (denominator) ;//防止分母为0
}
//G
float GeometrySchlickGGX(float NV,float Roughness)
{
    float r = Roughness +1.0;
    float k = r*r / 8.0;
    float nominator = NV;
    float denominator = k + (1.0-k) * NV;
    // return nominator/ max(denominator,0.001) ;//防止分母为0
    return              nominator/ max(denominator,0.0000001) ;//防止分母为0
}

float G_GeometrySmith(float3 N,float3 V,float3 L,float Roughness)
{
    float NV = max(dot(N,V),0);
    float NL = max(dot(N,L),0);

    float ggx1 = GeometrySchlickGGX(NV,Roughness);
    float ggx2 = GeometrySchlickGGX(NL,Roughness);
    return ggx1*ggx2;
}

//F
float3 F_FrenelSchlick(float HV,float3 F0)
{
    return F0 +(1.0 - F0)*pow(1.0-HV,5);
}

float3 FresnelSchlickRoughness(float NV,float3 F0,float Roughness)
{
    return F0 + (max(float3(1.0 - Roughness, 1.0 - Roughness, 1.0 - Roughness), F0) - F0) * pow(1.0 - NV, 5.0);
}

//UE4 Black Ops II modify version
float2 EnvBRDFApprox(float Roughness, float NoV )
{
    // [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
    // Adaptation to fit our G term.
    const float4 c0 = { -1, -0.0275, -0.572, 0.022 };
    const float4 c1 = { 1, 0.0425, 1.04, -0.04 };
    float4 r = Roughness * c0 + c1;
    float a004 = min( r.x * r.x, exp2( -9.28 * NoV ) ) * r.x + r.y;
    float2 AB = float2( -1.04, 1.04 ) * a004 + r.zw;
    return AB;
}

float3 ACESToneMapping(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}
float4 ACESToneMapping(float4 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x+b))/(x*(c*x+d)+e));
}

float3 InvACESToneMappingCurve(float3 x) //逆tonemapping
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float s = 0.14;
    float3 aa = a - x * c;
    float3 bb = b - x * d;
    float3 cc = -x * s;
    return (-bb + sqrt(bb * bb - 4 * aa * cc)) / (2 * aa);
}

float4 InvACESToneMappingCurve(float4 x) //逆tonemapping
{
    float a = 2.51;
    float b = 0.03;
    float c = 2.43;
    float d = 0.59;
    float s = 0.14;
    float4 aa = a - x * c;
    float4 bb = b - x * d;
    float4 cc = -x * s;
    return (-bb + sqrt(bb * bb - 4 * aa * cc)) / (2 * aa);
}


//对外调用函数
float Specular_Direct_GGX(float3 N,float3 L,float3 V,float3 H,float Roughness,float Metallic,float3 BaseColor)
{
    //Cook-Torrance BRDF
    float HV = max(dot(H,V),0);
    float NV = max(dot(N,V),0);
    float NL = max(dot(N,L),0);

    float3 F0 = lerp(0.04,BaseColor,Metallic);

    float D = D_DistributionGGX(N,H,Roughness);
    float3 F = F_FrenelSchlick(HV,F0);
    float G = G_GeometrySmith(N,V,L,Roughness);

    float3 KS = F;
    float3 KD = 1-KS;
    KD*=1-Metallic;
    float3 nominator = D*F*G;
    float denominator = max(4*NV*NL,0.001);
    float3 Specular = nominator/denominator;
    return Specular;
}

float3 Specular_GGX(float3 N,float3 L,float3 H,float3 V,float Roughness,float3 F0)
{
    float NV = dot(N,V);
    float NL = dot(N,L);
    float HV = dot(H,V);
    float D = D_DistributionGGX(N,H,Roughness);
    float3 F = F_FrenelSchlick(HV,F0);
    float G = G_GeometrySmith(N,V,L,Roughness);
    float3 nominator = D*F*G;
    float denominator = max(4*NV*NL,0.001);
    float3 Specular = nominator/denominator;
    Specular =max( Specular,0);
    return Specular;
}
// #inclde "Unity.cg"
// float3 Specular_Indirect_GGX(float3 N,float3 V,float Roughness,float3 F0)
// {
//     //Specular
//     float3 R = reflect(-V,N);
//     float NV = dot(N,V);
//     float3 F_IndirectLight = FresnelSchlickRoughness(NV,F0,Roughness);
//     // return F_IndirectLight.xyzz;
//     // float3 F_IndirectLight = F_FrenelSchlick(NV,F0);
//     float mip = Roughness * (1.7 - 0.7 * Roughness) * UNITY_SPECCUBE_LOD_STEPS ;
//     float4 rgb_mip = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,R,mip);
//
//     //间接光镜面反射采样的预过滤环境贴图
//     float3 EnvSpecularPrefilted = DecodeHDR(rgb_mip, unity_SpecCube0_HDR);
//                
//     //LUT采样
//     // float2 env_brdf = tex2D(_BRDFLUTTex, float2(NV, Roughness)).rg; //0.356
//     // float2 env_brdf = tex2D(_BRDFLUTTex, float2(lerp(0, 0.99, NV), lerp(0, 0.99, Roughness))).rg;
//              
//     //数值近似
//     float2 env_brdf = EnvBRDFApprox(Roughness,NV);
//     float3 Specular_Indirect = EnvSpecularPrefilted  * (F_IndirectLight * env_brdf.r + env_brdf.g);
//     return Specular_Indirect;
// }

//高光形变
struct StylizedSpecularParam 
{
    float3 BaseColor;      // 该像素的反射率，反应了像素的基色   
    float3 Normal;     // 该像素的法线方向  
    float Shininess;     // 该像素的高光指数    
    float Gloss;         // 该像素的高光光滑度，值越大高光反射越清晰，反之越模糊    
    float Threshold;
    float3 dv;
    float3 du;
};
float3 RotateAroundAxis(float3 center, float3 original, float3 u, float angle)
{
    original -= center;
    float C = cos(angle);
    float S = sin(angle);
    float t = 1 - C;
    float m00 = t * u.x * u.x + C;
    float m01 = t * u.x * u.y - S * u.z;
    float m02 = t * u.x * u.z + S * u.y;
    float m10 = t * u.x * u.y + S * u.z;
    float m11 = t * u.y * u.y + C;
    float m12 = t * u.y * u.z - S * u.x;
    float m20 = t * u.x * u.z - S * u.y;
    float m21 = t * u.y * u.z + S * u.x;
    float m22 = t * u.z * u.z + C;
    float3x3 finalMatrix = float3x3(m00, m01, m02, m10, m11, m12, m20, m21, m22);
    return mul(finalMatrix, original) + center;
}

void Op(inout float3 h, inout float3 du, inout float3 dv, float3 normal)
{
    // translate
    h = h + 0.5 * du +0 * dv;
    h = normalize(h);
    // rotate
    du = RotateAroundAxis(float3(0, 0, 0), du, normal, 1.57);
    dv = RotateAroundAxis(float3(0, 0, 0), dv, normal, 1.57);
    // directional scaling
    h = h - 0.5 * dot(h, du) * du;
    h = normalize(h);
    // split
    h = h - 0.07 * sign(dot(h, du)) * du - 0.1 * sign(dot(h, dv)) * dv;
    h = normalize(h);
    // sqruare
    float theta = min(acos(dot(h, du)), acos(dot(h, dv)));
    float sqrnorm = sin(2 * theta);
    //h = h - 0.1 * sqrnorm * (dot(h, du) * du + dot(h, dv) * dv);
    float m = min(abs(dot(h, du)), abs(dot(h, dv)));
    m = sin(2 * acos(m));
    m = sqrt(m);
    h = h - 0.5 * m * (dot(h, du) * du + dot(h, dv) * dv);
    h = normalize(h);
}
//Blin-Phong高光形变
float StylizedSpecularLight_BlinPhong(in StylizedSpecularParam Param, in float3 H)
{
    //Specular_Direct_GGX(float3 N,float3 L,float3 V,float Roughness,float Metallic,float3 BaseColor)

    float3 h = H;
    Op(h, Param.du, Param.dv, Param.Normal);

    float nh = max(0, dot(Param.Normal, h));
    float spec = pow(nh, Param.Shininess*128.0) * Param.Gloss;

    float w = fwidth(spec);
    spec = lerp(0, 1, smoothstep(-w, w, spec - Param.Threshold));

    return spec;
}
//GGX高光形变
float StylizedSpecularLight_GGX(in StylizedSpecularParam Param, in float3 V, float3 L,float3 H,float Roughness,float Metallic)
{
    // float3 h = normalize(light + viewDir);  
    Op(H, Param.du, Param.dv, Param.Normal);
    // float nh = max(0, dot(Param.Normal, h));
    // float spec = pow(nh, Param.Shininess*128.0) * Param.Gloss;
    float spec = Specular_Direct_GGX(Param.Normal,L,V,H, Roughness, Metallic,Param.BaseColor);
    float w = fwidth(spec);
    spec = lerp(0, 1, smoothstep(-w, w, spec - Param.Threshold));
    return spec;
}

/** 各项异性高光 */
inline float pow5(float value)
{
    return value*value*value*value*value;
}

float D_Anisotropic(float at, float ab, float ToH, float BoH, float NoH)    
{
    // Burley 2012, "Physically-Based Shading at Disney"
    float a2 = at * ab;
    float3 d = float3(ab * ToH, at * BoH, a2 * NoH);
    return saturate(a2 * sqrt(a2 / dot(d, d)) * (1.0 / PI));
}


float V_Anisotropic(float at, float ab, float ToV, float BoV,float ToL, float BoL, float NoV, float NoL) 
{
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    // TODO: lambdaV can be pre-computed for all the lights, it should be moved out of this function
    float lambdaV = NoL * length(float3(at * ToV, ab * BoV, NoL));
    float lambdaL = NoV * length(float3(at * ToL, ab * BoL, NoV));
    float v = 0.5 / (lambdaV + lambdaL);
    return saturate(v);
}

float3 F_Schlick(  float3 f0, float f90, float VoH) 
{
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    float f = pow5(1.0 - VoH);
    return f + f0 * (f90 - f);
}

float3 F_Anisotropic( float3 f0, float LoH) 
{
    return F_Schlick(f0, 1.0, LoH);
}

struct PixelParams
{
    float3 anisotropicT;
    float3 anisotropicB;
    float linearRoughness;
    float anisotropy;
    float3 f0;
};

float3 BRDF_Anisotropic(in PixelParams pixel,float3 L, float3 V, float3 H,float NoV, float NoL, float NoH) 
{
    float3 t = pixel.anisotropicT;
    float3 b = pixel.anisotropicB;
    float3 v = V;

    float ToV = dot(t, v);
    float BoV = dot(b, v);
    float ToL = dot(t, L);
    float BoL = dot(b, L);
    float ToH = dot(t, H);
    float BoH = dot(b, H);
    float LoH = dot(L,H);

    // Anisotropic parameters: at and ab are the roughness along the tangent and bitangent
    // to simplify materials, we derive them from a single roughness parameter
    // Kulla 2017, "Revisiting Physically Based Shading at Imageworks"
    float at = max(pixel.linearRoughness * (1.0 + pixel.anisotropy), 0.001);
    float ab = max(pixel.linearRoughness * (1.0 - pixel.anisotropy), 0.001);

    // specular anisotropic BRDF
    float D = D_Anisotropic(at, ab, ToH, BoH, NoH);
    float V_ = V_Anisotropic(at, ab, ToV, BoV, ToL, BoL, NoV, NoL);
    float3  F = F_Anisotropic(pixel.f0, LoH);

    return D * V_ * F;
}
#endif