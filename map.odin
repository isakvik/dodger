package dodger

import "core:math"
import "core:math/rand"

//playfield_from :: vec2{-172, -48}
//playfield_to :: vec2{684, 420}



playfield_from :: vec2{0,0}
playfield_to :: vec2{512,384}

global_sv_multiplier :: 0.598


rng_int :: proc(from, to: int) -> int { return int(rand.int_max(to) - from) }
rng_f64 :: proc(from, to: f64) -> f64 { return rand.float64_range(from, to) }
rng_angle :: proc() -> f64 { return rng_f64(0, 2*math.PI) }

global_seed :: u64(1)

start_pattern :: proc(seed: u64 = 0) {
    used_seed := global_seed if seed == 0 else seed
    rand.reset(used_seed)
    // create bookmark at time?
}


shotgun :: proc(pt: vec2, angle, spread, speed: f64) {

    greenline_add(speed)
    for i in 0..<5 {
        slider_from_angle(pt, angle + rng_f64(-spread, spread), osu_time())
    }
    advance_time(1)

    greenline_add(speed/3*2)
    for i in 0..<5 {
        slider_from_angle(pt, angle + rng_f64(-spread, spread), osu_time())
    }
    advance_time(1)

    greenline_add(speed/3)
    for i in 0..<5 {
        slider_from_angle(pt, angle + rng_f64(-spread, spread), osu_time())
    }
    advance_time(1)

}

ANGLE_RIGHT :: 0
ANGLE_UP :: math.PI/2
ANGLE_LEFT :: math.PI
ANGLE_DOWN :: math.PI/2*3


map_create :: proc() {

    start_pattern()

    shotgun({0, playfield_to.y/2}, ANGLE_RIGHT, math.PI/4, 1)

    advance_snap(1)
    advance_snap(1)
    advance_snap(1)
    advance_snap(1)

    /*
    it_angle := 2*math.PI / 25
    for i in 0..<25*4 {
        greenline_add(f64(i)*0.02 + 1)
        slider_from_angle({100,100}, it_angle+f64(i)*2*math.PI, osu_time())
        advance_snap(8)
    }
    */


    /* todos

        eye pattern
        outspiral - inspiral?
        walls
        sans (what did he mean by this?)
        shotgun

    */

}
