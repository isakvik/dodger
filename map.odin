package dodger

import "core:math"

//playfield_from :: vec2{-172, -48}
//playfield_to :: vec2{684, 420}



playfield_from :: vec2{0,0}
playfield_to :: vec2{512,320}

global_sv_multiplier :: 0.598

//1.671875

map_create :: proc() {
    greenline_add(2)

    //slider_from_to(playfield_from, playfield_to, osu_time())

    slider_from_to(playfield_from, vec2_w(playfield_from, 0), osu_time())
}
