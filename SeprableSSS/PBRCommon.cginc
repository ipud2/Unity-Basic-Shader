#include "UnityCG.cginc"
#define MINNUM 0.000001

float _GGX;

inline float pow2(float res)
{
    return res * res;
}

inline float pow5(float res)
{
    return pow2(res) * pow2(res) * res;
}

//Specular D, based on GGX（Trowbridge-Reitz）, normal distribution function, α = roughtness^2
float GGX(float NdotH, float r_2)
{
    float alpha_2 = pow2(r_2);
    float res = (alpha_2 * _GGX) / (UNITY_PI * pow2(pow2(NdotH) * (alpha_2 - 1) + 1) + MINNUM); //加个非常小的数以防是0
    return res;
}

//Anisotropic Specular D
float AnisotropicGGX(float RoughnessX, float RoughnessY, float NdotH, float3 H, float3 X, float3 Y)
{
    float ax = pow2(RoughnessX);
    float ay = pow2(RoughnessY);
    float XdotH = dot(X, H);
    float YdotH = dot(Y, H);
    float d = pow2(XdotH) / pow2(ax) + pow2(YdotH) / pow2(ay) + pow2(NdotH);
    return 1 / (RoughnessX * RoughnessY * pow2(d) + MINNUM);
}

//Specular G，Geometry Term
float SmithJoint(float NdotL, float NdotV, float r)
{
    float k = pow2(r + 1) / 8;
    float g1 = NdotV / (NdotV * (1 - k) + k);
    float g2 = NdotL * (NdotL * (1 - k) + k);
    return g1 * g2;
}

float AnisotropicSmithJoint(float3 X, float3 Y, float3 V, float3 L, float3 N, float RoughnessX, float RoughnessY)
{
    float ax = pow2(RoughnessX);
    float ay = pow2(RoughnessY);

    float NdotL = dot(N, L);
    float NdotV = dot(N, V);
    float XdotV = dot(X, V);
    float YdotV = dot(Y, V);
    float XdotL = dot(X, L);
    float YdotL = dot(Y, L);

    float g1 = NdotL * sqrt(ax * pow2(XdotV) + ay * pow2(YdotV) + pow2(NdotV));
    float g2 = NdotV * sqrt(ax * pow2(YdotL) + ay * pow2(YdotL) + pow2(NdotL));

    return 0.5 / (g1 + g2);
}

//Specular F, Fresnel Term
float4 FresnelSchlick(float4 F0, float VdotH)
{
    return F0 + (1 - F0) * exp2(-5.55473 * VdotH - 6.98316 * VdotH);
}

float4 FresnelLerp(float4 F0, float4 F90, float cosA)
{
    float t = pow5(1 - cosA);
    return lerp(F0, F90, t);
}

void ConvertAnisotropyToRoughness(float roughness, float anisotropy, out float roughnessX, out float roughnessY)
{
    // (0 <= anisotropy <= 1), therefore (0 <= anisoAspect <= 1)
    // The 0.9 factor limits the aspect ratio to 10:1.
    float anisoAspect = sqrt(1.0 - 0.9 * anisotropy);
    roughnessX = roughness / anisoAspect; // Distort along tangent (rougher)
    roughnessY = roughness * anisoAspect; // Straighten along bitangent (smoother)
}

float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
    return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}

float4 CookTorranceBRDF(float NdotH, float NdotL, float NdotV, float VdotH, float roughness, float4 specularColor)
{
    float D = GGX(NdotH, pow2(roughness));
    float G = SmithJoint(NdotL, NdotV, roughness);
    float4 F = FresnelSchlick(specularColor, VdotH);
    float4 res = (D * G * F) / (4 * NdotL * NdotV + MINNUM);
    return res;
}

float4 AnisotropyCookTorranceBRDF(float RoughnessX, float RoughnessY, float3 X, float3 Y, float3 H, float3 N, float3 L,
                                  float3 V, float4 specularColor)
{
    float NdotL = dot(N, L);
    float NdotV = dot(N, V);
    float NdotH = dot(N, H);
    float VdotH = dot(V, H);
    float D = AnisotropicGGX(RoughnessX, RoughnessY, NdotH, H, X, Y);
    float G = AnisotropicSmithJoint(X, Y, V, L, N, RoughnessX, RoughnessY);
    float4 F = FresnelSchlick(specularColor, VdotH);
    float4 res = (D * G * F) / (4 * NdotL * NdotV + MINNUM);
    return res;
}
