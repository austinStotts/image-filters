[[block]] struct TextureData {
    data: array<u8>;
};

[[group(0), binding(0)]] var<storage, read_write> textureData: TextureData;

[[stage(compute), workgroup_size(1, 1, 1)]]
fn main([[builtin(global_invocation_id)]] global_id: vec3<u32>) {
    let width = u32(textureData.data.length / 4); // Assuming RGBA format
    let x = global_id.x;
    let y = global_id.y;
    
    // Get the RGBA values of the current pixel
    let index = (y * width + x) * 4;
    let pixel = vec4<f32>(
        f32(textureData.data[index]) / 255.0,
        f32(textureData.data[index + 1]) / 255.0,
        f32(textureData.data[index + 2]) / 255.0,
        f32(textureData.data[index + 3]) / 255.0
    );
    
    // Compute the luminance of the pixel
    let luminance = dot(pixel.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
    
    // Sobel edge detection
    var gradientX: f32 = 0.0;
    var gradientY: f32 = 0.0;
    
    // Horizontal Sobel filter
    gradientX += textureData.data[(y - 1) * width * 4 + (x - 1) * 4] * -1.0;
    gradientX += textureData.data[(y - 1) * width * 4 + x * 4] * -2.0;
    gradientX += textureData.data[(y - 1) * width * 4 + (x + 1) * 4] * -1.0;
    gradientX += textureData.data[(y + 1) * width * 4 + (x - 1) * 4] * 1.0;
    gradientX += textureData.data[(y + 1) * width * 4 + x * 4] * 2.0;
    gradientX += textureData.data[(y + 1) * width * 4 + (x + 1) * 4] * 1.0;
    
    // Vertical Sobel filter
    gradientY += textureData.data[(y - 1) * width * 4 + (x - 1) * 4] * -1.0;
    gradientY += textureData.data[y * width * 4 + (x - 1) * 4] * -2.0;
    gradientY += textureData.data[(y + 1) * width * 4 + (x - 1) * 4] * -1.0;
    gradientY += textureData.data[(y - 1) * width * 4 + (x + 1) * 4] * 1.0;
    gradientY += textureData.data[y * width * 4 + (x + 1) * 4] * 2.0;
    gradientY += textureData.data[(y + 1) * width * 4 + (x + 1) * 4] * 1.0;
    
    // Compute the magnitude of the gradient
    let magnitude = sqrt(gradientX * gradientX + gradientY * gradientY);
    
    // Output the result
    textureData.data[index] = u8(magnitude * 255.0);
    textureData.data[index + 1] = u8(magnitude * 255.0);
    textureData.data[index + 2] = u8(magnitude * 255.0);
    textureData.data[index + 3] = 255u8; // Alpha channel remains unchanged
}
