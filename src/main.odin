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
	fmt.println("Device: ", device->name()->odinString())

	// Create a Metal layer and assign to the window. 
	// When the window is displayed, the Metal layer will be used to render the content in the view.
	metal_layer := CA.MetalLayer.layer()
	defer metal_layer->release()
	metal_layer->setDevice(device)
	metal_layer->setPixelFormat(.BGRA8Unorm_sRGB) // why this format?
	native_window->contentView()->setLayer(metal_layer)

	//create triangle
	createTriangle(device)

	// Create Metal render pipeline
	metal_library := createLibraryFromSource(device) or_return
	command_queue := createCommandQueue(device)
	render_PSO := createRenderPipeline(device, metal_library, metal_layer) or_return


	SDL.ShowWindow(window)
	// While window open loop through events. Close on quit event.
	for quit := false; !quit; {
		for e: SDL.Event; SDL.PollEvent(&e); {
			#partial switch e.type {
			case .QUIT:
				quit = true
			}
		}
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
