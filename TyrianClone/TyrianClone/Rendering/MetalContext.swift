import MetalKit

final class MetalContext {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let library: MTLLibrary

    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue()
        else {
            return nil
        }

        let library = Self.makeLibrary(device: device)
        guard let library else {
            return nil
        }

        self.device = device
        self.commandQueue = commandQueue
        self.library = library
    }

    private static func makeLibrary(device: MTLDevice) -> MTLLibrary? {
        if let bundledLibrary = try? device.makeDefaultLibrary(bundle: .main) {
            return bundledLibrary
        }

        if let defaultLibrary = device.makeDefaultLibrary() {
            return defaultLibrary
        }

        return try? device.makeLibrary(source: shaderSourceFallback, options: nil)
    }

    private static let shaderSourceFallback = """
    #include <metal_stdlib>
    using namespace metal;

    struct PrimitiveVertex {
        float2 position;
        float4 color;
        float2 textureCoordinate;
        float textureMix;
    };

    struct RasterizerData {
        float4 position [[position]];
        float4 color;
        float2 textureCoordinate;
        float textureMix;
    };

    vertex RasterizerData primitiveVertex(
        const device PrimitiveVertex *vertices [[buffer(0)]],
        uint vertexID [[vertex_id]]
    ) {
        PrimitiveVertex inputVertex = vertices[vertexID];

        RasterizerData out;
        out.position = float4(inputVertex.position, 0.0, 1.0);
        out.color = inputVertex.color;
        out.textureCoordinate = inputVertex.textureCoordinate;
        out.textureMix = inputVertex.textureMix;
        return out;
    }

    fragment float4 primitiveFragment(
        RasterizerData in [[stage_in]],
        texture2d<float> atlasTexture [[texture(0)]],
        sampler atlasSampler [[sampler(0)]]
    ) {
        if (in.textureMix <= 0.001) {
            return in.color;
        }

        float4 sampled = atlasTexture.sample(atlasSampler, in.textureCoordinate);
        return float4(sampled.rgb * in.color.rgb, sampled.a * in.color.a);
    }
    """
}
