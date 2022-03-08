Shader "Unlit/TestWaterSSR"
{
    Properties
    {
        _SSRMaxSampleCount ("SSR Max Sample Count", Range(0, 64)) =64
        _SSRSampleStep ("SSR Sample Step", Range(4, 32)) = 4
        _SSRIntensity ("SSR Intensity", Range(0, 2)) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderPipeline" = "UniversalPipeline" "ShaderModel" = "4.5" }

        Pass
        {
            Name "TestWaterSSR"

            HLSLPROGRAM
            #pragma target 4.5

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            #include "WaterSSR.cginc"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 screenUV  :TEXCOORD4;
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.positionWS = TransformObjectToWorld(input.positionOS);
                float4 screenUV = ComputeScreenPos(output.positionCS);
                output.screenUV.xy =screenUV.xy / screenUV.w;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 positionWS = input.positionWS;

                // float4 screenUV = ComputeScreenPos( TransformWorldToHClip(positionWS));
                // screenUV.xy /= screenUV.w;
                
                float3 V = normalize( GetWorldSpaceViewDir(positionWS));
                float3 R = reflect(-V,float3(0,1,0));
                float4 ssr = GetWaterSSR(input.screenUV.xy, V.y, positionWS, R);
                ssr.rgb *= ssr.a;
                return ssr;
              
            }
            ENDHLSL

        }
    }
}
