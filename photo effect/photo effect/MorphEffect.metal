//
//  MorphEffect.metal
//  photo effect
//
//  Created by Michael Lee on 5/23/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
    float2 textureCoordinate [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = in.position;
    out.textureCoordinate = in.textureCoordinate;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]],
                              texture2d<float> tex [[texture(0)]],
                              sampler s [[sampler(0)]],
                              constant float2 &touchLocation [[buffer(1)]],
                              constant float &scale [[buffer(2)]]) {
    constexpr sampler textureSampler (mag_filter::linear, min_filter::linear);
    float2 uv = in.textureCoordinate;
    float2 direction = uv - touchLocation;
    float2 scaledDirection = direction * scale;
    float2 newUV = touchLocation + scaledDirection;
    return tex.sample(textureSampler, newUV);
}



