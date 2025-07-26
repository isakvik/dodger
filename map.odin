package dodger

import "core:fmt"
import "core:math"
import "core:math/rand"


//////////////////////////////////////////////////////
// utils

//pf_from :: vec2{-172, -48}
//pf_to :: vec2{684, 420}


map_velocity :: f64(2)
circle_radius :: f64(54.4 - 4.48 * 4.0)

//pf_from :: [2]f64{-circle_radius,-circle_radius}
//pf_to :: [2]f64{512+circle_radius,384+circle_radius}
//global_sv_multiplier :: 0.598*1.1775

pf_from :: [2]f64{0,0}
pf_to :: [2]f64{512,384}
global_sv_multiplier :: 0.598

pf_center :: [2]f64{pf_to[0]/2+pf_from[0]/2,pf_to[1]/2+pf_from[1]/2}



rng_int :: proc(from, to: int) -> int { return int(rand.int_max(to) - from) }
rng_f64 :: proc(from, to: f64) -> f64 { return rand.float64_range(from, to) }
rng_angle :: proc() -> f64 { return rng_f64(0, 2*math.PI) }

global_seed :: u64(1)

start_pattern :: proc(seed: u64 = 0) {
    used_seed := global_seed if seed == 0 else seed
    rand.reset(used_seed)
    // create bookmark at time?
}


angle_full :: 2*math.PI
angle_right :: 0
angle_down :: math.PI/2
angle_left :: math.PI
angle_up :: math.PI/2*3

angle_down_right :: (angle_down+angle_right)/2
angle_down_left :: (angle_down+angle_left)/2

angle_up_right :: (angle_up+angle_right)/2
angle_up_left :: (angle_up+angle_left)/2




top_left        :: [2]f64{0, 0}
top_middle      :: [2]f64{pf_center[0], 0}
top_right       :: [2]f64{pf_to[0], 0}
middle_left     :: [2]f64{0, pf_center[1]}
center          :: pf_center
middle_right    :: [2]f64{pf_to[0], pf_center[1]}
bottom_left     :: [2]f64{0, pf_to[1]}
bottom_middle   :: [2]f64{pf_center[0], pf_to[1]}
bottom_right    :: [2]f64{pf_to[0], pf_to[1]}

almost_top_left        := [2]f64{1, 1} + top_left
almost_top_middle      := [2]f64{0, 1} + top_middle
almost_top_right       := [2]f64{-1, 1} + top_right
almost_middle_left     := [2]f64{1,  0} + middle_left
almost_middle_right    := [2]f64{-1, 0} + middle_right
almost_bottom_left     := [2]f64{1, -1} + bottom_left
almost_bottom_middle   := [2]f64{0, -1} + bottom_middle
almost_bottom_right    := [2]f64{-1,-1} + bottom_right

to_rad :: proc(angle_deg: f64) -> f64 {
    return (angle_deg * 2*math.PI) / 360
}



//////////////////////////////////////////////////////
// map generators

spellcard_1 :: proc() {
    start_pattern(1)

    full_circle_count := 16
    hole_count := 4

    greenline_add(0.6)

    hole_angle := f64(0)
    hole_it_angle := 2*math.PI / f64(12)
    it_angle := 2*math.PI / f64(full_circle_count)

    for c in 0..<32 {

        launcher_pos := center - unit_circle(hole_angle) * 40

        circles := full_circle_count-hole_count
        for i in 0..<circles {
            open_angle := hole_angle + it_angle * f64(hole_count) / 2
            slider_from_angle(launcher_pos, f64(i)*it_angle + open_angle)
        }

        if c < 16 {
            hole_angle += hole_it_angle
        } else {
            hole_angle -= hole_it_angle
        }

        advance_snap(2)
    }
}

