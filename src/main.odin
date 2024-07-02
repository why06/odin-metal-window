package main

import NS "core:sys/darwin/Foundation" // Foundation layer for Apps on Apple Ecosystem
import MTL "vendor:darwin/Metal"
import CA "vendor:darwin/QuartzCore"
import SDL "vendor:sdl2" // cross-platform windowing and input https://wiki.libsdl.org/SDL2/Introduction

import "core:fmt"
import "core:os"

metal_main :: proc() -> (err: ^NS.Error) {

	window, cleanup := createMetalWindow()
	defer cleanup(window)
	w, h: i32
	SDL.Metal_GetDrawableSize(window, &w, &h)

	// Get Metal layer from SDL window
	window_system_info: SDL.SysWMinfo
	SDL.GetVersion(&window_system_info.version)
	SDL.GetWindowWMInfo(window, &window_system_info)
	// grab the native MacOS window that SDL uses
	assert(window_system_info.subsystem == .COCOA)
	native_window := (^NS.Window)(window_system_info.info.cocoa.window)


	// The name of the device is the name of the GPU: 'Apple M1 Max' in our case
	device := MTL.CreateSystemDefaultDevice()
	defer device->release()
	// fmt.println("Device: ", device->name()->odinString())

	// Create a Metal layer and assign to the window. 
	// When the window is displayed, the Metal layer will be used to render the content in the view.
	metal_layer := CA.MetalLayer.layer()
	defer metal_layer->release()
	metal_layer->setDevice(device)
	metal_layer->setPixelFormat(.BGRA8Unorm_sRGB) // default format
	metal_layer->setDrawableSize(NS.Size{NS.Float(w), NS.Float(h)})
	// fmt.println(w, h)
	native_window->contentView()->setLayer(metal_layer)

	// create triangle
	triangle_vertex_buffer := createTriangle(device)
	// create square
	square_vertex_buffer := createSquare(device)

	grass_texture := createTexture(device)

	defer grass_texture->release()

	// Create Metal render pipeline
	// metal_library := createTriangleLibrary(device) or_return
	metal_library := createLibraryFromFile(device, "src/shaders/built/square.metallib") or_return
	command_queue := createCommandQueue(device)
	render_PSO := createRenderPipeline(device, metal_library) or_return


	SDL.ShowWindow(window)
	// While window open loop through events. Close on quit event.
	for !quit_window {
		// Poll for SDL window events
		pollEvents(window)

		// Render
		drawable := metal_layer->nextDrawable()
		defer drawable->release()
		pass := MTL.RenderPassDescriptor_alloc()->init()
		// Configure Render Pass
		defer pass->release()
		configureRenderPass(pass, drawable)

		// Encode Render Command
		command_buffer := command_queue->commandBuffer()
		defer command_buffer->release()
		command_encoder := command_buffer->renderCommandEncoderWithDescriptor(pass)
		defer command_encoder->release()
		// encodeRenderCommand(command_encoder, render_PSO, triangle_vertex_buffer)
		encodeRenderCommand(command_encoder, render_PSO, square_vertex_buffer, grass_texture)
		command_encoder->endEncoding()

		command_buffer->presentDrawable(drawable)
		command_buffer->commit()
		command_buffer->waitUntilCompleted()
	}

	return nil
}

main :: proc() {
	err := metal_main()
	if err != nil {
		fmt.eprintln(err->localizedDescription()->odinString())
		os.exit(1)
	}
}
