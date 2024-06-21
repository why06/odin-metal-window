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
		854,
		480,
		{.ALLOW_HIGHDPI, .HIDDEN, .RESIZABLE},
	)

	return window, cleanupMetalWindow
}

cleanupMetalWindow :: proc(window: ^SDL.Window) {
	SDL.DestroyWindow(window)
	SDL.Quit()
}
