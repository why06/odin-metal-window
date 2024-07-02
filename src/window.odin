package main
import "core:fmt"
import SDL "vendor:sdl2"

createMetalWindow :: proc() -> (^SDL.Window, proc(window: ^SDL.Window)) {
	SDL.SetHint(SDL.HINT_RENDER_DRIVER, "metal")
	SDL.setenv("METAL_DEVICE_WRAPPER_TYPE", "1", 0)
	SDL.Init({.VIDEO})

	window := SDL.CreateWindow(
		"My Metal Window",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		800,
		600,
		{.ALLOW_HIGHDPI, .HIDDEN, .RESIZABLE},
	)

	return window, cleanupMetalWindow
}

cleanupMetalWindow :: proc(window: ^SDL.Window) {
	SDL.DestroyWindow(window)
	SDL.Quit()
}


quit_window := false
// Poll for events
pollEvents :: proc(window: ^SDL.Window) {
	w, h: i32
	for e: SDL.Event; SDL.PollEvent(&e); {
		#partial switch e.type {
		case .WINDOWEVENT:
			{
				#partial switch e.window.event {
				case .RESIZED:
					fmt.println("Event: ", e.window.event)
					fmt.println("Window resized: ", e.window.data1, "x", e.window.data2)
					SDL.Metal_GetDrawableSize(window, &w, &h)
					fmt.println("Drawable resized: ", w, "x", h)

				}
			}
		case .QUIT:
			quit_window = true
		}
	}
}
