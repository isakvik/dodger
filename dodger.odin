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

        fmt.sbprintf(b, "{},{},{},2,0,{}",
                slider.pos.x,
                slider.pos.y,
                slider.time,
                "L|")

        for n in 0..<slider.nodeCount {
            if n > 0 {
                write_rune(b, ',')
            }

            node := node_buf[slider.firstNodeIndex + n]
            write_int(b, node.pos.x)
            write_rune(b, ':')
            write_int(b, node.pos.y)
        }

        fmt.sbprintfln(b, ",1,{}", slider.length)
    }
}


node_buf: [65536]SliderNode
node_count := 0

slider_buf: [65536]Slider
slider_count := 0

greenline_buf: [4096]GreenLine
greenline_count := 0


//out_file_path :: "C:\\Users\\Isak\\AppData\\Local\\Temp\\befa01dfbc9a7298efcf0da6b23156960117d84c7250197c5eac85ab70cd3950\\Manabu Namiki - On the Verge of Madness [data].osu"
//out_file_path :: "F:\\osu!\\Songs\\Manabu Namiki - On the Verge of Madness (Stage 5)\\Manabu Namiki - On the Verge of Madness (Guest) [data].osu"
out_file_path :: "C:\\Users\\Isak\\AppData\\Local\\osu!\\Songs\\Manabu Namiki - On the Verge of Madness\\Manabu Namiki - On the Verge of Madness (Guest) [data].osu"


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

        append_osu(out_handle, "\n\n[HitObjects]\n")

        b = builder_make_len_cap(0, 2*1024*1024)

        write_sliders(&b)
        fmt.println(to_string(b))

        append_osu(out_handle, to_string(b))
    }

    os.close(out_handle)
}
