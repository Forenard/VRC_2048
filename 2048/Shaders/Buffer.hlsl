float3 unpack(sampler2D _Tex,uint id)
{
    int idx = id % SQRTED_SIZE;
    int idy = id / SQRTED_SIZE;
    float2 uv = (float2(idx, idy)+float2(0.5,0.5)) / float(SQRTED_SIZE);
    float2 uv0 = uv + float2(0.25, 0.25) / float(SQRTED_SIZE);
    float2 uv1 = uv + float2(0.25, -0.25) / float(SQRTED_SIZE);
    float2 uv2 = uv + float2(-0.25, -0.25) / float(SQRTED_SIZE);
    float2 uv3 = uv + float2(-0.25, 0.25) / float(SQRTED_SIZE);
    uint3 v0 = uint3(tex2Dlod(_Tex, float4(uv0,0,0)).rgb*255.0+0.5)<<0;
    uint3 v1 = uint3(tex2Dlod(_Tex, float4(uv1,0,0)).rgb*255.0+0.5)<<8;
    uint3 v2 = uint3(tex2Dlod(_Tex, float4(uv2,0,0)).rgb*255.0+0.5)<<16;
    uint3 v3 = uint3(tex2Dlod(_Tex, float4(uv3,0,0)).rgb*255.0+0.5)<<24;
    uint3 v = v0+v1+v2+v3;
    return asfloat(v);
}

bool pack(uint id,float2 uv)
{
    int idx = id % SQRTED_SIZE;
    int idy = id / SQRTED_SIZE;
    float2 uv0 = float2(idx, idy) / float(SQRTED_SIZE);
    float2 uv1 = float2(idx+1, idy+1) / float(SQRTED_SIZE);
    return all(uv0 <= uv && uv <= uv1);
}

float3 ixPackColor(float3 xyz, uint ix) {
    uint3 xyzI = asuint(xyz);
    xyzI = (xyzI >> (ix * 8)) % 256;
    return (float3(xyzI) + 0.5) / 255.0;
}

float3 packColor(float3 color,float2 uv)
{
    float2 muv = fmod(uv,1.0/float(SQRTED_SIZE));
    bool yup = muv.y > 0.5/float(SQRTED_SIZE);
    bool xup = muv.x > 0.5/float(SQRTED_SIZE);
    uint ix = 0;
    if(yup&&xup) ix = 0;
    else if(!yup&&xup) ix = 1;
    else if(!yup&&!xup) ix = 2;
    else ix = 3;
    return ixPackColor(color,ix);
}