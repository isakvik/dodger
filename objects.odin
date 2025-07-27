package dodger

import "core:fmt"
import "core:math"
import "core:strings"


//////////////////////////////////////////////////////
// math

segment :: struct {
    from: [2]f64,
    to: [2]f64
}

vec2_dist :: proc(from, to: [2]f64) -> f64 {
    return math.sqrt(math.pow(f64(to.x - from.x), 2) + math.pow(f64(to.y - from.y), 2))
}

vec2_cross :: proc(a, b: [2]f64) -> f64 {
    return a[0]*b[1] - a[1]*b[0]
}

vec2_orient :: proc(a, b, c: [2]f64) -> f64 {
    return vec2_cross({b[0]-a[0], b[1]-a[1]}, {c[0]-a[0], c[1]-a[1]})
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



unit_circle :: proc(angle_rad: f64) -> [2]f64 {
    return { math.cos(angle_rad), math.sin(angle_rad) }
}

segment_from_angle :: proc(pt: [2]f64, angle_rad: f64) -> segment {
    // 1000 just to cover the playfield
    return segment{ pt, pt + (unit_circle(angle_rad) * 1000) }
}


//////////////////////////////////////////////////////
// objects

ReversedSliderGroup :: struct {
    startTime: int,
    longestSliderDuration: f64,
    velocity: f64
}

SliderNodeType :: enum { Linear }

SliderNode :: struct {
    pos: [2]f64
}

//x,y,time,type,hitSound,curveType|curvePoints,slides,length,edgeSounds,edgeSets,hitSample
Slider :: struct {
    pos: [2]f64,
    time: int,
    nodeCount: int,
    firstNodeIndex: int,
    length: int, // visual length

    reversed: bool,
    reversedGroup: int
}

//x,y,time,type,wtf,hitSound
Circle :: struct {
    pos: [2]f64,
    time: int,
}

circle_add :: proc(pos: [2]f64) {
    if true { return } // this is buggy lol

    circle := &circle_buf[circle_count]
    circle.pos = pos
    circle.time = osu_time()

    circle_count += 1
}


//time,beatLength,meter,sampleSet,sampleIndex,volume,uninherited,effects
GreenLine :: struct {
    time: int,
    velocityMultiplier: int // negative percentage
}

last_greenline_added_velocity := f64(1.0)

greenline_add :: proc(sliderVelocityMultiplier: f64) {
    velocity := sliderVelocityMultiplier * global_sv_multiplier
    value := int(math.round(100 / velocity)) * -1

    greenline := &greenline_buf[greenline_count]
    greenline.time = osu_time()
    greenline.velocityMultiplier = value

    greenline_count += 1
    last_greenline_added_velocity = velocity
}


current_reversed_group := 0

reversed_group_start :: proc() {
    assert(current_reversed_group == 0)
    reversed_count += 1

    reversed_group := &reversed_buf[reversed_count]
    reversed_group.velocity = last_greenline_added_velocity

    current_reversed_group = reversed_count
}

reversed_group_end :: proc() {
    assert(current_reversed_group != 0)
    current_reversed_group = 0
}


//////////////////////////////////////////////////////
// slider api

slider_guard := false

slider_begin :: proc(pos: [2]f64, time: int) -> ^Slider {
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

slider_addNode :: proc(slider: ^Slider, pos: [2]f64) {
    node := &node_buf[node_count]
    node.pos = pos
    slider.nodeCount += 1
    node_count += 1
}


slider_from_to :: proc(from, to: [2]f64) -> ^Slider {
    slider: ^Slider
    if current_reversed_group > 0 {
        len := vec2_dist(from, to)

        slider = slider_begin(to, osu_time())
        slider_addNode(slider, from)
        slider_end(slider, len)

        slider.reversed = true
        slider.reversedGroup = current_reversed_group

        rev := &reversed_buf[current_reversed_group]

        duration := f64(len) / (rev.velocity * 100 * map_velocity) * (beat_len)
        rev.longestSliderDuration = math.max(rev.longestSliderDuration, duration)
    } else {
        slider = slider_begin(from, osu_time())
        slider_addNode(slider, to)
        slider_end(slider, vec2_dist(from, to))
    }
    return slider
}

slider_from_angle :: proc(start_pt: [2]f64, angle_rad: f64) {
    pt := [2]f64{ math.clamp(start_pt[0], pf_from[0], pf_to[0]),
                  math.clamp(start_pt[1], pf_from[1], pf_to[1]) }

    seg := segment_from_angle(pt, angle_rad)

    playfield_tl := pf_from
    playfield_tr := [2]f64{pf_to.x, pf_from.y}
    playfield_bl := [2]f64{pf_from.x, pf_to.y}
    playfield_br := pf_to

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
        slider_from_to(pt, end_pt)
    } else {
        fmt.printfln("no intersection found, start {}:{}, angle {}", pt.x, pt.y, angle_rad)
    }
    assert(found)
}

slider_from_angle_duration :: proc(start_pt: [2]f64, angle_rad, duration: f64) {
    dist := unit_circle(angle_rad) * duration
    slider_from_to(start_pt, start_pt + dist)
}


//////////////////////////////////////////////////////
// time handling

current_time := f64(300)
current_beat_16ths := 0

unbeated_time_ms := 0

beat_len :: 416.666666667

osu_time :: proc() -> int { return int(math.round_f64(current_time)) }

advance_snap :: proc(snap_divisor: int, times: int = 1) -> int {
    advance_time(-unbeated_time_ms)

    time_before := osu_time()
    for i in 0..<times {
        advance := f64(beat_len) / f64(snap_divisor)
        current_time += advance
        unbeated_time_ms = 0

        current_beat_16ths = (current_beat_16ths + snap_divisor / 16) % 16
    }
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


to_set_time := f64(0)
to_set_beat_16ths := 0
to_set_unbeated_time_ms := 0

set_guard := 0

set_times :: proc() {
    assert(set_guard == 0)
    set_guard = 1

    to_set_time = current_time
    to_set_beat_16ths = current_beat_16ths
    to_set_unbeated_time_ms = unbeated_time_ms
}

reset_times :: proc() {
    assert(set_guard == 1)
    set_guard = 0

    current_time = to_set_time
    current_beat_16ths = to_set_beat_16ths
    unbeated_time_ms = to_set_unbeated_time_ms
}
