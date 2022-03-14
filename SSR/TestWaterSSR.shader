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
                float4 screenUV  :TEXCOORD4;
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.positionWS = TransformObjectToWorld(input.positionOS);
                output.screenUV =ComputeScreenPos(output.positionCS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 positionWS = input.positionWS;
                
                float3 V = normalize( GetWorldSpaceViewDir(positionWS));
                float3 R = reflect(-V,float3(0,1,0));
                float2 screenUV = input.screenUV.xy / input.screenUV.w;//直接在VS中做了除法，效果会出错
                float4 ssr = GetWaterSSR(screenUV,input.positionCS, positionWS,R,V.y );
                ssr.rgb *= ssr.a;

                
                
                return ssr;
              
            }
            ENDHLSL

        }
