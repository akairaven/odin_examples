package main

import "core:fmt"
import "core:log"
import "core:os"
import "vendor:sdl3"
import img "vendor:sdl3/image"

WINDOW_TITLE :: "SDL3 Hellope!"
WINDOW_WIDTH := i32(800)
WINDOW_HEIGHT := i32(600)
WINDOW_FLAGS :: sdl3.WindowFlags{}

CTX :: struct {
	window:       ^sdl3.Window,
	renderer:     ^sdl3.Renderer,
	should_close: bool,
}

ctx := CTX{}

init_sdl :: proc() -> (ok: bool) {
	if res_init := sdl3.Init(sdl3.INIT_VIDEO); !res_init {
		log.errorf("Could not init SDL3")
		return false
	}

	if res_window := sdl3.CreateWindowAndRenderer(
		WINDOW_TITLE,
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		WINDOW_FLAGS,
		&ctx.window,
		&ctx.renderer,
	); !res_window {
		log.errorf("Create Window and Renderer failed.")
		return false
	}

	return true
}

cleanup :: proc() {
	sdl3.DestroyRenderer(ctx.renderer)
	sdl3.DestroyWindow(ctx.window)
	sdl3.Quit()
}

draw :: proc() -> bool {
	// Clear the screen
	sdl3.SetRenderDrawColor(ctx.renderer, 30, 80, 133, sdl3.ALPHA_OPAQUE)
	sdl3.RenderClear(ctx.renderer)

	image := img.Load("logo-slim.png")

	image_texture := sdl3.CreateTextureFromSurface(ctx.renderer, image)

	t_rect := sdl3.FRect {
		x = 100,
		y = 100,
		w = f32(image.w) / 2,
		h = f32(image.h) / 2,
	}
	sdl3.RenderTexture(ctx.renderer, image_texture, nil, &t_rect)

	// show on screen
	sdl3.RenderPresent(ctx.renderer)

	// cleanup
	sdl3.DestroySurface(image)
	sdl3.DestroyTexture(image_texture)
	return true
}

process_input :: proc() {
	event: sdl3.Event
	for sdl3.PollEvent(&event) {
		#partial switch (event.type) {
		case .QUIT:
			ctx.should_close = true
		case .KEY_DOWN:
			#partial switch (event.key.scancode) {
			case .ESCAPE:
				fmt.printf("Escape pressed\n")
				ctx.should_close = true
			case .UP:
				fmt.printf("Up pressed\n")
			}
		}
	}
}

loop :: proc() {
	for !ctx.should_close {
		process_input()
		if err := draw(); !err {
			ctx.should_close = true
		}
		sdl3.Delay(10)
	}
}

main :: proc() {
	context.logger = log.create_console_logger()
	if ok := init_sdl(); !ok {
		log.errorf("Initialization failed.")
		os.exit(1)
	}
	defer cleanup()
	loop()
}

