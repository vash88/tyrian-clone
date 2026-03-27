#include <metal_stdlib>
using namespace metal;

struct PrimitiveVertex {
    float2 position;
    float4 color;
};

struct RasterizerData {
    float4 position [[position]];
    float4 color;
};

vertex RasterizerData primitiveVertex(
    const device PrimitiveVertex *vertices [[buffer(0)]],
    uint vertexID [[vertex_id]]
) {
    PrimitiveVertex inputVertex = vertices[vertexID];

    RasterizerData out;
    out.position = float4(inputVertex.position, 0.0, 1.0);
    out.color = inputVertex.color;
    return out;
}

fragment float4 primitiveFragment(RasterizerData in [[stage_in]]) {
    return in.color;
}
