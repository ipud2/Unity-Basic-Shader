Shader "Unlit/SSS"
{
    CGINCLUDE
    #include "SSSCommon.cginc"
    ENDCG

    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        ZTest Always
        ZWrite Off
        Cull Off
        Stencil
        {
            Ref 5
            Comp Equal
            Pass Keep
        }

        Pass
        {
            Name "XBlur"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_SourceTex, i.uv);
                float sssIntensity = _SSSScaler * _CameraDepthTexture_TexelSize.x;
                float3 xBlur = SSS(col, i.uv, float2(sssIntensity, 0)).rgb;

                return float4(xBlur, col.a);
            }
            ENDCG
        }

        Pass
        {
            Name "YBlur"
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag(v2f i) : SV_Target
            {
                // sample the texture
                float4 col = tex2D(_SourceTex, i.uv);
                float sssIntensity = _SSSScaler * _CameraDepthTexture_TexelSize.y;
                float3 yBlur = SSS(col, i.uv, float2(0, sssIntensity)).rgb;
                
                return float4(yBlur, col.a);
            }
            ENDCG
        }
    }
        Fallback "Diffuse"

}