#ifndef WATER_SSR
#define WATER_SSR

// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

TEXTURE2D(_CameraDepthTexture);SAMPLER(sampler_CameraDepthTexture);
TEXTURE2D(_CameraOpaqueTexture);SAMPLER(sampler_CameraOpaqueTexture);

float _SSRMaxSampleCount;
float _SSRSampleStep;
float _SSRIntensity;

float UVJitter(in float2 uv)
{
    return frac((52.9829189 * frac(dot(uv, float2(0.06711056, 0.00583715)))));
}

void SSRRayConvert(float3 worldPos, out float4 clipPos, out float3 screenPos)
{
    clipPos = TransformWorldToHClip(worldPos);
    float k = ((1.0) / (clipPos.w));
    screenPos.xy = ComputeScreenPos(clipPos).xy * k;
    screenPos.z = k;
}

float3 SSRRayMarch(float2 ScreenUV, float3 worldPos, float3 R)
{
    float4 startClipPos;
    float3 startScreenPos;

    SSRRayConvert(worldPos, startClipPos, startScreenPos);

    float4 endClipPos;
    float3 endScreenPos;

    SSRRayConvert(worldPos + R, endClipPos, endScreenPos);

    if (((endClipPos.w) < (startClipPos.w)))
    {
        return float3(0, 0, 0);
    }

    float3 screenDir = endScreenPos - startScreenPos;

    float screenDirX = abs(screenDir.x);
    float screenDirY = abs(screenDir.y);

    float dirMultiplier = lerp(1 / (_ScreenParams.y * screenDirY), 1 / (_ScreenParams.x * screenDirX),screenDirX > screenDirY) * _SSRSampleStep;

    screenDir *= dirMultiplier;

    float lastRayDepth = startClipPos.w;

    float sampleCount = 1 + UVJitter(ScreenUV) * 0.1;

    float3 lastScreenMarchUVZ = startScreenPos;
    float lastDeltaDepth = 0;

    UNITY_LOOP
    for (int i = 0; i < _SSRMaxSampleCount; i++)
    {
        float3 screenMarchUVZ = startScreenPos + screenDir * sampleCount;

        if ((screenMarchUVZ.x <= 0) || (screenMarchUVZ.x >= 1) || (screenMarchUVZ.y <= 0) || (screenMarchUVZ.y >= 1))
        {
            break;
        }

        float sceneDepth = LinearEyeDepth(
            SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenMarchUVZ.xy),
            _ZBufferParams);
        float rayDepth = 1.0 / screenMarchUVZ.z;
        float deltaDepth = rayDepth - sceneDepth;

        if ((deltaDepth > 0) && (sceneDepth > startClipPos.w) && (deltaDepth < (abs(rayDepth - lastRayDepth)* 2)))
        {
            float samplePercent = saturate(lastDeltaDepth / (lastDeltaDepth - deltaDepth));
            samplePercent = lerp(samplePercent, 1, rayDepth >= _ProjectionParams.z);
            float3 hitScreenUVZ = lerp(lastScreenMarchUVZ, screenMarchUVZ, samplePercent);
            return float3(hitScreenUVZ.xy, 1);
        }

        lastRayDepth = rayDepth;
        sampleCount += 1;

        lastScreenMarchUVZ = screenMarchUVZ;
        lastDeltaDepth = deltaDepth;
    }

    float4 farClipPos;
    float3 farScreenPos;

    SSRRayConvert(worldPos + R * 100000, farClipPos, farScreenPos);

    if ((farScreenPos.x > 0) && (farScreenPos.x < 1) && (farScreenPos.y > 0) && (farScreenPos.y < 1))
    {
        float farDepth = LinearEyeDepth(
            SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, farScreenPos.xy),
            _ZBufferParams);

        if (farDepth > startClipPos.w)
        {
            return float3(farScreenPos.xy, 1);
        }
    }

    return float3(0, 0, 0);
}

float3 GetSSRUVZ(float2 screenUV, float NV, float3 worldPos, float3 R)
{
    screenUV = screenUV * 2 - 1;
    screenUV *= screenUV;

    float ssrWeight = saturate(1 - dot(screenUV, screenUV));
    float NoV = NV * 2.5;
    ssrWeight *= (1 - NoV * NoV);

    if (ssrWeight > 0.005)
    {
        float3 uvz = SSRRayMarch(screenUV, worldPos, R);
        uvz.z *= ssrWeight;
        return uvz;
    }

    return float3(0, 0, 0);
}

//screenPos = ComputeScreenPos(positionCS);
//screenUV = screenPos.xy/screenPos.w;
float4 GetWaterSSR(float2 screenUV, float NV, float3 worldPos, float3 R)
{
    float3 uvz = GetSSRUVZ(screenUV, NV, worldPos, R);
    float3 ssrColor = lerp(float3(0, 0, 0),
                          SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, uvz.xy) *
                          _SSRIntensity, uvz.z > 0);
    return float4(ssrColor, uvz.z);
}

#endif
