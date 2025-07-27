package dodger

import "core:fmt"
import "core:math"
import "core:os"
import "core:strings"

header := #load("header.osu", string)


append_osu :: proc(handle: os.Handle, buf: string) -> int {
    len, err := os.write_string(handle, buf)
    if err != 0 {
        fmt.printfln("error while writing:", err)
    }
    return len
}

write_sliders :: proc(b: ^strings.Builder) {
    using strings

    for s in 0..<slider_count {
        slider := slider_buf[s]
        time := slider.time

        if slider.length < 10 { continue; }

        if slider.reversed {
            rev := reversed_buf[slider.reversedGroup]

            duration := f64(slider.length) / (rev.velocity * 100 * map_velocity) * beat_len
            time = slider.time + int(math.round_f64(rev.longestSliderDuration - duration) - rev.longestSliderDuration)

            fmt.println(pf_to[0] - pf_from[0])
            fmt.println(pf_to[1] - pf_from[1])
        }


        fmt.sbprintf(b, "{},{},{},2,0,{}",
                int(math.round_f64(slider.pos[0])),
                int(math.round_f64(slider.pos[1])),
                time,
                "L|")

        for n in 0..<slider.nodeCount {
            if n > 0 {
                write_rune(b, ',')
            }

            node := node_buf[slider.firstNodeIndex + n]
            write_int(b, int(math.round_f64(node.pos[0])))
            write_rune(b, ':')
            write_int(b, int(math.round_f64(node.pos[1])))
        }

        fmt.sbprintfln(b, ",1,{}", slider.length)
    }
}

write_circles :: proc(b: ^strings.Builder) {
    using strings

    for c in 0..<circle_count {

        circle := circle_buf[c]

        fmt.sbprintfln(b, "{},{},{},1,0,0:0:0:0",
                       int(math.round_f64(circle.pos[0])),
                       int(math.round_f64(circle.pos[1])),
                       circle.time)
    }
}


reversed_buf: [65536]ReversedSliderGroup
reversed_count := 0

node_buf: [65536]SliderNode
node_count := 0

slider_buf: [65536]Slider
slider_count := 0

circle_buf: [65536]Circle
circle_count := 0

greenline_buf: [4096]GreenLine
greenline_count := 0


//out_file_path :: "C:\\Users\\Isak\\AppData\\Local\\Temp\\6efc6f4df8e45e725bd2836fb351b1b413d18dbf164b6a1e0c5d757002bec9bc\\Manabu Namiki - On the Verge of Madness [data].osu"
//out_file_path :: "C:\\Users\\Isak\\AppData\\Local\\osu!\\Songs\\Manabu Namiki - On the Verge of Madness\\Manabu Namiki - On the Verge of Madness (Guest) [data].osu"

out_file_path :: "F:\\osu!\\Songs\\Manabu Namiki - On the Verge of Madness (Stage 5)\\Manabu Namiki - On the Verge of Madness (-GN) [LOWEST SCORE WINS].osu"

main :: proc() {
    out_handle, err := os.open(out_file_path, os.O_CREATE | os.O_TRUNC)
    if err != 0 {
        fmt.printfln("failed during header file read: {}", err)
        return
    }

    map_create()

    append_osu(out_handle, header)

    {
        using strings
        b := builder_make_len_cap(0, 2*1024*1024)

        //time,beatLength,meter,sampleSet,sampleIndex,volume,uninherited,effects

        for i in 0..<greenline_count {
            greenline := greenline_buf[i]
            fmt.sbprintfln(&b, "{},{},0,1,0,0,0,0", greenline.time, greenline.velocityMultiplier)
        }
        fmt.println(to_string(b))

        append_osu(out_handle, to_string(b))

        append_osu(out_handle, "\n\n[Colours]\nCombo1 : 255,0,255\nCombo2 : 255,0,255")

        append_osu(out_handle, "\n\n[HitObjects]\n")

        b = builder_make_len_cap(0, 2*1024*1024)

        write_circles(&b)
        write_sliders(&b)
        fmt.println(to_string(b))

        append_osu(out_handle, to_string(b))
    }

    os.close(out_handle)
}
