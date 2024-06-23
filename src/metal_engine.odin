package main

import "core:fmt"
import NS "core:sys/darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"


createTriangle :: proc(device: ^MTL.Device) -> ^MTL.Buffer {
	NUM_VERTICES :: 3
	// triangle has 3 points in 3 dimensions
	triangleVertices := [NUM_VERTICES][3]f32 {
		// vertices
		{-0.5, -0.5, 0.0},
		{0.0, 0.5, 0.0},
		{0.5, -0.5, 0.0},
	}

	return device->newBufferWithSlice(triangleVertices[:], {}) //empty options uses default of shared
}

// NOT USED
// XCode creates default library but we're not using XCode
// This could be useful if we figureout how to compile shaders to a .metallib
createDefaultLibrary :: proc(device: ^MTL.Device) -> ^MTL.Library {
	metalDefaultLibrary := device->newDefaultLibrary()
	assert(metalDefaultLibrary != nil, "Failed to create default library")
	return metalDefaultLibrary
}

shader_source: string = #load("shaders/triangle.metal")

createLibraryFromSource :: proc(
	devive: ^MTL.Device,
) -> (
	metal_library: ^MTL.Library,
	err: ^NS.Error,
) {
	metal_library = devive->newLibraryWithSource(NS_String(shader_source), nil) or_return
	assert(metal_library != nil, "Failed to create library from traingle.metal")
	return
}

createCommandQueue :: proc(device: ^MTL.Device) -> ^MTL.CommandQueue {
	return device->newCommandQueue()
}

createRenderPipeline :: proc(
	device: ^MTL.Device,
	library: ^MTL.Library,
) -> (
	render_pso: ^MTL.RenderPipelineState,
	err: ^NS.Error,
) {
	// These correspond to the name functions in triangle.metal (our shader library)
	vertexFunction := library->newFunctionWithName(NS.AT("vertexShader"))
	fragmentFunction := library->newFunctionWithName(NS.AT("fragmentShader"))
	assert(vertexFunction != nil, "Failed to create vertex function")
	assert(fragmentFunction != nil, "Failed to create fragment function")

	//Create render pipeline descriptor
	descriptor: ^MTL.RenderPipelineDescriptor = MTL.RenderPipelineDescriptor_alloc()->init()
	defer descriptor->release()
	descriptor->setLabel(NS.AT("Triangle Rendering Pipeline"))
	descriptor->setVertexFunction(vertexFunction)
	descriptor->setFragmentFunction(fragmentFunction)

	// Default Metal Pixel Format: https://developer.apple.com/documentation/quartzcore/cametallayer/1478155-pixelformat
	descriptor->colorAttachments()->object(0)->setPixelFormat(.BGRA8Unorm_sRGB)

	// finally with have a our Render Pipeline State Object that specifies our render pipeline
	render_pso = device->newRenderPipelineStateWithDescriptor(descriptor) or_return
	return
}

configureColorAttachment :: proc(color_desc: ^MTL.RenderPassColorAttachmentDescriptor) {
	color_desc->setLoadAction(.Clear) // remove the previous contents of the texture
	color_desc->setStoreAction(.Store) // store the result of the render pass in the texture
	color_desc->setClearColor(MTL.ClearColor{19.0 / 255.0, 20.0 / 255.0, 24.0 / 255.0, 1.0})
}

configureRenderPass :: proc(pass: ^MTL.RenderPassDescriptor, drawable: ^CA.MetalDrawable) {
	// Configure color attachment
	color_desc := pass->colorAttachments()->object(0)
	assert(color_desc != nil, "Failed to create color attachment")
	color_desc->setTexture(drawable->texture()) // clear the texture
	configureColorAttachment(color_desc)
}

encodeRenderCommand :: proc(
	encoder: ^MTL.RenderCommandEncoder,
	pso: ^MTL.RenderPipelineState,
	vertex_buffer: ^MTL.Buffer,
) {
	encoder->setRenderPipelineState(pso)
	encoder->setVertexBuffer(vertex_buffer, 0, 0)
	encoder->drawPrimitives(.Triangle, 0, 3) // vertex start: 0, vertex count: 3
}
