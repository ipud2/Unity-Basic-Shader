Shader "BadDog/URP/BGWater"
{
    Properties
    {
        [Header(Three Direction Wave)]
        _MainWave ("Main Wave", 2D) = "white" { }
        _MainWaveBumpScale ("Main Wave Bump Scale", Range(0, 2)) = 1
        _SecondWave ("Second Wave", 2D) = "white" { }
        _SecondWaveBumpScale ("Second Normal Bump Scale", Range(0, 2)) = 1
        _MainWaveTilingOffset ("Main Wave Tiling Offset", Vector) = (1, 1, 1, 1)
        _SecondWaveTilingOffset ("Second Wave Tiling Offset", Vector) = (1, 1, -1, 1)
        _ThirdWaveTilingOffset ("Third Wave Tiling Offset", Vector) = (1, 1, 1, -1)

        [Header(Water)]
        _WaterBaseColor ("Water Base Color", Color) = (1.0, 1.0, 1.0, 1)

        [Header(Muddy)]
        _WaterMuddyColor ("Water Muddy Color", Color) = (1.0, 1.0, 1.0, 1)
        _WaterMuddyScale ("Water Muddy Scale", Range(0, 2)) = 1
        _WaterDepthOffset ("Water Depth Offset", Range(0, 1)) = 1

        [Header(Specular)]
        _SpecularIntensity ("Specular Intensity", Range(0, 8)) = 1

        [Header(Refraction)]
        _WaterDistortScale ("Distort Scale", Range(0, 10)) = 1

        [Header(Enviroment Reflection)]
        _EnviromentIntensity ("Enviroment Intensity", Range(0, 10)) = 1

        [Header(Screen Space Reflection)]
        [Toggle] _BGWATER_SSR ("Screen Space Reflection", Float) = 1.0
        _SSRMaxSampleCount ("SSR Max Sample Count", Range(0, 64)) = 12
        _SSRSampleStep ("SSR Sample Step", Range(4, 32)) = 16
        _SSRIntensity ("SSR Intensity", Range(0, 2)) = 0.5

        [Toggle] _BGWATER_ORTHO ("Orthographic Camera", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "IgnoreProjector" = "True" "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Back

            HLSLPROGRAM
            #if !defined(UNITY_PASS_FORWARDBASE)
            #define UNITY_PASS_FORWARDBASE
            #endif

            #pragma vertex VertexForward
            #pragma fragment FragForward

            #pragma target 3.0

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma multi_compile _ _BGWATER_SSR_ON
            #pragma multi_compile _ _BGWATER_ORTHO_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

            #ifndef BADDOG_WATER_BASE
            #define BADDOG_WATER_BASE

            sampler2D _MainWave;
            float4 _MainWave_ST;

            sampler2D _SecondWave;
            float4 _SecondWave_ST;

            half _MainWaveBumpScale;
            half _SecondWaveBumpScale;

            half4 _MainWaveTilingOffset;
            half4 _SecondWaveTilingOffset;
            half4 _ThirdWaveTilingOffset;

            half _WaterDepthOffset;
            half _WaterMuddyScale;
            half _WaterDistortScale;

            half4 _WaterBaseColor;
            half4 _WaterMuddyColor;

            half _SpecularIntensity;
            half _EnviromentIntensity;



            #include "./BGWaterOrtho.hlsl"

            #ifndef BADDOG_WATER_STRUCT
            #define BADDOG_WATER_STRUCT

            struct BGWaterVertexInput
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct BGWaterVertexOutput
            {
                float4 pos : SV_POSITION;

                float3 mainWaveUV : TEXCOORD0;
                float4 secondWaveUV : TEXCOORD1;

                float4 worldNormalDir : TEXCOORD2;
                float4 worldTangentDir : TEXCOORD3;
                float4 worldBitangentDir : TEXCOORD4;

                float4 screenPos : TEXCOORD5;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            struct BGLightingData
            {
                float3 worldPos;
                float3 worldNormal;
                float3 worldLightDir;
                float3 worldViewDir;

                half NoL;
                half NoV;
                half NoH;
                half LoH;

                half3 R;

                half3 diffuseColor;
                half3 specularColor;
                half3 lightColor;

                float2 screenUV;
            };

            #endif


            #include "WaterSSR.cginc"
            
            #ifndef BADDOG_WATER_LIGHTING
            #define BADDOG_WATER_LIGHTING

            float3 WaveNormal(BGWaterVertexOutput vertexOutput)
            {
                half3 waterNormal1 = tex2D(_MainWave, vertexOutput.mainWaveUV.xy).xyz;
                half3 waterNormal2 = tex2D(_MainWave, vertexOutput.secondWaveUV.xy).xyz;
                half3 waterNormal3 = tex2D(_SecondWave, vertexOutput.secondWaveUV.zw).xyz;

                half3 waterNormal = ((waterNormal1 + waterNormal2) * 0.6667 - 0.6667) * half3(
                    _SecondWaveBumpScale, _SecondWaveBumpScale, 1);

                waterNormal3 = waterNormal3 * 2 - 1;
                waterNormal += (waterNormal3 * half3(_MainWaveBumpScale, _MainWaveBumpScale, 1));

                return normalize(TransformTangentToWorld(waterNormal,
                                                         float3x3(vertexOutput.worldTangentDir.xyz,
                                                                  vertexOutput.worldBitangentDir.xyz,
                                                                  vertexOutput.worldNormalDir.xyz)));
            }

            BGLightingData PrepareLighting(BGWaterVertexOutput vertexOutput)
            {
                BGLightingData lightingData = (BGLightingData)0;

                lightingData.worldPos = float3(vertexOutput.worldNormalDir.w, vertexOutput.worldTangentDir.w,
                                               vertexOutput.worldBitangentDir.w);
                lightingData.worldNormal = WaveNormal(vertexOutput);
                lightingData.worldNormal = half3(0, 1, 0);
                lightingData.worldLightDir = normalize(_MainLightPosition.xyz);

                lightingData.worldViewDir = normalize(_WorldSpaceCameraPos.xyz - lightingData.worldPos);

                half3 H = normalize(lightingData.worldLightDir + lightingData.worldViewDir);

                lightingData.NoL = saturate(dot(lightingData.worldLightDir, lightingData.worldNormal));
                lightingData.NoV = saturate(dot(lightingData.worldNormal, lightingData.worldViewDir));
                lightingData.NoH = saturate(dot(lightingData.worldNormal, H));
                lightingData.LoH = saturate(dot(lightingData.worldLightDir, H));
                lightingData.R = normalize(reflect(-lightingData.worldViewDir, lightingData.worldNormal));

                lightingData.diffuseColor = _WaterBaseColor;
                lightingData.specularColor = half3(0.04, 0.04, 0.04);
                lightingData.lightColor = _MainLightColor.rgb;

                lightingData.screenUV = vertexOutput.screenPos.xy / vertexOutput.screenPos.w;

                #if defined(UNITY_SINGLE_PASS_STEREO)
							lightingData.screenUV.xy = UnityStereoTransformScreenSpaceTex(lightingData.screenUV.xy);
                #endif

                return lightingData;
            }

            half3 IndirectDiffuse(BGLightingData lightingData)
            {
                return SampleSH(lightingData.worldNormal);
            }

            half3 Diffuse(BGLightingData lightingData)
            {
                return lightingData.lightColor * lightingData.NoL;
            }

            half3 Specular(BGLightingData lightingData)
            {
                float D = (-0.004) / (lightingData.NoH * lightingData.NoH - 1.005);
                D *= D;

                half x = 1 - lightingData.LoH;
                half x2 = x * x;
                half x5 = x2 * x2 * x;

                float F = lightingData.specularColor + (1 - lightingData.specularColor) * x5;

                return lightingData.lightColor * D * F * PI * _SpecularIntensity;
            }

            half3 IndirectSpecular(BGLightingData lightingData)
            {
                half3 probe = GlossyEnvironmentReflection(lightingData.R, 0, 1);

                half fresnelTerm = 1.0 - saturate(dot(lightingData.worldNormal, lightingData.worldViewDir));
                fresnelTerm *= fresnelTerm;
                fresnelTerm *= fresnelTerm;

                return probe.rgb * lerp(lightingData.specularColor, 1, fresnelTerm);
            }

            half3 GetReflectionWithSSR(BGWaterVertexOutput vertexOutput, BGLightingData lightingData)
            {
                half3 indirectDiffuse = IndirectDiffuse(lightingData);
                half3 diffuse = Diffuse(lightingData);
                half3 specular = Specular(lightingData);
                half3 indirectSpecular = IndirectSpecular(lightingData);

                #if defined(_BGWATER_SSR_ON)
							half4 ssrLighting = GetWaterSSR(lightingData.screenUV,lightingData.NoV,lightingData.worldPos,lightingData.R);
							indirectSpecular = lerp(lerp(indirectSpecular, ssrLighting.rgb, ssrLighting.a), ssrLighting, ssrLighting.a > 0.99);
                #endif

                indirectSpecular *= _EnviromentIntensity;

                return (indirectDiffuse + diffuse) * lightingData.diffuseColor + specular + indirectSpecular;
            }

            half4 GetRefraction(BGWaterVertexOutput vertexOutput, BGLightingData lightingData)
            {
                float2 screenUV = lightingData.screenUV;
                float2 grabUV = screenUV;

                half3 worldViewDir = normalize(lightingData.worldViewDir);
                half worldViewDirY = abs(worldViewDir.y);

                #if defined(_BGWATER_ORTHO_ON)
							float depth = GetOrthoEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV));
                #else
                float depth = LinearEyeDepth(
                    SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV), _ZBufferParams);
                #endif
                depth = depth - vertexOutput.screenPos.z;

                half2 deltaUV = lightingData.worldNormal.xz * _WaterDistortScale * saturate(depth) * worldViewDirY /
                    vertexOutput.screenPos.z;

                #if defined(_BGWATER_ORTHO_ON)
							float newDepth = GetOrthoEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV + deltaUV));
                #else
                float newDepth = LinearEyeDepth(
                    SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV + deltaUV),
                    _ZBufferParams);
                #endif
                newDepth = newDepth - vertexOutput.screenPos.z;

                half signDepth = saturate(newDepth * 10);
                grabUV = grabUV + deltaUV * signDepth;

                depth = lerp(depth, newDepth, signDepth);

                half viewMultiplier = (worldViewDirY + _WaterMuddyScale) * _WaterDepthOffset * _WaterDepthOffset;
                depth *= viewMultiplier;

                half alpha = saturate(1 - depth);
                alpha = saturate(1.02 - pow(alpha, (dot(lightingData.worldNormal.xyz, worldViewDir) * 5 + 6)));

                half4 refraction = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, grabUV);
                refraction.rgb = lerp(refraction.rgb, refraction.rgb * _WaterMuddyColor * _WaterMuddyScale, alpha);
                refraction.a = alpha;

                return refraction;
            }

            #endif


            BGWaterVertexOutput VertexCommon(BGWaterVertexInput v)
            {
                BGWaterVertexOutput o = (BGWaterVertexOutput)0;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = TransformObjectToHClip(v.vertex);

                o.mainWaveUV.xy = v.texcoord * _MainWaveTilingOffset.xy + _Time.r * _MainWaveTilingOffset.zw * 0.1;
                o.secondWaveUV.xy = v.texcoord * _SecondWaveTilingOffset.xy + _Time.r * _SecondWaveTilingOffset.zw *
                    0.1;
                o.secondWaveUV.zw = v.texcoord * _ThirdWaveTilingOffset.xy + _Time.r * _ThirdWaveTilingOffset.zw * 0.1;

                float3 worldPos = TransformObjectToWorld(v.vertex);

                VertexNormalInputs normalInput = GetVertexNormalInputs(v.normal, v.tangent);

                o.worldNormalDir = float4(normalInput.normalWS, worldPos.x);
                o.worldTangentDir = float4(normalInput.tangentWS, worldPos.y);
                o.worldBitangentDir = float4(normalInput.bitangentWS, worldPos.z);

                o.mainWaveUV.z = ComputeFogFactor(o.pos.z);

                o.screenPos = ComputeScreenPos(o.pos);
                o.screenPos.z = -TransformWorldToView(worldPos).z;

                return o;
            }

            BGWaterVertexOutput VertexForward(BGWaterVertexInput vertexInput)
            {
                BGWaterVertexOutput vertexOutput = VertexCommon(vertexInput);
                return vertexOutput;
            }

            half4 FragForward(BGWaterVertexOutput vertexOutput) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(vertexOutput);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(vertexOutput);

                BGLightingData lightingData = PrepareLighting(vertexOutput);

                // return vertexOutput.screenPos;

                // reflection + fog
                // half3 reflection = GetReflectionWithSSR(vertexOutput, lightingData);
                // reflection = MixFog(reflection, vertexOutput.mainWaveUV.z);

                #if defined(_BGWATER_SSR_ON)
						lightingData.worldNormal.xyz = half3(0, 1, 0);
						half4 ssrLighting = GetWaterSSR(lightingData.screenUV,lightingData.NoV,lightingData.worldPos,lightingData.R);
						ssrLighting.rgb *= ssrLighting.a;
						return half4(ssrLighting.rgb, 1);
                #endif

                return half4(0, 0, 0, 1);
                // // refraction
                // half4 refraction = GetRefraction(vertexOutput, lightingData);

                // // final
                // half3 finalColor = lerp(refraction.rgb, reflection, refraction.a);

                // return half4(finalColor, 1);
            }

            #endif
            ENDHLSL

        }
    }

    FallBack "VertexLit"
}
