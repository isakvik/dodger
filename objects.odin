package dodger

import "core:fmt"
import "core:math"
import "core:strings"


//////////////////////////////////////////////////////
// math

vec2 :: struct {
    x: int,
    y: int
}

to_vec2 :: proc(v: [2]f64) -> vec2 {
    return {int(v[0]),int(v[1])}
}

to_vec2_f64 :: proc(v: vec2) -> [2]f64 {
    return {f64(v.x), f64(v.y)}
}

segment :: struct {
    from: [2]f64,
    to: [2]f64
}

vec2_dist :: proc(from: vec2, to: vec2) -> f64 {
    return math.sqrt(math.pow(f64(to.x - from.x), 2) + math.pow(f64(to.y - from.y), 2))
}

vec2_cross :: proc(a: [2]f64, b: [2]f64) -> f64 {
    return a.x*b.y - a.y*b.x
}

vec2_orient :: proc(a: [2]f64, b: [2]f64, c: [2]f64) -> f64 {
    return vec2_cross({b.x-a.x, b.y-a.y}, {c.x-a.x, c.y-a.y})
}


segment_intersect :: proc(a: segment, b: segment) -> ([2]f64, bool) {
    oa := vec2_orient(b.from, b.to, a.from)
    ob := vec2_orient(b.from, b.to, a.to)
    oc := vec2_orient(a.from, a.to, b.from)
    od := vec2_orient(a.from, a.to, b.to)
    out := [2]f64{0,0}

    if (oa*ob < 0 && oc*od < 0) {
        out = (a.from*ob - a.to*oa) / (ob-oa);
        return out, true
    }

    return out, false
}


segment_from_angle :: proc(pt: vec2, angle_rad: f64) -> segment {
    pt_f64 := [2]f64{f64(pt.x), f64(pt.y)}

    // 1000 just to cover the playfield
    return segment{ pt_f64, {pt_f64.x + math.cos(angle_rad) * 1000, pt_f64.y + math.sin(angle_rad) * 1000} }
}


//////////////////////////////////////////////////////
// objects

SliderNodeType :: enum { Linear }

SliderNode :: struct {
    pos: vec2
}

//x,y,time,type,hitSound,curveType|curvePoints,slides,length,edgeSounds,edgeSets,hitSample
Slider :: struct {
    pos: vec2,
    time: int,
    nodeCount: int,
    firstNodeIndex: int,
    length: int, // visual length
}


//time,beatLength,meter,sampleSet,sampleIndex,volume,uninherited,effects
GreenLine :: struct {
    time: int,
    velocityMultiplier: int // negative percentage
}

greenline_add :: proc(sliderVelocityMultiplier: f64) {
    value: int
    value = int(math.round(100 / (sliderVelocityMultiplier * global_sv_multiplier))) * -1

    greenline := &greenline_buf[greenline_count]
    greenline.time = osu_time()
    greenline.velocityMultiplier = value

    greenline_count += 1
}


//////////////////////////////////////////////////////
// slider api

slider_addNode :: proc(slider: ^Slider, pos: vec2) {
    node := &node_buf[node_count]
    node.pos = pos
    slider.nodeCount += 1
    node_count += 1
}


slider_from_to :: proc(from: vec2, to: vec2, time: int) -> ^Slider {
    slider := slider_begin(from, time)
    slider_addNode(slider, to)
    slider_end(slider, vec2_dist(from, to))
    return slider
}


slider_guard := false

slider_begin :: proc(pos: vec2, time: int) -> ^Slider {
    assert(!slider_guard)
    slider_guard = true

    slider := &slider_buf[slider_count]

    slider.pos = pos
    slider.time = time
    slider.firstNodeIndex = node_count

    return slider
}

slider_end :: proc(slider: ^Slider, length: f64) {
    assert(slider.nodeCount > 0)
    slider_guard = false
    slider_count += 1

    slider.length = int(math.round(length))
}

slider_from_angle :: proc(start_pt: vec2, angle_rad: f64, time: int) {
    seg := segment_from_angle(start_pt, angle_rad)

    playfield_tl := to_vec2_f64(playfield_from)
    playfield_tr := to_vec2_f64(vec2{playfield_to.x, playfield_from.y})
    playfield_bl := to_vec2_f64(vec2{playfield_from.x, playfield_to.y})
    playfield_br := to_vec2_f64(playfield_to)

    end_pt, found := segment_intersect(seg, segment{playfield_tl - {1,0}, playfield_tr + {1,0}})
    if !found {
        end_pt, found = segment_intersect(seg, segment{playfield_bl - {1,0}, playfield_br + {1,0}})
    }
    if !found {
        end_pt, found = segment_intersect(seg, segment{playfield_tl - {0,1}, playfield_bl + {0,1}})
    }
    if !found {
        end_pt, found = segment_intersect(seg, segment{playfield_tr - {0,1}, playfield_br + {0,1}})
    }

    if found {
        slider_from_to(start_pt, to_vec2(end_pt), time)
    } else {
        fmt.printfln("no intersection found, start {}:{}, angle {}", start_pt.x, start_pt.y, angle_rad)
    }
}


//////////////////////////////////////////////////////
// time handling

current_time := f64(300)
current_beat_16ths := 0

unbeated_time_ms := 0

beat_len :: 416.666666667

osu_time :: proc() -> int { return int(math.round_f64(current_time)) }

advance_snap :: proc(snap_divisor: int) -> int {
    time_before := osu_time() - int(unbeated_time_ms)
    advance := f64(beat_len) / f64(snap_divisor)
    current_time += advance
    unbeated_time_ms = 0

    current_beat_16ths = (current_beat_16ths + snap_divisor / 16) % 16

    return osu_time() - time_before
}

advance_time :: proc(time_ms: int) {
    current_time += f64(time_ms)
    unbeated_time_ms += time_ms
}

advance_to_next :: proc(snap_divisor: int) -> int {
    // todo buggy with divisor 1/16
    if snap_divisor == 1 && current_beat_16ths == 0 { current_beat_16ths = 16 }

    cum := 0
    for current_beat_16ths > 0 {
        cum += advance_snap(16)
    }
    return cum
}
