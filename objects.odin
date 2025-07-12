package dodger

import "core:fmt"
import "core:math"
import "core:strings"

vec2 :: struct {
    x: int,
    y: int
}

vec2_f64 :: struct {
    x: f64,
    y: f64
}

segment :: struct {
    from: vec2_f64,
    to: vec2_f64
}

vec2_dist :: proc(from: vec2, to: vec2) -> f64 {
    return math.sqrt(math.pow(f64(to.x - from.x), 2) + math.pow(f64(to.y - from.y), 2))
}


segment_intersect :: proc(a: segment, b: segment) -> vec2 {


    return {0,0}
}


vec2_w :: proc(pt: vec2, angle_rad: f64) -> vec2 {
    pt_f64 := vec2_f64{f64(pt.x), f64(pt.y)}

    lol := vec2_f64{ math.cos(angle_rad), math.sin(angle_rad) }

    seg := segment{ pt_f64, {pt_f64.x + lol.x, pt_f64.y + lol.y} }

    result: vec2

    result.x = pt.x + 100 * int(lol.x)
    result.y = pt.y + 100 * int(lol.y)

    return result
}



//time,beatLength,meter,sampleSet,sampleIndex,volume,uninherited,effects
GreenLine :: struct {
    time: int,
    velocityMultiplier: int // negative percentage
}

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
    return slider;
}


slider_guard := false

slider_begin :: proc(pos: vec2, time: int) -> ^Slider {
    assert(!slider_guard)
    slider_guard = true

    slider := &slider_buf[slider_count]

    slider.pos = pos;
    slider.time = time;
    slider.firstNodeIndex = node_count

    return slider;
}

slider_end :: proc(slider: ^Slider, length: f64) {
    assert(slider.nodeCount > 0)
    slider_guard = false
    slider_count += 1;

    slider.length = int(math.round(length))
}

greenline_add :: proc(sliderVelocityMultiplier: f64) {
    value: int
    value = int(math.round(100 / (sliderVelocityMultiplier * global_sv_multiplier))) * -1

    greenline := &greenline_buf[greenline_count]
    greenline.time = osu_time()
    greenline.velocityMultiplier = value

    greenline_count += 1
}

