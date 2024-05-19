//
//  Shaders.metal
//  paper
//
//  Created by Michael Lee on 5/16/24.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
};

vertex float4 vertex_main(VertexIn in [[stage_in]], constant float &scale [[buffer(1)]]) {
    // Simulate crumpling effect by modifying the position based on some noise function
    float noiseX = sin(in.position.x * 10.0 * scale) * 0.1 * scale;
    float noiseY = cos(in.position.y * 10.0 * scale) * 0.1 * scale;
    float2 crumpledPosition = in.position + float2(noiseX, noiseY);
    return float4(crumpledPosition, 0.0, 1.0);
}

fragment float4 fragment_main() {
    return float4(1.0, 1.0, 1.0, 1.0); // White color
}