spellcard_2 :: proc() {
    start_pattern(5)
    greenline_add(1)

    // advance here cuz this starts with reverse
    advance_snap(1,3)

    angle := angle_up
    it_angle := 2*math.PI / 16

    for v in 0..<30 {
        i := f64(v)
        reversed_group_start()
        spread_shot(center, angle + it_angle * i, math.PI/2, 5)
        spread_shot(center, math.PI + angle + it_angle * i, math.PI/2, 5)
        reversed_group_end()

        if v == 16 { it_angle *= -1 }

        if v % 2 == 0 && v < 28 {
            advance_snap(2)
            greenline_add(0.4)
            circle(center, angle_right + rng_f64(0,angle_full), 7)
            advance_time(2)
            greenline_add(1)
            advance_snap(2)

            // vurder å bytte denne med regular circle
        }
        else {
            advance_snap(1)
        }
    }
}


spread_shot :: proc(pt: [2]f64, angle, spread: f64, num: int) {
    it_angle, used_angle: f64

    if num < 2 {
        it_angle = 0
        used_angle = angle
    } else {
        it_angle = spread / f64(num-1)
        used_angle = angle - it_angle * f64(num-1)/2
    }

    for i in 0..<num {
        slider_from_angle(pt, used_angle + f64(i)*it_angle)
    }

}

wall :: proc(pt: [2]f64, angle, spacing: f64, num: int) {
    it_space := unit_circle(angle + math.PI/2) * spacing
    start_pt := pt - it_space * f64(num-1)/2
    for i in 0..<num {
        slider_from_angle(start_pt + it_space * f64(i), angle)
    }

}

wall_from :: proc(pt: [2]f64, angle, angle_to, spacing: f64, num: int) {
    it_space := unit_circle(angle_to) * spacing
    for i in 0..<num {
        slider_from_angle(pt + it_space * f64(i), angle)
    }
}

wall_from_wait :: proc(pt: [2]f64, angle, angle_to, spacing: f64, num, wait: int) {
    it_space := unit_circle(angle_to) * spacing
    for i in 0..<num {
        slider_from_angle(pt + it_space * f64(i), angle)
        advance_time(wait)
    }
}

shotgun :: proc(pt: [2]f64, angle, spread, speed: f64, num: int) {

    for i in 0..<num {
        greenline_add(rng_f64(speed/3, speed))
        slider_from_angle(pt, angle + rng_f64(-spread/2, spread/2))
        advance_time(2)
    }

}

shotgun_2 :: proc(pt: [2]f64, angle, spread, speed, min_speed_factor: f64, num: int) {

    for i in 0..<num {
        greenline_add(rng_f64(min_speed_factor * speed, speed))
        slider_from_angle(pt, angle + rng_f64(-spread/2, spread/2))
        advance_time(2)
    }

}


circle :: proc(pt: [2]f64, angle: f64, num: int) {
    it_angle := 2*math.PI / f64(num)
    for i in 0..<num {
        slider_from_angle(pt, angle + it_angle*f64(i))
    }
}


hexgrid_cover :: proc() {
    x := f64(0)
    y := f64(0)
    counter := 0
    for x < f64(pf_to.x) {
        add := counter % 2 == 1 ? (circle_radius*2 - 18) / 2 : 0
        for y < f64(pf_to.y) {
            circle_add({x, y + add})
            y += circle_radius*2 - 18
        }
        x += circle_radius*2 - 20
        y = 0
        counter += 1
        advance_snap(2)
    }
}


lerp :: proc(a, b, v: f64) -> f64 {
    return (b - a) * v + a
}

ellipse :: proc(pt: [2]f64, angle, long_speed, short_speed: f64, num: int) {
    using math

    it_angle := 2*PI / f64(num)

    v := 0
    for v < num/2 {
        i := f64(v)

        t := angle + it_angle*i

        x := long_speed * cos(t)
        y := short_speed * sin(t)

        angle_speed := sqrt(pow(x,2) + pow(y,2))

        greenline_add(angle_speed)
        fmt.println(angle_speed)

        slider_from_angle(pt, t)
        slider_from_angle(pt, t + angle_left)
        advance_time(1)

        v += 1
    }

    //assert(false)
}


