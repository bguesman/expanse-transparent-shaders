#ifndef EXPANSE_TRANSPARENCY_INCLUDED
#define EXPANSE_TRANSPARENCY_INCLUDED

#include "../../code/source/clouds/CloudGlobalTextures.hlsl"
#include "../../code/source/atmosphere/AtmosphereGlobalTextures.hlsl"

float4 EvaluateExpanseFog(float linear01Depth, float2 uv, float4 color, float exposure) {
    float4 fog = float4(0, 0, 0, 1);
    SampleExpanseFog_float(linear01Depth, uv, fog);
    return float4(color.xyz * fog.w + exposure * fog.xyz, color.w);
}

float4 EvaluateExpanseFogAndClouds(float linear01Depth, float2 uv, float4 color, float exposure) {
    float4 outColor = color;
    
    /* Here's all the things we'll be sampling + compositing. */
    float4 fogOnGeometry = float4(0, 0, 0, 1);
    float3 cloudColor = 0;
    float3 cloudAlpha = 1;
    float cloudT = 0;
    float4 fogOnClouds = float4(0, 0, 0, 1);

    /* Sample distant fog and clouds. */
    SampleExpanseFog_float(linear01Depth, uv, fogOnGeometry);
    SampleExpanseClouds_float(uv, cloudColor, cloudAlpha, cloudT);
    
    /* Composite fog on top of geometry. */
    outColor.xyz *= fogOnGeometry.w;
    outColor.xyz += exposure * fogOnGeometry.xyz;

    /* Only sample fog on clouds if the clouds are in front of the
     * geometry. */
    float3 view = float3(0, 0, 1);
    float3 d = normalize(float3(uv * 2 - 1, 1));
    float eyeMultiplier = dot(view, d);
    float cloudLinearDepth = saturate((cloudT * _ProjectionParams.w * eyeMultiplier));
    if (cloudLinearDepth < linear01Depth) {
        SampleExpanseFog_float(cloudLinearDepth, uv, fogOnClouds);
        outColor.xyz *= cloudAlpha;
        outColor.xyz += exposure * cloudColor;
        outColor.xyz += exposure * fogOnClouds.xyz * (1 - cloudAlpha);
    }
    return outColor;
}

#endif // EXPANSE_TRANSPARENCY_INCLUDED