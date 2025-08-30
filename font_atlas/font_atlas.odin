package main

import "core:fmt"
import "core:log"
import "core:os"
import "vendor:sdl3"
import img "vendor:sdl3/image"
import ttf "vendor:sdl3/ttf"

WINDOW_TITLE :: "Font atlas!"
WINDOW_WIDTH := i32(800)
WINDOW_HEIGHT := i32(600)
WINDOW_FLAGS :: sdl3.WindowFlags{}

CTX :: struct {
	window:       ^sdl3.Window,
	renderer:     ^sdl3.Renderer,
	should_close: bool,
}

ctx := CTX{}

NUM_GLYPH :: 256 // max number of glyph

Font_atlas :: struct {
	glyph:   [NUM_GLYPH]sdl3.Rect,
	texture: ^sdl3.Texture,
}

// This can hold multiple font atlas
Font_ctx :: struct {
	font: map[string]Font_atlas,
}

font_ctx := Font_ctx{}

draw_text :: proc(font: ^Font_atlas, text: string, x, y: i32, r, g, b: u8) {
	glyph_frect: sdl3.FRect // position of the glyph
	target_frect := sdl3.FRect {
		x = f32(x),
		y = f32(y),
	}
	sdl3.SetTextureColorMod(font.texture, r, g, b)
	for a_rune in text {
		glyph_rect := font.glyph[a_rune]
		sdl3.RectToFRect(glyph_rect, &glyph_frect)
		target_frect.w = glyph_frect.w
		target_frect.h = glyph_frect.h
		sdl3.RenderTexture(ctx.renderer, font.texture, &glyph_frect, &target_frect)
		target_frect.x += glyph_frect.w
	}

}

draw :: proc() -> bool {
	// Clear the screen
	sdl3.SetRenderDrawColor(ctx.renderer, 30, 80, 133, sdl3.ALPHA_OPAQUE)
	sdl3.RenderClear(ctx.renderer)

	arimo := font_ctx.font["Arimo 35"]
	tinos := font_ctx.font["Tinos 25"]
	draw_text(&arimo, "This is a RED line Arimo 35...", 10, 10, 255, 0, 0)
	draw_text(&tinos, "This is a GREEN line Tinos 25...", 10, 100, 0, 255, 0)
	sdl3.RenderPresent(ctx.renderer)

	return true
}

load_font :: proc(filename: cstring, size: f32, font_atlas: ^Font_atlas) -> (ok: bool) {
	ttf_font := ttf.OpenFont(filename, size)
	if ttf_font == nil {
		log.errorf("Error opening Font: %s", filename)
		return false
	}

	// setup the surface for the atlas 512x512
	texture_size := i32(512)
	surface := sdl3.CreateSurface(texture_size, texture_size, sdl3.PixelFormat.RGBA64)

	// set the key to get transparency
	sdl3.SetSurfaceColorKey(
		surface,
		true,
		sdl3.MapRGBA(
			sdl3.GetPixelFormatDetails(surface.format),
			sdl3.GetSurfacePalette(surface),
			0,
			0,
			0,
			0,
		),
	)
	color := sdl3.Color{255, 255, 255, 255} // white text

	dest := sdl3.Rect{} // The rect where to paint the glyph

	// generate the glyph from unicode 32 to 255 excluding some ranges
	for i in i32(32) ..< i32(256) {
		if (i > 126) & (i < 160) | (i == 173) do continue
		c := rune(i)
		if (dest.x + dest.w) > texture_size {
			dest.x = 0
			dest.y += dest.h + 1
			if (dest.y + dest.h) > texture_size {
				log.errorf("Atlas surface is too small")
				return false
			}
		}
		// generate surface for the Glyph 
		text_surface := ttf.RenderGlyph_Blended(ttf_font, u32(c), color)
		if text_surface == nil {
			log.errorf("Cannot render rune %w %d", c, i)
			continue // skip this rune
		}

		dest.w = text_surface.w
		dest.h = text_surface.h
		sdl3.BlitSurface(text_surface, nil, surface, &dest) // paint the glyph
		sdl3.DestroySurface(text_surface)

		g := &font_atlas.glyph[i]
		g.x = dest.x
		g.y = dest.y
		g.w = dest.w
		g.h = dest.h

		dest.x += dest.w // move to the next space

	}
	font_atlas.texture = sdl3.CreateTextureFromSurface(ctx.renderer, surface)
	return true
}

init_resources :: proc() -> bool {
	font_list := make(map[string]Font_atlas)

	font := Font_atlas{}
	res_loadfont := load_font("fonts/Arimo-Regular.ttf", 35, &font)
	if !res_loadfont {
		log.errorf("Error loading Arimo 35")
	}
	font_list["Arimo 35"] = font

	// if many fonts this could be a loop	
	font = Font_atlas{}
	res_loadfont = load_font("fonts/Tinos-Regular.ttf", 25, &font)
	if !res_loadfont {
		log.errorf("Error loading Tinos 25")
	}
	font_list["Tinos 25"] = font

	// set the list in the global context
	font_ctx.font = font_list
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

	if res_ttf := ttf.Init(); !res_ttf {
		log.errorf("Could not init TTF")
		return false
	}
	return true
}

cleanup :: proc() {
	ttf.Quit()

	// to clean
	sdl3.DestroyRenderer(ctx.renderer)
	sdl3.DestroyWindow(ctx.window)
	sdl3.Quit()
}

main :: proc() {
	context.logger = log.create_console_logger()
	if ok_init := init_sdl(); !ok_init {
		log.errorf("Initialization of SDL failed.")
		os.exit(1)
	}
	if ok_resources := init_resources(); !ok_resources {
		log.errorf("Initialization of resources failed.")
		os.exit(1)
	}
	defer cleanup()
	loop()
}

