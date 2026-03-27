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
    """
}
