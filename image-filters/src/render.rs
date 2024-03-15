use image::{DynamicImage, ImageBuffer, Rgba};
use std::fs::File;
use std::io::BufWriter;
use wgpu::util::DeviceExt;

const OUTPUT_IMAGE_PATH: &str = "output.png";

// Main function
fn run() {
    // Load input image
    let input_image = image::load_from_memory(include_bytes!("cat.png"))?.to_rgba8();
    let (width, height) = input_image.dimensions();

    // Initialize WGPU device
    let instance = wgpu::Instance::new(wgpu::BackendBit::PRIMARY);
    let adapter = futures::executor::block_on(instance.request_adapter(
        &wgpu::RequestAdapterOptions {
            power_preference: wgpu::PowerPreference::Default,
            compatible_surface: None,
        },
    ))
    .unwrap();
    let (device, queue) = futures::executor::block_on(adapter.request_device(
        &wgpu::DeviceDescriptor {
            features: wgpu::Features::empty(),
            limits: wgpu::Limits::default(),
            label: None,
        },
        None,
    ))
    .unwrap();

    // Create texture from input image
    let texture = device.create_texture_from_image(&input_image);

    // Load shaders
    let shader = device.create_shader_module(wgpu::ShaderSource::Wgsl(include_str!("../shaders/perlin-noise.wgsl").into()));
    // let fs_module = device.create_shader_module(wgpu::include_spirv!("shader.frag.spv"));

    // Create render pipeline
    let render_pipeline_layout =
        device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: None,
            bind_group_layouts: &[],
            push_constant_ranges: &[],
        });
    let render_pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
        label: None,
        layout: Some(&render_pipeline_layout),
        vertex: wgpu::VertexState {
            module: &shader,
            entry_point: "vmain",
            buffers: &[],
        },
        fragment: Some(wgpu::FragmentState {
            module: &shader,
            entry_point: "fmain",
            targets: &[wgpu::ColorTargetState {
                format: wgpu::TextureFormat::Rgba8UnormSrgb,
                blend: Some(wgpu::BlendState::REPLACE),
                write_mask: wgpu::ColorWrite::ALL,
            }],
        }),
        primitive: wgpu::PrimitiveState::default(),
        depth_stencil: None,
        multisample: wgpu::MultisampleState::default(),
    });

    // Create output texture and bind group
    let output_texture = device.create_texture(&wgpu::TextureDescriptor {
        label: None,
        size: wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: 1,
        },
        mip_level_count: 1,
        sample_count: 1,
        dimension: wgpu::TextureDimension::D2,
        format: wgpu::TextureFormat::Rgba8UnormSrgb,
        usage: wgpu::TextureUsage::RENDER_ATTACHMENT | wgpu::TextureUsage::COPY_SRC,
    });
    let output_texture_view = output_texture.create_view(&Default::default());
    let output_bind_group_layout =
        device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: None,
            entries: &[wgpu::BindGroupLayoutEntry {
                binding: 0,
                visibility: wgpu::ShaderStage::FRAGMENT,
                ty: wgpu::BindingType::Texture {
                    multisampled: false,
                    view_dimension: wgpu::TextureViewDimension::D2,
                    sample_type: wgpu::TextureSampleType::Float { filterable: true },
                },
                count: None,
            }],
        });
    let output_bind_group =
        device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: None,
            layout: &output_bind_group_layout,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: wgpu::BindingResource::TextureView(&output_texture_view),
            }],
        });

    // Create encoder and render pass
    let mut encoder =
        device.create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });
    {
        let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
            label: None,
            color_attachments: &[wgpu::RenderPassColorAttachmentDescriptor {
                attachment: &output_texture_view,
                resolve_target: None,
                ops: wgpu::Operations {
                    load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                    store: true,
                },
            }],
            depth_stencil_attachment: None,
        });
        render_pass.set_pipeline(&render_pipeline);
        render_pass.draw(0..3, 0..1);
    }

    // Submit commands
    queue.submit(Some(encoder.finish()));

    // Read pixel data from output texture
    let output_buffer = device.create_buffer(&wgpu::BufferDescriptor {
        label: None,
        size: (width * height * 4) as u64,
        usage: wgpu::BufferUsage::COPY_DST | wgpu::BufferUsage::MAP_READ,
        mapped_at_creation: false,
    });
    queue.copy_texture_to_buffer(
        wgpu::ImageCopyTexture {
            texture: &output_texture,
            mip_level: 0,
            origin: wgpu::Origin3d::ZERO,
            aspect: wgpu::TextureAspect::All,
        },
        wgpu::ImageCopyBuffer {
            buffer: &output_buffer,
            layout: wgpu::ImageDataLayout {
                offset: 0,
                bytes_per_row: Some(std::num::NonZeroU32::new(width * 4).unwrap()),
                rows_per_image: Some(std::num::NonZeroU32::new(height).unwrap()),
            },
        },
        wgpu::Extent3d {
            width,
            height,
            depth_or_array_layers: 1,
        },
    );

    // Wait for the copy operation to complete
    queue.poll(wgpu::Maintain::Wait);

    // Save output image
    let output_slice = output_buffer.slice(..);
    let output_future = output_slice.map_async(wgpu::MapMode::Read);
    futures::executor::block_on(output_future).unwrap();
    let output_data = output_slice.get_mapped_range();
    let output_image = ImageBuffer::<Rgba<u8>, _>::from_raw(width, height, output_data.to_vec())
        .expect("Failed to create output image buffer");
    output_image
        .save(OUTPUT_IMAGE_PATH)
        .expect("Failed to save output image");
}
