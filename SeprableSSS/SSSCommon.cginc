#include "UnityCG.cginc"

#define DistanceToProjectionWindow 5.671281819617709   // 1.0 / tan(0.5 * radians(20))
#define DPTimes300 1701.384545885313                     //DistanceToProjectionWindow * 300

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
};

sampler2D _CameraDepthTexture;
float4 _CameraDepthTexture_TexelSize;
sampler2D _SourceTex;
float4 _SourceTex_ST;
float _SSSScaler;
float4 _Kernel[100];
int _Samples;

v2f vert(appdata v)
{
    v2f o;
    o.vertex = v.vertex;
    o.uv = TRANSFORM_TEX(v.uv, _SourceTex);
    return o;
}

float4 SSS(float4 sceneColor, float2 uv, float2 sssIntensity)
{
    float sceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
    float blurLength = DistanceToProjectionWindow / sceneDepth;
    float2 uvOffset = sssIntensity * blurLength;
    float4 blurSceneColor = sceneColor;
    blurSceneColor.rgb *= _Kernel[0].rgb;

    [loop]
    for (int i = 1; i < _Samples; i++)
    {
        float2 sssUV = uv + _Kernel[i].a * uvOffset;
        float4 sssSceneColor = tex2D(_SourceTex, sssUV);
        float sssDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sssUV)).r;
        float sssScale = saturate(DPTimes300 * sssIntensity * abs(sceneDepth - sssDepth));
        sssSceneColor.rgb = lerp(sssSceneColor.rgb, sceneColor.rgb, sssScale);
        blurSceneColor.rgb += _Kernel[i].rgb * sssSceneColor.rgb;
    }
    return blurSceneColor;
}


#define SSSS_QUALITY 2

#if SSSS_QUALITY == 2
#define SSSS_N_SAMPLES 25
float4 kernel[] = {
    float4(0.530605, 0.613514, 0.739601, 0),
    float4(0.000973794, 1.11862e-005, 9.43437e-007, -3),
    float4(0.00333804, 7.85443e-005, 1.2945e-005, -2.52083),
    float4(0.00500364, 0.00020094, 5.28848e-005, -2.08333),
    float4(0.00700976, 0.00049366, 0.000151938, -1.6875),
    float4(0.0094389, 0.00139119, 0.000416598, -1.33333),
    float4(0.0128496, 0.00356329, 0.00132016, -1.02083),
    float4(0.017924, 0.00711691, 0.00347194, -0.75),
    float4(0.0263642, 0.0119715, 0.00684598, -0.520833),
    float4(0.0410172, 0.0199899, 0.0118481, -0.333333),
    float4(0.0493588, 0.0367726, 0.0219485, -0.1875),
    float4(0.0402784, 0.0657244, 0.04631, -0.0833333),
    float4(0.0211412, 0.0459286, 0.0378196, -0.0208333),
    float4(0.0211412, 0.0459286, 0.0378196, 0.0208333),
    float4(0.0402784, 0.0657244, 0.04631, 0.0833333),
    float4(0.0493588, 0.0367726, 0.0219485, 0.1875),
    float4(0.0410172, 0.0199899, 0.0118481, 0.333333),
    float4(0.0263642, 0.0119715, 0.00684598, 0.520833),
    float4(0.017924, 0.00711691, 0.00347194, 0.75),
    float4(0.0128496, 0.00356329, 0.00132016, 1.02083),
    float4(0.0094389, 0.00139119, 0.000416598, 1.33333),
    float4(0.00700976, 0.00049366, 0.000151938, 1.6875),
    float4(0.00500364, 0.00020094, 5.28848e-005, 2.08333),
    float4(0.00333804, 7.85443e-005, 1.2945e-005, 2.52083),
    float4(0.000973794, 1.11862e-005, 9.43437e-007, 3),
};
#elif SSSS_QUALITY == 1
#define SSSS_N_SAMPLES 17
float4 kernel[] = {
    float4(0.536343, 0.624624, 0.748867, 0),
    float4(0.00317394, 0.000134823, 3.77269e-005, -2),
    float4(0.0100386, 0.000914679, 0.000275702, -1.53125),
    float4(0.0144609, 0.00317269, 0.00106399, -1.125),
    float4(0.0216301, 0.00794618, 0.00376991, -0.78125),
    float4(0.0347317, 0.0151085, 0.00871983, -0.5),
    float4(0.0571056, 0.0287432, 0.0172844, -0.28125),
    float4(0.0582416, 0.0659959, 0.0411329, -0.125),
    float4(0.0324462, 0.0656718, 0.0532821, -0.03125),
    float4(0.0324462, 0.0656718, 0.0532821, 0.03125),
    float4(0.0582416, 0.0659959, 0.0411329, 0.125),
    float4(0.0571056, 0.0287432, 0.0172844, 0.28125),
    float4(0.0347317, 0.0151085, 0.00871983, 0.5),
    float4(0.0216301, 0.00794618, 0.00376991, 0.78125),
    float4(0.0144609, 0.00317269, 0.00106399, 1.125),
    float4(0.0100386, 0.000914679, 0.000275702, 1.53125),
    float4(0.00317394, 0.000134823, 3.77269e-005, 2),
};
#elif SSSS_QUALITY == 0
#define SSSS_N_SAMPLES 11
float4 kernel[] = {
    float4(0.560479, 0.669086, 0.784728, 0),
    float4(0.00471691, 0.000184771, 5.07566e-005, -2),
    float4(0.0192831, 0.00282018, 0.00084214, -1.28),
    float4(0.03639, 0.0130999, 0.00643685, -0.72),
    float4(0.0821904, 0.0358608, 0.0209261, -0.32),
    float4(0.0771802, 0.113491, 0.0793803, -0.08),
    float4(0.0771802, 0.113491, 0.0793803, 0.08),
    float4(0.0821904, 0.0358608, 0.0209261, 0.32),
    float4(0.03639, 0.0130999, 0.00643685, 0.72),
    float4(0.0192831, 0.00282018, 0.00084214, 1.28),
    float4(0.00471691, 0.000184771, 5.07565e-005, 2),
};
#else
#endif


float4 SkinSSS(float4 sceneColor, float2 uv, float2 sssIntensity)
{
    float sceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
    float blurLength = DistanceToProjectionWindow / sceneDepth;
    float2 uvOffset = sssIntensity * blurLength;
    float4 blurSceneColor = sceneColor;
    blurSceneColor.rgb *= kernel[0].rgb;

    [loop]
    for (int i = 1; i < SSSS_N_SAMPLES; i++)
    {
        float2 sssUV = uv + kernel[i].a * uvOffset;
        float4 sssSceneColor = tex2D(_SourceTex, sssUV);
        float sssDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sssUV)).r;
        float sssScale = saturate(DPTimes300 * sssIntensity * abs(sceneDepth - sssDepth));
        sssSceneColor.rgb = lerp(sssSceneColor.rgb, sceneColor.rgb, sssScale);
        blurSceneColor.rgb += kernel[i].rgb * sssSceneColor.rgb;
    }
    return blurSceneColor;
}