//////////////////////////////////////////////////////
// map

map_create :: proc() {

    intro()

    circle_add(center)
    greenline_add(1.1)

    i := f64(0)
    snap := 4
    for v in 0..<60 {
        ellipse(center, to_rad(i * 7), 1.2, 0.9,  4)
        advance_snap(snap)

        if v < snap*2*2 {
            i += 1
        }
        else if v < snap*2*4 {
            i -= 1
        }
        else if v < snap*2*5-1 {
            i += 2
        }
        else if v < snap*2*6-1 {
            i -= 3
        }
        else if v < snap*2*7-1 {
            i -= 5
        }
        else if v < snap*2*8-1 {
            i += 4
        }
    }

    greenline_add(0.6)
    advance_snap(1)


    advance_snap(1, 4)

    for v in 0..<11 {
        star := 5
        i := f64(v)
        reversed_group_start()
        circle(center, to_rad(i*13) + to_rad(180/f64(star)), star)
        reversed_group_end()

        circle(center, to_rad(i*13), star)

        advance_snap(1)

        if v == 0 || v == 6 {
            advance_time(1)
            shotgun(center, 0, angle_full, 0.4, 8)
            advance_time(1)
            greenline_add(0.6)
        }

    }
    advance_snap(1)

    {
        greenline_add(1.5)
        it_pos := [2]f64{pf_to[0] / 9, 0}

        slider_from_angle(top_left + it_pos * 0, angle_down); advance_snap(2)
        slider_from_angle(top_left + it_pos * 1, angle_down); advance_snap(2)
        slider_from_angle(top_left + it_pos * 2, angle_down); advance_snap(4)
        slider_from_angle(top_left + it_pos * 3, angle_down); advance_snap(4)
        slider_from_angle(top_left + it_pos * 4, angle_down); advance_snap(4)
        slider_from_angle(top_left + it_pos * 5, angle_down); advance_snap(4)
        slider_from_angle(top_left + it_pos * 6, angle_down); advance_snap(2)
        slider_from_angle(top_left + it_pos * 7, angle_down); advance_snap(2)
        slider_from_angle(top_left + it_pos * 8, angle_down); advance_snap(2)
        slider_from_angle(top_left + it_pos * 9, angle_down); advance_snap(2)
        slider_from_angle(bottom_left + it_pos * 0, angle_up); advance_snap(2)
        slider_from_angle(bottom_left + it_pos * 1, angle_up); advance_snap(2)
        slider_from_angle(bottom_left + it_pos * 2, angle_up); advance_snap(4)
        slider_from_angle(bottom_left + it_pos * 3, angle_up); advance_snap(4)
        slider_from_angle(bottom_left + it_pos * 4, angle_up); advance_snap(4)
        slider_from_angle(bottom_left + it_pos * 5, angle_up); advance_snap(4)
        slider_from_angle(bottom_left + it_pos * 6, angle_up); advance_snap(2)
        slider_from_angle(bottom_left + it_pos * 7, angle_up); advance_snap(2)
        slider_from_angle(bottom_left + it_pos * 8, angle_up); advance_snap(2)
        slider_from_angle(bottom_left + it_pos * 9, angle_up); advance_snap(2)

        wait := 10
        wall_from_wait(bottom_left, angle_right, angle_up, circle_radius * 2 - 30, 5, wait); advance_snap(2, 3)
        wall_from_wait(top_left, angle_right, angle_down, circle_radius * 2 - 30, 5, wait); advance_snap(2, 2)
        greenline_add(1.6)
        wall_from_wait(bottom_left, angle_right, angle_up, circle_radius * 2 - 30, 5, wait*2); advance_snap(2)
        wall_from_wait(top_left, angle_right, angle_down, circle_radius * 2 - 30, 5, wait*2); advance_snap(2,2)
    }

    advance_snap(-1, 12)
    for v in 0..<16 {
        i := f64(v)
        advance_time(1)
        greenline_add(0.8)

        ang := to_rad(5 - i)

        spread_shot(top_left + {1,i*4}, angle_right+ang, ang, 2)

        spread_shot(bottom_right - {1,i*4}, angle_left+ang, ang, 2)
        advance_time(1)
        greenline_add(1.5)
        advance_snap(1)
    }

    advance_snap(-1, 4)

    {
        pt := [2]f64{0, pf_to[1] * 0.7 + pf_to[1] * 0.15}
        it_pos := [2]f64{0, pf_to[1] * 0.7 / 7}
        poses: [7][2]f64
        for i in 0..<7 { poses[i] = pt - it_pos * f64(i) }

        slider_from_angle(poses[1], angle_right); advance_snap(2)
        slider_from_angle(poses[6], angle_right); advance_snap(4)
        slider_from_angle(poses[5], angle_right); advance_snap(4)
        slider_from_angle(poses[4], angle_right); advance_snap(2)
        slider_from_angle(poses[1], angle_right); advance_snap(4)
        slider_from_angle(poses[2], angle_right); advance_snap(4)
        slider_from_angle(poses[3], angle_right); advance_snap(2)
        slider_from_angle(poses[6], angle_right); advance_snap(2)
        slider_from_angle(poses[4], angle_right); advance_snap(2)
        //wall_from(top_left, angle_right, angle_down, circle_radius * 2 - 30, 5)
    }

    advance_snap(2)

    swords()

    spellcard_2()

    advance_snap(-1)
    greenline_add(1.5)

    {
        wait := 20
        
        shotgun(bottom_right, angle_up_left, 0, 1, 3)
        advance_time(1)
        greenline_add(1.5)

        for i in 0..<4 {

            wall_from_wait(bottom_left, angle_right, angle_up, pf_to[1] / (2*5), 6, wait)
            advance_snap(1)
            wall_from_wait(top_right, angle_left, angle_down, pf_to[1] / (2*5), 6, wait)
            advance_snap(1)
        }

        for i in 0..<4 {
            greenline_add(1.0)
            slider_from_angle({ pf_to[0] * 0.6, 0 }, angle_down)
            slider_from_angle({ pf_to[0] * 0.4, pf_to[1] }, angle_up)
            advance_time(1)
            greenline_add(1.5)

            greenline_add(1.5)
            wall_from_wait(top_left, angle_right, angle_down, pf_to[1] / (2*5), 6, wait)
            advance_snap(1)
            wall_from_wait(bottom_right, angle_left, angle_up, pf_to[1] / (2*5), 6, wait)
            advance_snap(1)
        }
    }




    /* todos

        eye pattern
        outspiral - inspiral?
        walls
        sans (what did he mean by this?)
        shotgun

        VVV shots
        spiral super hexagon like, with random adds

        hitcircles som visual cue... kan fungere som introduksjon / ramp up

    */

}



