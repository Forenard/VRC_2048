Shader "Custom/2048Model"
{
    Properties
    {
        _Buffer ("Buffer", 2D) = "white" {}
        _Input ("Input", Float) = 0
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"
            // できるだけそのままカメラに映すためにOverlayにする
            "Queue"="Overlay"
            "DisableBatching"="True"
        }
        LOD 200
        ZWrite Off
        ZTest Always
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "2048Header.hlsl"
            #include "../Buffer.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _Buffer;
            float4 _Buffer_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _Buffer);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                // Perspectiveの場合は見えなくする
                if(UNITY_MATRIX_P[3][3]!=1)
                {
                    o.vertex = 0;
                }
                return o;
            }

            // 0:None
            // 1:Up
            // 2:Right
            // 3:Down
            // 4:Left
            // 5:Reset
            int _Input;

            float hash(float2 n) {
                return frac(sin(dot(n, float2(12.9898, 4.1414))) * 43758.5453);
            }

            float2 hash2(float2 st){
                st = float2( dot(st,float2(127.1,311.7)),
                dot(st,float2(269.5,183.3)) );
                return -1.0 + 2.0*frac(sin(st)*43758.5453123);
            }

            fixed4 frag (v2f IN) : SV_Target
            {
                int i,j,k,index;
                int cells[4][4];
                int frame = 0;
                int prevInput = 0,input;
                float2 uv = IN.uv;
                float3 col = tex2D(_Buffer, uv).rgb;

                // 初期化処理
                if(_Input==5)
                {
                    col = float3(0,0,0);
                    // 値の保存
                    for(i=0;i<4;i++)
                    {
                        for(j=0;j<4;j++)
                        {
                            index = ID_CELLS + i*4+j;
                            // セルの保存
                            col = pack(index,uv)?packColor(float3(0,0,0),uv):col;
                        }
                    }
                    // フレームの保存
                    col = pack(ID_FRAME,uv)?packColor(float3(0,0,0),uv):col;
                    // ひとつ前の入力の保存
                    col = pack(ID_PREV_INPUT,uv)?packColor(float3(0,0,0),uv):col;
                    // 値の書き込み
                    return float4(col,1);
                }

                // 値の読み込み
                for(i=0;i<4;i++)
                {
                    for(j=0;j<4;j++)
                    {
                        index = ID_CELLS + i*4+j;
                        // セルの読み込み
                        int val = int(unpack(_Buffer,index).r+0.5);
                        cells[i][j] = val;
                    }
                }
                // フレームの読み込み
                frame = int(unpack(_Buffer,ID_FRAME).r+0.5);
                // フレームを進める
                frame += 1;
                // ひとつ前の入力の読み込み
                prevInput = int(unpack(_Buffer,ID_PREV_INPUT).r+0.5);

                // 何もしない
                if(_Input==0)
                {
                    // フレームの保存
                    col = pack(ID_FRAME,uv)?packColor(float3(frame,0,0),uv):col;
                    // ひとつ前の入力の保存
                    col = pack(ID_PREV_INPUT,uv)?packColor(float3(_Input,0,0),uv):col;
                    // 値の書き込み
                    return float4(col,1);
                }

                // ひとつ前の入力と同じ入力は無視
                if(_Input==prevInput)
                {
                    // フレームの保存
                    col = pack(ID_FRAME,uv)?packColor(float3(frame,0,0),uv):col;
                    return float4(col, 1);
                }

                // 入力に応じてセルを動かす
                // インデックスの定義
                static const int inds[2][4] = { {0,1,2,3}, {3,2,1,0} };
                // y方向のインデックス
                static const int yrule[4] = {1,0,0,0};
                // x方向のインデックス
                static const int xrule[4] = {0,1,0,0};
                // 動く方向
                static const int2 dir[4] = { {0,1}, {1,0}, {0,-1}, {-1,0} };
                // インプットを扱いやすいように変換
                input = _Input-1;
                // セルの更新
                for(i=0;i<4;i++)
                {
                    for(j=0;j<4;j++)
                    {
                        int yind = inds[yrule[input]][i];
                        int xind = inds[xrule[input]][j];
                        int val = cells[yind][xind];
                        // 空のセルは無視
                        if(val==0)
                        {
                            continue;
                        }
                        // セルの移動
                        while(true)
                        {
                            int y = yind + dir[input].y;
                            int x = xind + dir[input].x;
                            // 範囲外に出たら移動できなかったとして終了
                            if(y<0 || y>=4 || x<0 || x>=4)
                            {
                                break;
                            }
                            // 移動先が空のセルなら移動
                            if(cells[y][x]==0)
                            {
                                cells[y][x] = val;
                                cells[yind][xind] = 0;
                                yind = y;
                                xind = x;
                            }
                            // 移動先が同じ値のセルなら結合
                            else if(cells[y][x]==val)
                            {
                                cells[y][x] = val*2;
                                cells[yind][xind] = 0;
                                break;
                            }
                            // 移動先が異なる値のセルなら終了
                            else
                            {
                                break;
                            }
                        }
                    }
                }

                // セルを生成(ランダム)
                int seed = 0;
                for(i=0;i<4;i++)
                {
                    for(j=0;j<4;j++)
                    {
                        seed += cells[i][j];
                    }
                }
                
                // 乱数の生成
                int2 cent = int2(hash2(float2(seed,0))*4);
                int val = pow(2,int(hash(float2(0,seed))*2)+1);
                bool flag = 0;
                for(i=0;i<4;i++)
                {
                    for(j=0;j<4;j++)
                    {
                        int2 pos = int2(i,j)+cent;
                        pos.x = pos.x%uint(4);
                        pos.y = pos.y%uint(4);
                        if(cells[pos.y][pos.x]==0)
                        {
                            cells[pos.y][pos.x] = val;
                            flag = 1;
                            break;
                        }
                    }
                    if(flag)
                    {
                        break;
                    }
                }

                // 値の保存
                for(i=0;i<4;i++)
                {
                    for(j=0;j<4;j++)
                    {
                        index = ID_CELLS + i*4+j;
                        // セルの保存
                        col = pack(index,uv)?packColor(float3(cells[i][j],0,0),uv):col;
                    }
                }
                // フレームの保存
                col = pack(ID_FRAME,uv)?packColor(float3(frame,0,0),uv):col;
                // ひとつ前の入力の保存
                col = pack(ID_PREV_INPUT,uv)?packColor(float3(_Input,0,0),uv):col;
                // 値の書き込み
                return float4(col,1);
            }
            ENDCG
        }
    }
}
