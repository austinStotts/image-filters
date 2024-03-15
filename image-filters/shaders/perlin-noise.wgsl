// Perlin noise function
fn perlin_noise(vec2: vec2) -> f32 {
    let uv = vec2 * 289.0 + vec2.yx * (vec2.yx + 1.0);
    let a = textureSample(tex, sampler, uv.floor()).r;
    let b = textureSample(tex, sampler, uv + vec2(1.0, 0.0).floor()).r;
    let c = textureSample(tex, sampler, uv + vec2(0.0, 1.0).floor()).r;
    let d = textureSample(tex, sampler, uv + 1.0).r;

    let xy = fract(uv);
    let x = mix(a, b, xy.x);
    let y = mix(c, d, xy.x);
    
    return mix(x, y, xy.y) * 2.0 - 1.0;
}

// Main function to generate noise map
[[stage(vertex)]]
fn main_vertex(
    [[location(0)]] position: vec4<f32>,
    [[location(1)]] uv: vec2<f32>,
    [[builtin(vertex_index)]] vertex_index: u32,
    [[out(0)]] out_uv: vec2<f32>,
) {
    out_uv = uv;
}

[[stage(fragment)]]
fn main_fragment(
    [[location(0)]] in_uv: vec2<f32>,
    [[out(0)]] frag_color: vec4<f32>,
) {
    let tex_size = vec2<f32>(512.0, 512.0);
    let tex_coord = in_uv * tex_size / 10.0; // Adjust the divisor for scale
    let noise_val = perlin_noise(tex_coord);
    frag_color = vec4<f32>(noise_val, noise_val, noise_val, 1.0);
}

// Output the noise map as a texture
[[group(0), binding(0)]]
var<storage, read_write> output_texture: texture_2d<f32>;

[[group(0), binding(1)]]
var<storage, read_write> output_texture_view: texture_2d<f32>;

[[stage(compute), workgroup_size(1, 1, 1)]]
fn main_compute([[builtin(global_invocation_id)]] global_id: vec3<u32>) {
    let tex_size = vec2<u32>(512u, 512u); // Adjust the size accordingly
    let pixel_coord = vec2<u32>(global_id.xy);
    let texel_coord = pixel_coord * tex_size / 512u;

    let uv = vec2<f32>(texel_coord) / vec2<f32>(tex_size);

    let noise_val = perlin_noise(uv * 10.0); // Adjust the scale

    textureStore(output_texture, vec2<u32>(pixel_coord), vec4<f32>(noise_val, noise_val, noise_val, 1.0));
}
