package main

import "core:bytes"
import "core:fmt"
import "core:image"
import PNG "core:image/png"
import "core:os"

import NS "core:sys/darwin/Foundation"
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"

import glm "core:math/linalg/glsl"


Vertex_Data :: struct {
	position: [4]f32,
	texcoord: [2]f32,
}

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

createSquare :: proc(device: ^MTL.Device) -> ^MTL.Buffer {
	NUM_VERTICES :: 6
	// square has 6 points in 3 dimensions
	squareVertices := []Vertex_Data {
		// vertices & texcoords
		{{-0.5, -0.5, 0.5, 1.0}, {0.0, 0.0}},
		{{-0.5, 0.5, 0.5, 1.0}, {0.0, 1.0}},
		{{0.5, 0.5, 0.5, 1.0}, {1.0, 1.0}},
		{{-0.5, -0.5, 0.5, 1.0}, {0.0, 0.0}},
		{{0.5, 0.5, 0.5, 1.0}, {1.0, 1.0}},
		{{0.5, -0.5, 0.5, 1.0}, {1.0, 0.0}},
	}

	return device->newBufferWithSlice(squareVertices[:], {}) //empty options uses default of shared
}

// NOT USED
// XCode creates default library but we're not using XCode
// This could be useful if we figureout how to compile shaders to a .metallib
createDefaultLibrary :: proc(device: ^MTL.Device) -> ^MTL.Library {
	metalDefaultLibrary := device->newDefaultLibrary()
	assert(metalDefaultLibrary != nil, "Failed to create default library")
	return metalDefaultLibrary
}

createTriangleLibrary :: proc(device: ^MTL.Device) -> (lib: ^MTL.Library, err: ^NS.Error) {
	lib = createLibraryFromFile(device, "src/shaders/built/triangle.metallib") or_return
	return
}

createLibraryFromFile :: proc(
	device: ^MTL.Device,
	url: string,
) -> (
	lib: ^MTL.Library,
	err: ^NS.Error,
) {
	_url := NS.URL_alloc()->initFileURLWithPath(NS_String(url))
	defer _url->release()
	lib = device->newLibraryWithURL(_url) or_return
	assert(lib != nil, "Failed to create library from file")
	return
}

shader_source: string = #load("shaders/triangle.metal")
createLibraryFromSource :: proc(devive: ^MTL.Device) -> (lib: ^MTL.Library, err: ^NS.Error) {
	lib = devive->newLibraryWithSource(NS_String(shader_source), nil) or_return
	assert(lib != nil, "Failed to create library from traingle.metal")
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
	texture: ^MTL.Texture,
) {
	vertexStart := 0
	vertexCount := 6
	encoder->setRenderPipelineState(pso)
	encoder->setVertexBuffer(vertex_buffer, 0, 0)
	encoder->setFragmentTexture(texture, 0) // no texture
	encoder->drawPrimitives(.Triangle, NS.UInteger(vertexStart), NS.UInteger(vertexCount))
}

Texture :: struct {
	texture:                 ^MTL.Texture,
	width, height, channels: int,
}

createTexture :: proc(device: ^MTL.Device) -> (texture: ^MTL.Texture) {

	// Load texture from file using PNG

	img: ^PNG.Image
	err: PNG.Error
	img, err = PNG.load_from_file("assets/mc_grass.png", {.alpha_add_if_missing})
	if (err != nil) {fmt.printfln("Failed to load png image", err)}
	assert(img != nil, "Failed to load png image")
	defer PNG.destroy(img)

	// switch pixel colors
	pixels := (bytes.buffer_to_bytes(&img.pixels))
	pixel_buf := make([][4]u8, img.width * img.height)
	for i in 0 ..< (img.width * img.height) {
		// RGBA -> BGRA
		pixel_buf[i] = [4]u8 {
			pixels[i * 4 + 2],
			pixels[i * 4 + 1],
			pixels[i * 4 + 0],
			pixels[i * 4 + 3],
		}
	}

	// flip vertically
	flipped_pixels := make([][4]u8, img.width * img.height)
	for y in 0 ..< img.height {
		for x in 0 ..< img.width {
			flipped_pixels[y * img.width + x] = pixel_buf[(img.height - y - 1) * img.width + x]
		}
	}

	final_pixels := raw_data(flipped_pixels)

	texture_descriptor: ^MTL.TextureDescriptor = MTL.TextureDescriptor_alloc()->init() // Create a texture descriptor
	defer texture_descriptor->release()
	texture_descriptor->setPixelFormat(.BGRA8Unorm_sRGB)
	texture_descriptor->setWidth(NS.UInteger(img.width))
	texture_descriptor->setHeight(NS.UInteger(img.height))

	// Create a texture from descriptor
	texture = device->newTextureWithDescriptor(texture_descriptor)
	assert(texture != nil, "Failed to create texture")

	// Copy the image data into the texture
	region := MTL.Region{{0, 0, 0}, {NS.Integer(img.width), NS.Integer(img.height), 1}}
	texture->replaceRegion(region, 0, final_pixels, NS.UInteger(img.width * 4))
	return
}
