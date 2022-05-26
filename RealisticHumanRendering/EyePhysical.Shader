Shader "Unlit/EyePhysical"
{
    Properties
    {        
        _ReflectionCube("Reflection Cube",Cube) = "Black"{}
        _ReflectionCubeRot(" Reflection Cube Rot",Range(0,3.14)) = 0
        _ReflectionVec("Reflection x:Pow y:Scale",Vector)=(1,1,0,0)
        _BaseMap ("Texture", 2D) = "white" {}
        _EyeOrigin("_EyeOrigin", Vector) = (0,0,0.45,0)
        _RefrectStartPos("_RefrectStartPos", Float) = 0.4

        _EyeUVScale("_EyeUVScale", Float) = 1
        _EtaScale("_EtaScale", Float) = 1
        
        
        _IrisMap ("Iris Map", 2D) = "white" {}
        _ScleraMap ("Sclera Map", 2D) = "white" {}
        
        
        _EyeBallScale("Eye Ball Scale",Float) = 1

    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x

            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D(_IrisMap);SAMPLER(sampler_IrisMap);
            TEXTURE2D(_ScleraMap);SAMPLER(sampler_ScleraMap);

            float _EyeBallScale;

            float4 _BaseColor;
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 normalWS : TEXCOORD1; // xyz: normal, w: viewDir.x
                float4 tangentWS : TEXCOORD2; // xyz: tangent, w: viewDir.y
                float4 bitangentWS : TEXCOORD3; // xyz: bitangent, w: viewDir.z
                float3 viewDirWS : TEXCOORD4;
                float4 positionCS : SV_POSITION;

                float3 positionOS:TEXCOORD5;
                float3 normalOS:TEXCOORD6;
                float3 positionWS:TEXCOORD7;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                float3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                float3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);

                output.positionCS = vertexInput.positionCS;
                output.uv = input.uv;
                output.normalWS = float4(normalInput.normalWS, viewDirWS.x);
                output.tangentWS = float4(normalInput.tangentWS, viewDirWS.y);
                output.bitangentWS = float4(normalInput.bitangentWS, viewDirWS.z);
                output.viewDirWS = viewDirWS;
                output.positionWS = TransformObjectToWorld(input.positionOS);

                output.positionOS.xyz = input.positionOS.xyz; 
                output.normalOS.xyz = input.normalOS.xyz; 

                return output;
            }

            float3 Erot(float3 p, float3 ax,float angle)
            {
                return lerp(dot(ax, p) * ax, p,cos(angle)) + cross(ax, p) * sin(angle);
            }

            //直线与平面相交
            //Ray and plane intsection
            bool IntersectPlane(float3 rayPos,float3 rayDir,float3 planePos,float3 planeNormal, inout float t0)
            {
                float3 p0 = planePos - rayPos;
                float dotDN= dot(rayDir,planeNormal);
                //平行
                if (abs(dotDN) <=0.001 )
                {
                    return false;
                }
                t0 = dot(p0,planeNormal) / dotDN;
                return t0 > 0;
            }

            //直线与球相交
            //Ray and sphere intsection
            bool IntersectSphere(float3 rayPos,float3 rayDir,float3 spherePos,float sphereRadius, inout float t0,inout float t1)
            {
                float3 L = spherePos - rayPos;
                float Tca = dot(L,rayDir);
                float d2 = dot(L,L) - Tca*Tca;
                float r2 =sphereRadius*sphereRadius;
                if(d2> r2)
                {
                    return false;
                }

                float Thc = sqrt(r2 - d2);
                t0 = Tca - Thc;
                t1 = Tca + Thc;

                return true;
            }

            float4 _EyeOrigin;
            float _EyeUVScale;
            TEXTURECUBE(_ReflectionCube);SAMPLER(sampler_ReflectionCube);
            float _ReflectionCubeRot;
            float4 _ReflectionVec;
            float _EtaScale;
            float _RefrectStartPos;

            float4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float3 N = normalize(input.normalWS.xyz);
                float3 T = normalize(input.tangentWS.xyz);
                float3 B = normalize(input.bitangentWS.xyz);
                float3 V = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);
                float3 L = normalize(_MainLightPosition.xyz);
                float3 H = normalize(V + L);

                float NV = dot(N, V);
                float NL = dot(N, L);
                float NH = dot(N, H);

                float2 uv = input.uv;
                float3 R = reflect(-V, N);
                R = Erot(R, float3(0,1,0),_ReflectionCubeRot);
                float3 EyeReflection = SAMPLE_TEXTURECUBE(_ReflectionCube,sampler_ReflectionCube,R)*_ReflectionVec.y;
                
                float3 rayPos = input.positionOS.xyz;
                float3 rayDir = normalize(TransformWorldToObjectDir(-V));
                // float3 normal = normalize(input.positionOS.xyz - _EyeOrigin.xyz);
                float3 normal = normalize(input.normalOS.xyz);
                //i n ite
                float N_Air = 1.000293;
                float N_Eye = 1.437;
                float eta = N_Air/N_Eye *_EtaScale;
                float3 rayDirRefracted = refract(rayDir,normal,eta);
                float3 planePos =_EyeOrigin.xyz;
                float3 planeNormal = float3(0,0,1);

                float2 uv_Refrected = input.positionOS.xy+0.5;

                // uv = uv_Refrected;
                // uv = uv +  normalize(uv - float2(0.5,0.5)) * _EyeUVScale;
                // return SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
                // float isRefrectPart = rayPos.z>_EyeOrigin.z;
                float isRefrectPart = rayPos.z>_RefrectStartPos;
                if(isRefrectPart)
                {
                    /*
                    float t0;
                    if(IntersectPlane(rayPos,rayDirRefracted,planePos,planeNormal,t0))
                    {
                        float3 hitPos = rayPos + rayDir*t0;
                        uv_Refrected = frac(hitPos.xy)+0.5;
                    }
                    */
                    
                    float sphereT0,sphereT1;
                    float3 spherePos = _EyeOrigin.xyz;
                    if(IntersectSphere(rayPos,rayDirRefracted,spherePos,_EyeOrigin.w,sphereT0,sphereT1))
                    {
                        float3 hitPos = rayPos + rayDir*sphereT1;
                        uv_Refrected = frac(hitPos.xy)+0.5;
                    }
                    
                }

                uv = uv_Refrected;
                // return float4(uv,0,0);
                uv =uv +  normalize(uv - float2(0.5,0.5)) * _EyeUVScale;

                float4 IsrisMap = SAMPLE_TEXTURE2D(_IrisMap, sampler_IrisMap, uv);
                float4 ScleraMap = SAMPLE_TEXTURE2D(_ScleraMap, sampler_ScleraMap, uv);

                float4 finalColor = lerp(ScleraMap,IsrisMap,isRefrectPart);

                return finalColor + EyeReflection.xyzz * isRefrectPart;
                

                return NL;
            }
            ENDHLSL
        }
        
        
        //DepthOnly
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

    }
}
