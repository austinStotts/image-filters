// [[block]] struct TextureData {
//     data: array<u8>;
// };

@group(0) @binding(0) var srcTexture : texture_2d<f32>;
@group(0) @binding(1) var dstTexture : texture_storage_2d<rgba8unorm, write>;

@compute
@workgroup_size(16, 16)
fn main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let texelCoord = vec2<i32>(global_id.xy);
    let srcPixel: vec4<f32> = textureLoad(srcTexture, texelCoord, 0);
    
    // Compute the luminance of the pixel
    let luminance = dot(srcPixel.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
    
    // Sobel edge detection
    var gradientX: f32 = 0.0;
    var gradientY: f32 = 0.0;
    
    // Horizontal Sobel filter
    gradientX += textureLoad(srcTexture, texelCoord + vec2(-1, -1), 0).r * -1.0;
    gradientX += textureLoad(srcTexture, texelCoord + vec2(-1, 0), 0).r * -2.0;
    gradientX += textureLoad(srcTexture, texelCoord + vec2(-1, 1), 0).r * -1.0;
    gradientX += textureLoad(srcTexture, texelCoord + vec2(1, -1), 0).r * 1.0;
    gradientX += textureLoad(srcTexture, texelCoord + vec2(1, 0), 0).r * 2.0;
    gradientX += textureLoad(srcTexture, texelCoord + vec2(1, 1), 0).r * 1.0;
    
    // Vertical Sobel filter
    gradientY += textureLoad(srcTexture, texelCoord + vec2(-1, -1), 0).r * -1.0;
    gradientY += textureLoad(srcTexture, texelCoord + vec2(0, -1), 0).r * -2.0;
    gradientY += textureLoad(srcTexture, texelCoord + vec2(1, -1), 0).r * -1.0;
    gradientY += textureLoad(srcTexture, texelCoord + vec2(-1, 1), 0).r * 1.0;
    gradientY += textureLoad(srcTexture, texelCoord + vec2(0, 1), 0).r * 2.0;
    gradientY += textureLoad(srcTexture, texelCoord + vec2(1, 1), 0).r * 1.0;
    
    // Compute the magnitude of the gradient
    let magnitude = sqrt(gradientX * gradientX + gradientY * gradientY);
    
    // Output the result
    textureStore(dstTexture, texelCoord, vec4(magnitude, magnitude, magnitude, 1.0));
    // textureStore(dstTexture, texelCoord, vec4(srcPixel.r/2.0, srcPixel.g, srcPixel.b, 1.0));
}
