module Horus

using GLMakie
using GLMakie: events
using FileIO: load
using Colors: red, green, blue

export view_image

function color_to_hex(c)
    r = round(Int, red(c) * 255)
    g = round(Int, green(c) * 255)
    b = round(Int, blue(c) * 255)
    return uppercase(string("#", string(r, base=16, pad=2), string(g, base=16, pad=2), string(b, base=16, pad=2)))
end

function view_image(path::String="output.png"; max_size=800)
    img_ref = Ref(load(path))
    h, w = size(img_ref[])

    # Scale down if too large
    scale = min(1.0, max_size / max(w, h))
    display_w = round(Int, w * scale)
    display_h = round(Int, h * scale)

    bar_height = 20
    fig = Figure(size=(display_w, display_h + bar_height), figure_padding=0)

    # Create a scene for the image (bypasses Axis layout issues)
    scene = Scene(fig.scene, viewport=Observable(Rect2i(0, bar_height, display_w, display_h)), clear=true)
    campixel!(scene)
    img_observable = Observable(rotr90(img_ref[]))
    image!(scene, 1..display_w, 1..display_h, img_observable)

    # Status bar as overlay at bottom
    status_text = Observable("Pixel: (-, -)  Color: #------")
    status_scene = Scene(fig.scene, viewport=Observable(Rect2i(0, 0, display_w, bar_height)), clear=true, backgroundcolor=:gray90)
    campixel!(status_scene)
    text!(status_scene, 5, bar_height/2, text=status_text, fontsize=12, align=(:left, :center))

    # Track mouse position (map display coords back to image coords)
    on(events(scene).mouseposition) do pos
        if is_mouseinside(scene)
            dx, dy = pos[1], pos[2] - bar_height
            # Convert display coords to image coords
            img_col = round(Int, dx / scale)
            img_row = h - round(Int, dy / scale) + 1
            if 1 <= img_row <= h && 1 <= img_col <= w
                c = img_ref[][img_row, img_col]
                hex = color_to_hex(c)
                status_text[] = "Pixel: ($img_col, $img_row)  Color: $hex"
            end
        end
    end

    # Reload function
    function reload_image()
        try
            img_ref[] = load(path)
            img_observable[] = rotr90(img_ref[])
        catch e
            @warn "Failed to reload image" exception=e
        end
    end

    # Manual reload with R key
    on(events(fig).keyboardbutton) do event
        if event.action == Keyboard.press && event.key == Keyboard.r
            reload_image()
        end
    end

    # Auto-reload by polling file modification time
    last_mtime = Ref(mtime(path))
    @async begin
        while events(fig).window_open[]
            try
                current_mtime = mtime(path)
                if current_mtime > last_mtime[]
                    last_mtime[] = current_mtime
                    sleep(0.05)  # Brief delay to ensure file is fully written
                    reload_image()
                end
            catch e
                @warn "File poll error" exception=e
            end
            sleep(0.5)  # Poll every 500ms
        end
    end

    GLMakie.activate!(title = "Horus")
    display(fig)
    return fig
end

end
