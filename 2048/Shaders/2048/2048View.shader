Shader "Custom/2048View"
{
    Properties
    {
        _FontTex ("Font (RGB)", 2D) = "white" {}
        _Buffer ("Buffer (RGB)", 2D) = "white" {}
        _BackColor ("Background Color", Color) = (0,0,0,0)
        _EdgeColor ("Edge Color", Color) = (1,1,1,0)
        _FontColor ("Font Color", Color) = (1,1,1,0)
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
        float3 _BackColor;
        float3 _EdgeColor;
        float3 _FontColor;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 uv = IN.uv_FontTex;
            float3 col = _BackColor;
            float2 muv = frac(uv * 4);
            int2 iuv = int2(uv * 4);
            int i,j,k,cell,index;

            // edge
            if (muv.x < 0.02 || muv.x > 0.98 || muv.y < 0.02 || muv.y > 0.98)
            {
                col = _EdgeColor;
            }

            // fontの描画
            [unroll]
            for(index=0;index<16;index++)
            {
                i=index/4;
                j=index%4;
                if(!(iuv.x == j && iuv.y == i))
                {
                    continue;
                }
                // 値の読み込み
                cell = ID_CELLS + i*4+j;
                // セルの読み込み
                int val = int(unpack(_Buffer,cell).r+0.5);
                // 空白セルはスキップ
                if(val == 0)
                {
                    continue;
                }
                // 値の桁数の計算
                int tmp = val;
                int dec = 0;
                [loop]
                while(1)
                {
                    if(tmp == 0)
                    {
                        break;
                    }
                    tmp /= uint(10);
                    dec++;
                }
                // 桁数に応じて位置を調整しながらフォントを描画
                float2 fuv = muv*dec;
                fuv.y -= (dec-1)*0.5;
                tmp = val;
                [loop]
                for(k=0;k<dec;k++)
                {
                    int digit = tmp % uint(10);
                    tmp /= uint(10);
                    N(dec-k-1,0,digit,col,fuv);
                }
            }

            // Standerdシェーダーのパラメータを設定
            o.Albedo = col;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = _Alpha;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
