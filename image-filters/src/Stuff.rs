use wgpu::util::DeviceExt;

async fn create_edge_detection_pipeline(
    device: &wgpu::Device,
    texture_format: wgpu::TextureFormat,
) -> wgpu::RenderPipeline {
    // Define the vertex shader
    let vs_module = device.create_shader_module(&wgpu::ShaderModuleDescriptor {
        label: Some("Edge Detection Vertex Shader"),
        source: wgpu::ShaderSource::Wgsl(include_str!("edge_detection.vert")),
    });

    // Define the fragment shader
    let fs_module = device.create_shader_module(&wgpu::ShaderModuleDescriptor {
        label: Some("Edge Detection Fragment Shader"),
        source: wgpu::ShaderSource::Wgsl(include_str!("edge_detection.frag")),
    });

    // Define the vertex buffer layout
    let vertex_buffer_layout = wgpu::VertexBufferLayout {
        array_stride: 2 * std::mem::size_of::<f32>() as wgpu::BufferAddress,
        step_mode: wgpu::InputStepMode::Vertex,
        attributes: &[
            wgpu::VertexAttribute {
                format: wgpu::VertexFormat::Float32x2,
                offset: 0,
                shader_location: 0,
            },
        ],
    };

    // Create the render pipeline layout
    let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
        label: Some("Edge Detection Pipeline Layout"),
        bind_group_layouts: &[],
        push_constant_ranges: &[],
    });

    // Create the render pipeline
    device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
        label: Some("Edge Detection Pipeline"),
        layout: Some(&pipeline_layout),
        vertex: wgpu::VertexState {
            module: &vs_module,
            entry_point: "main",
            buffers: &[vertex_buffer_layout],
        },
        fragment: Some(wgpu::FragmentState {
            module: &fs_module,
            entry_point: "main",
            targets: &[wgpu::ColorTargetState {
                format: texture_format,
                blend: Some(wgpu::BlendState::REPLACE),
                write_mask: wgpu::ColorWrite::ALL,
            }],
        }),
        primitive: wgpu::PrimitiveState {
            topology: wgpu::PrimitiveTopology::TriangleStrip,
            ..Default::default()
        },
        depth_stencil: None,
        multisample: wgpu::MultisampleState::default(),
    })
}