intro :: proc() {

    start_pattern()
    greenline_add(0.9)

    lpos := top_left
    rpos := top_right
    circle_add(lpos)
    circle_add(rpos)

    for v in 0..=4 {
        i := f64(v)
        slider_from_angle(lpos + { pf_to[0] / 8, 0 } * f64(i), angle_down)
        if v != 4 {
            slider_from_angle(rpos - { pf_to[0] / 8, 0 } * f64(i), angle_down)
        }
        advance_snap(1)
    }

    advance_snap(1,1)
    spread_shot(top_middle, angle_down, to_rad(150),5)

    advance_snap(1,2)

    lpos = bottom_left
    rpos = bottom_right

    greenline_add(1.0)
    advance_snap(1, 4)
    for v in 0..=4 {
        i := f64(v)
        slider_from_angle(lpos + { pf_to[0] / 8, 0 } * f64(i), angle_up)
        if v != 4 {
            slider_from_angle(rpos - { pf_to[0] / 8, 0 } * f64(i), angle_up)
        }
        advance_snap(-1)
    }
    advance_snap(1, 6)
    advance_snap(2)

    greenline_add(0.95)
    spread_shot(lpos, (angle_up*1.1+angle_full*0.9)/2, to_rad(75),5)
    spread_shot(rpos, (angle_up*1.1+angle_left*0.9)/2, to_rad(75),5)

    advance_snap(2)
    advance_snap(1,2)

    circle(bottom_middle-{0,1}, 4, 5); advance_snap(1)
    circle(bottom_middle-{0,1}, 5, 5); advance_snap(1)
    circle(bottom_middle-{0,1}, 6, 5); advance_snap(1)
    circle(bottom_middle-{0,1}, 7, 5); advance_snap(1)
    circle(bottom_middle-{0,1}, 8, 5); advance_snap(1)

    advance_snap(1,1)

    circle_add(bottom_middle-{0,1})
    circle_add(top_middle+{0,1})
    circle(bottom_middle-{0,1}, to_rad(360/26), 12)
    circle(top_middle+{0,1}, to_rad(360/26), 12)

    advance_snap(1,2)

    for v in 0..=4 {
        circle(bottom_middle-{0,1}, to_rad(f64(v)*15), 9)
        advance_snap(1)
    }

    advance_snap(2)

    circle_add(middle_left+{1,0})
    circle_add(middle_right-{1,0})
    circle(middle_left+{1,0}, to_rad(360/26), 12)
    circle(middle_right-{1,0}, to_rad(360/26), 12)

    advance_snap(2)
    advance_snap(1,2)

    //wall(middle_left, angle_right, circle_radius*2-4, 1)

    start_pattern()

    {
        circle_add(top_middle)

        for v in 1..=5 {
            i := f64(v)
            greenline_add(0.8 + i/20)
            spread_shot(top_middle, angle_down, to_rad(40*(i-1)), v)
            advance_snap(1)
        }

        advance_snap(1)

        lpos := top_left + {20,0}
        rpos := top_right - {20,0}
        circle_add(lpos)
        circle_add(rpos)

        slider_from_angle(lpos, angle_down-to_rad(2))
        slider_from_angle(rpos, angle_down+to_rad(2))
        shotgun(lpos, (angle_down_right), to_rad(65), 1, 5)
        shotgun(rpos, (angle_down_left), to_rad(65), 1, 5)

        advance_snap(1,2)
    }


    start_pattern(3)

    {
        lpos := top_left + {50,0}
        rpos := top_right - {50,0}
        circle_add(lpos)
        circle_add(rpos)

        it_angle := to_rad(10)
        init_angle := angle_down

        for v in 0..<5 {
            i := f64(v)
            greenline_add(0.8 + i/20)
            spread_shot(lpos, init_angle + to_rad(10) - it_angle * i, to_rad(30*(i)), (v+1))
            spread_shot(rpos, init_angle - to_rad(10) + it_angle * i, to_rad(30*(i)), (v+1))
            advance_snap(1)
        }
    }

    advance_snap(2)
    shotgun(bottom_middle, angle_up, math.PI, 1, 20)
    advance_snap(2)

    advance_snap(1, 2)

    circle_add(bottom_right-{1,1})
    circle(bottom_right-{1,1}, to_rad(5), 15)
    advance_snap(1)
    circle_add(top_right+{-1,1})
    circle(top_right+{-1,1}, to_rad(10), 15)
    advance_snap(1)
    circle_add(top_left+{1,1})
    circle(top_left+{1,1}, to_rad(15), 15)
    advance_snap(1)
    circle_add(bottom_left+{1,-1})
    circle(bottom_left+{1,-1}, to_rad(24), 15)
    advance_snap(1)

    circle_add(center)
    circle(center, to_rad(30), 8)

    advance_snap(1,2)

    greenline_add(0.8)
    spread_shot(top_middle, angle_down, to_rad(170), 4)
    spread_shot(bottom_middle, angle_up, to_rad(170), 4)

    advance_snap(1, 2)

    start_pattern()

    for v in 1..=4 {
        i := f64(v)
        spread_shot(top_middle + {0,1}, angle_left, to_rad(20*i), v)
        spread_shot(top_middle + {0,1}, angle_right, to_rad(20*i), v)

        spread_shot(bottom_middle - {0,1}, angle_left, to_rad(20*i), v)
        spread_shot(bottom_middle - {0,1}, angle_right, to_rad(20*i), v)
        advance_snap(1, 1)
    }


    start_pattern(2)

    shotgun(middle_left, angle_right, math.PI/3, 1.5, 8)
    advance_snap(1, 1)
    advance_snap(2)
    shotgun(middle_right, angle_left, math.PI/3, 1.5, 8)

    advance_snap(2)
    advance_snap(1,2)
}


