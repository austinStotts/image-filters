

// Main function to generate noise map
@vertex
fn vertex_main() {

}

@fragment
fn fragment_main() {

}

// Output the noise map as a texture
@group(0) @binding(0) var srcTexture : texture_2d<f32>;
@group(0) @binding(1) var dstTexture : texture_storage_2d<rgba8unorm, write>;

@compute 
@workgroup_size(1, 1, 1)
fn main_compute(@builtin(global_invocation_id) global_id: vec3<u32>) {

}