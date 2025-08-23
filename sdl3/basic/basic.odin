package main

import "core:fmt"
import "core:log"
import "core:os"
import "vendor:sdl3"

WINDOW_TITLE :: "SDL Hellope!"
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
	if init_res := sdl3.Init(sdl3.INIT_VIDEO); !init_res {
		log.errorf("Could not init :  %v.", init_res)
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

	log.infof("SDL is using %v", sdl3.GetRendererName(ctx.renderer))
	log.info("Available renderers:")
	for i in 0 ..< sdl3.GetNumRenderDrivers() {
		log.infof("%d -> %v", i, sdl3.GetRenderDriver(i))
	}
	return true
}

cleanup :: proc() {
	sdl3.DestroyRenderer(ctx.renderer)
	sdl3.DestroyWindow(ctx.window)
	sdl3.Quit()
}

draw :: proc() {
	sdl3.SetRenderScale(ctx.renderer, 1.0, 1.0)
	sdl3.SetRenderDrawColor(ctx.renderer, 255, 0, 0, 255)
	sdl3.RenderClear(ctx.renderer)

	sdl3.SetRenderDrawColor(ctx.renderer, 50, 50, 50, 255)

	rect := sdl3.FRect{}
	rect.x = 35
	rect.y = 35
	rect.w = 400
	rect.h = 40
	sdl3.RenderFillRect(ctx.renderer, &rect)

	sdl3.SetRenderDrawColor(ctx.renderer, 255, 255, 255, sdl3.ALPHA_OPAQUE)
	sdl3.SetRenderScale(ctx.renderer, 4.0, 4.0)
	sdl3.RenderDebugText(ctx.renderer, 10, 10, "Hello world!")

	sdl3.RenderPresent(ctx.renderer)
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
				fmt.printf("Escape")
				ctx.should_close = true
			case .UP:
				fmt.printf("Up")
			}

		}
	}
}

loop :: proc() {
	for !ctx.should_close {
		process_input()
		draw()
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

