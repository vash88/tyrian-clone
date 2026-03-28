import simd

struct PrimitiveVertex {
    var position: SIMD2<Float>
    var color: SIMD4<Float>
    var textureCoordinate: SIMD2<Float>
    var textureMix: Float

    init(
        position: SIMD2<Float>,
        color: SIMD4<Float>,
        textureCoordinate: SIMD2<Float> = .zero,
        textureMix: Float = 0
    ) {
        self.position = position
        self.color = color
        self.textureCoordinate = textureCoordinate
        self.textureMix = textureMix
    }
}
