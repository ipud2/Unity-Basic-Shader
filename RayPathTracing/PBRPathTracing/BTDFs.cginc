#ifndef BTDF_INCLUDE
#define BTDF_INCLUDE

float3 RefractionBTDF(float D, float G, float3 F, float3 V, float3 L, float3 N, float3 H, float etaIn, float etaOut)
{ //Not reciprocal! be careful about direction!
    
    float NdotL = abs(dot(N, L));
    float NdotV = abs(dot(N, V));
            
    float VdotH = abs(dot(V, H));
    float LdotH = abs(dot(L, H));
            
    
    float term1 = VdotH * LdotH / (NdotV * NdotL);
    float3 term2 = etaOut * etaOut * (1 - F) * G * D;
            //term1 = 1;
            //term2 = 1;
    float term3 = (etaIn * VdotH + etaOut * LdotH) * (etaIn * VdotH + etaOut * LdotH) + 0.001f;
            //term3 = 1;
    float3 refractionBrdf = term1 * term2 / term3;
    
    return refractionBrdf;
}


#endif