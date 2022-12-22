Shader "Custom/2048InputView"
{
    Properties
    {
        _FontTex ("Font (RGB)", 2D) = "white" {}
        _FontColor ("Font Color", Color) = (1,1,1,1)
        _Buffer ("Buffer (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Alpha ("Alpha", Range(0,1)) = 1.0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows alpha:fade
        #pragma target 3.0

        sampler2D _FontTex;
        float3 _FontColor;
        sampler2D _Buffer;
        #include "2048Header.hlsl"
        #include "../Buffer.hlsl"
        #include "../Font.hlsl"

        struct Input
        {
            float2 uv_FontTex;
        };

        half _Glossiness;
        half _Metallic;
        float _Alpha;

        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 uv = IN.uv_FontTex;
            float3 col = float3(0,0,0);

            // ひとつ前の入力の読み込み
            int prevInput = int(unpack(_Buffer,ID_PREV_INPUT).r+0.5);
            // 矢印で表示
            int c = 16+fmod(prevInput,4);
            if(prevInput==0)
            {
                C(0,0,63,col,uv);// None
            }
            else if(prevInput==5)
            {
                C(0,0,26,col,uv);// Reset
            }
            else
            {
                C(0,0,c,col,uv);// 上下左右
            }
            
            
            o.Albedo = col;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = _Alpha;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
