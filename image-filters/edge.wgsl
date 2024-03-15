// Vertex shader
[[stage(vertex)]]
fn main(
    [[location(0)]] position: vec2<f32>,
) -> [[builtin(position)]] vec4<f32> {
    return vec4<f32>(position, 0.0, 1.0);
}

// Fragment shader
[[stage(fragment)]]
fn main(
    [[builtin(position)]] in_position: vec4<f32>,
    [[location(0)]] color: vec4<f32>,
    [[binding(0), group(0)]] textureSampler: sampler,
    [[texture(0), set(0)]] inputTexture: texture_2d<f32>,
    [[location(1)]] outputColor: vec4<f32>
) {
    let texelSize = vec2<f32>(1.0 / textureDimensions(inputTexture).x, 1.0 / textureDimensions(inputTexture).y);
    
    // Kernel for edge detection
    let kernel = mat3<f32>(
        -1.0, -1.0, -1.0,
        -1.0,  8.0, -1.0,
        -1.0, -1.0, -1.0
    );
    
    var edge: vec3<f32> = vec3<f32>(0.0);
    
    // Convolve image with kernel
    for (var y: i32 = -1; y <= 1; y = y + 1) {
        for (var x: i32 = -1; x <= 1; x = x + 1) {
            let offset = vec2<i32>(x, y);
            let texCoord = in_position.xy + texelSize * vec2<f32>(offset);
            let sampleColor = textureSample(inputTexture, textureSampler, texCoord);
            edge += sampleColor.rgb * kernel[y + 1][x + 1];
        }
    }
    
    // Clamp edge values to avoid overflow
    edge = clamp(edge, vec3<f32>(0.0), vec3<f32>(1.0));
    
    // Output the edge-detected color
    outputColor = vec4<f32>(edge, 1.0);
}
