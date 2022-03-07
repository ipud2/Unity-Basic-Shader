Shader "Unlit/WaterSSR"
{
    Properties
    {
        _SSRMaxDistance("SSR Max Distance",Float) = 20
    }
    SubShader
    {
        Tags {  "Queue"="Transparent" "RenderPipeline" = "UniversalPipeline" "ShaderModel"="4.5" }

        Pass
        {
            Name "Unlit"

            HLSLPROGRAM

            #pragma target 4.5

            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                // float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 screenPos  : TEXCOORD1;  
            };

            TEXTURE2D(_CameraOpaqueTexture);
			SAMPLER(sampler_CameraOpaqueTexture);

			// TEXTURE2D(_CameraDepthTexture);
			// SAMPLER(sampler_CameraDepthTexture);

            float _SSRMaxDistance;

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
                // output.positionVS = TransformWorldToView(input.positionWS);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);

                output.screenPos = ComputeScreenPos( output.positionCS);

                return output;
            }

            float3 GetWorldPosition(float2 screenUV)
            {
                 // Sample the depth from the Camera depth texture.
                float depth = SampleSceneDepth(screenUV);
                // Reconstruct the world space positions.
                float3 worldPos = ComputeWorldSpacePosition(screenUV, depth, UNITY_MATRIX_I_VP);
                return worldPos;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // float3 col = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture,input.screenPos.xy/input.screenPos.w + sin(_Time.y)*0.1) ;
                // return float4(col,1);

                float3 V = normalize(_WorldSpaceCameraPos.xyz - input.positionWS);
                float3 R = normalize(reflect(-V,float3(0,1,0)));
                float3 rayDir =R;
                float4 rayStart = input.screenPos;
                float4 rayEnd = ComputeScreenPos(TransformWorldToHClip(input.positionWS+rayDir*_SSRMaxDistance));
                float _SSRMarchCount = 16;
                float marchStep = rcp(_SSRMarchCount);
                float threshold = _SSRMaxDistance*marchStep * 1;

                float4 ray = rayEnd - rayStart;
                float4 rayStep = ray*marchStep;
                int rayHitIndex = 0;
                UNITY_LOOP
                for(int n=1;n<=_SSRMarchCount;n++)
                {
                    float4 rayPos =rayStep*n + rayStart;
                    float2 screenUV =  rayPos.xy/rayPos.w;
                    float depth = (SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture,screenUV));
                    float3 worldPos = ComputeWorldSpacePosition(screenUV, depth, UNITY_MATRIX_I_VP);
                    float3 rayWorldPos = input.positionWS+rayDir*n;
                    // rayDepth = LinearEyeDepth(rayDepth,_ZBufferParams);
                    if(length(rayWorldPos- worldPos)<threshold)
                    {
                        return SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture,  rayPos.xy/rayPos.w);
                        // rayHitIndex = n;
                        // break;
                    }
                }

                return float4(0,0,0,1);
                // float4 rayPos =rayStep*rayHitIndex + rayStart;
                // float2 rayPosScreen = rayPos.xy/rayPos.z;
                // float4 reflection = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, rayPosScreen);


                // return half4(0.8, 0.1, 0.2, 1);
            }
            ENDHLSL

        }
    }
}
