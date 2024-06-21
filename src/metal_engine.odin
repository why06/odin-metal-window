package main

import "core:fmt"
import NS "core:sys/darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"


createTriangle :: proc(device: ^MTL.Device) {
	NUM_VERTICES :: 3
	// triangle has 3 points in 3 dimensions
	triangleVertices := [NUM_VERTICES][3]f32 {
		// vertices
		{-0.5, -0.5, 0.0},
		{0.5, -0.5, 0.0},
		{0.0, 0.5, 0.0},
	}

	device->newBufferWithSlice(triangleVertices[:], {}) //empty options uses default of shared
}

createDefaultLibrary :: proc(device: ^MTL.Device) -> ^MTL.Library {
	// XCode creates default library but we're not using XCode
	// metalDefaultLibrary := device->newDefaultLibrary()
	// assert(metalDefaultLibrary != nil, "Failed to create default library")
	// return metalDefaultLibrary
	return nil
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
	metalLayer: ^CA.MetalLayer,
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