swords :: proc() {


    {
        advance_time(3)
        shotgun(top_middle, angle_down, to_rad(170), 0.7, 4)
        advance_time(1)
        for v in 0..<10 {
            i := f64(v)
            it_angle := to_rad(8)
            t := it_angle * i
            shotgun_2(top_left + {150, 0}, (angle_down + it_angle*5) - t, to_rad(10), 1.5, 0.7, 2)
            advance_snap(8)
        }

        shotgun(top_middle, angle_down, to_rad(170), 0.7, 4)

        advance_snap(8,6)

        for v in 0..<10 {
            i := f64(v)
            it_angle := to_rad(8)
            t := it_angle * i
            shotgun_2(top_right - {150, 0}, (angle_down - it_angle*5) + t, to_rad(10), 1.5, 0.7, 2)
            advance_snap(8)
        }

        shotgun(top_middle, angle_down, to_rad(170), 0.7, 2)

        advance_snap(8,6)

        for v in 0..<10 {
            i := f64(v)
            it_angle := to_rad(8)
            t := it_angle * i
            shotgun_2(top_left + {150, 0}, (angle_down - it_angle*4) + t, to_rad(10), 1.1, 0.7, 2)
            advance_snap(8)
        }

        shotgun(top_middle, angle_down, to_rad(170), 0.7, 2)

        advance_snap(8,6)

        for v in 0..<10 {
            i := f64(v)
            it_angle := to_rad(8)
            t := it_angle * i
            shotgun_2(top_right - {150, 0}, (angle_down + it_angle*4) - t, to_rad(10), 1.1, 0.7, 2)
            advance_snap(8)
        }

        shotgun(top_middle, angle_down, to_rad(170), 0.7, 5)
        advance_snap(8,6)

        for v in 0..<10 {
            i := f64(v)
            it_angle := to_rad(8)
            t := it_angle * i
            shotgun_2(top_left + {150, 0}, (angle_down + it_angle*7) - t, to_rad(10), 1.2, 0.7, 2)
            advance_snap(8)
        }

        shotgun(top_middle, angle_down, to_rad(170), 0.7, 2)

        advance_snap(8,6)

        for v in 0..<10 {
            i := f64(v)
            it_angle := to_rad(8)
            t := it_angle * i
            shotgun_2(top_right - {150, 0}, (angle_down - it_angle*7) + t, to_rad(10), 1.2, 0.7, 2)
            advance_snap(8)
        }

        advance_snap(8,6)

        for v in 0..<10 {
            i := f64(v)
            it_angle := to_rad(4)
            t := it_angle * i
            shotgun_2(top_middle, (angle_down) + (v%2==0? t : -t), to_rad(10), 1.2, 0.7, 2)
            advance_snap(8)
        }

        advance_snap(8,6)

        for v in 0..<12 {
            i := f64(12 - v)
            it_angle := to_rad(4)
            t := it_angle * i
            shotgun_2(bottom_middle, (angle_up) + (v%2==0? t : -t), to_rad(10), 1.2, 0.7, 2)
            advance_snap(8)
        }

        advance_snap(8,4)
    }
}
