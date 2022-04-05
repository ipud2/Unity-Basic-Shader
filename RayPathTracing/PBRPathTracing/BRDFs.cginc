#ifndef BRDF_INCLUDE
#define BRDF_INCLUDE
#include "Common.cginc"

float3 SpecularBRDF(float D, float G, float3 F, float3 V, float3 L, float3 N)
{        
    float NdotL = abs(dot(N, L));
    float NdotV = abs(dot(N, V));
            
    //specualr
    //Microfacet specular = D * G * F / (4 * NoL * NoV)
    float3 nominator = D * G * F;
    float denominator = 4.0 * NdotV * NdotL + 0.001;
    float3 specularBrdf = nominator / denominator;
    
    return specularBrdf;
}

float3 DiffuseBRDF(float3 albedo)
{
    return albedo / PI;
}



#endif