// Require : _FontTex
// : _FontColor

float4 char(int id,float2 uv)
{
    float2 nuv = float2(id%uint(16),15-id/uint(16))/16.0 + frac(uv)/16.0;
    return tex2D(_FontTex,nuv);
}
float4 number(int id,float2 uv)
{
    return char(id+48,uv);
}
float4 alphabet(int id,float2 uv)
{
    return char(id+65,uv);
}
bool inuv(float2 uv,float2 pos)
{
    float eps = 0.1;
    return (uv.x > pos.x+eps && uv.x < pos.x+1-eps && uv.y > pos.y+eps && uv.y < pos.y+1-eps);
}

// アルファベット
#define A(_x,_y,_c,_col,_uv) _col=inuv(_uv,float2(_x,_y))?alphabet(_c,_uv).r*_FontColor:_col
// 数字
#define N(_x,_y,_c,_col,_uv) _col=inuv(_uv,float2(_x,_y))?number(_c,_uv).r*_FontColor:_col
// その他の文字
#define C(_x,_y,_c,_col,_uv) _col=inuv(_uv,float2(_x,_y))?char(_c,_uv).r*_FontColor:_col