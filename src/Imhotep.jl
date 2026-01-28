module Imhotep

using ImageFiltering
using ImageTransformations
using Colors
using Random
using Luxor
using FileIO: load, save

const Cairo = Luxor.Cairo

export invert, gamma, brightness, contrast, saturate, desaturate, grayscale
export gaussian, box_blur, median_blur, motion_blur
export sharpen, edge_detect, emboss, posterize, threshold, solarize
export noise, pixelate
export crop, crop_center, crop_to, scale_crop
export text_overlay, glow, load, save

# Basic transformations
# Invert - apply to each color channel
invert(x) = map(pixel -> mapc(c -> 1.0 - c, pixel), x)

# Gamma correction - apply power to each color channel
gamma(γ) = function(x)
    map(pixel -> mapc(c -> c^γ, pixel), x)
end

brightness(factor) = function(x)
    map(pixel -> mapc(c -> clamp(c + factor, 0.0, 1.0), pixel), x)
end

contrast(factor) = function(x)
    map(pixel -> mapc(c -> clamp((c - 0.5) * factor + 0.5, 0.0, 1.0), pixel), x)
end

# Blur filters
gaussian(σ) = x -> imfilter(x, Kernel.gaussian(σ))

box_blur(size) = x -> imfilter(x, Kernel.box((size, size)))

median_blur(size) = x -> mapwindow(median, x, (size, size))

motion_blur(length, angle=0) = function(x)
    # Create a motion blur kernel
    kernel = zeros(length, length)
    center = (length + 1) ÷ 2

    # Simple horizontal motion blur (can be rotated by angle)
    if angle == 0
        kernel[center, :] .= 1 / length
    else
        # For now, simplified version
        for i in 1:length
            kernel[i, i] = 1 / length
        end
    end

    imfilter(x, kernel)
end

# Color adjustments
saturate(factor) = function(img)
    map(img) do pixel
        h, s, v = HSV(pixel)
        RGB(HSV(h, clamp(s * factor, 0, 1), v))
    end
end

desaturate(factor) = saturate(1 - factor)

grayscale(img) = Gray.(img)

# Edge detection and sharpening
sharpen(amount=1.0) = function(x)
    kernel = [0 -1 0; -1 5 -1; 0 -1 0] .* amount
    kernel[2, 2] = 1 + 4 * amount
    imfilter(x, kernel)
end

edge_detect(x) = imfilter(x, Kernel.sobel())

emboss(x) = begin
    kernel = [-2 -1 0; -1 1 1; 0 1 2]
    imfilter(x, kernel)
end

# Color effects
posterize(levels) = x -> round.(x .* levels) ./ levels

threshold(value=0.5) = x -> map(p -> p > value ? 1.0 : 0.0, x)

solarize(threshold=0.5) = function(x)
    map(x) do p
        p > threshold ? 1.0 - p : p
    end
end

# Distortion effects
noise(amount=0.1) = function(x)
    noise_matrix = randn(size(x)...) .* amount
    clamp.(x .+ noise_matrix, 0, 1)
end

pixelate(block_size) = function(x)
    h, w = size(x)
    result = copy(x)

    for i in 1:block_size:h
        for j in 1:block_size:w
            # Get block bounds
            i_end = min(i + block_size - 1, h)
            j_end = min(j + block_size - 1, w)

            # Calculate average color in block
            block = x[i:i_end, j:j_end]
            avg_color = sum(block) / length(block)

            # Fill block with average
            result[i:i_end, j:j_end] .= avg_color
        end
    end

    result
end

# Crop functions
"""
    crop(x, y, width, height)

Crop image starting at position (x, y) with given width and height.
Returns a curried function that takes an image.
"""
crop(x_start, y_start, width, height) = function(img)
    h, w = size(img)
    x_end = min(x_start + width - 1, w)
    y_end = min(y_start + height - 1, h)
    img[y_start:y_end, x_start:x_end]
end

"""
    crop_center(width, height)

Crop image from the center with given width and height.
Returns a curried function that takes an image.
"""
crop_center(width, height) = function(img)
    h, w = size(img)
    x_start = max(1, (w - width) ÷ 2 + 1)
    y_start = max(1, (h - height) ÷ 2 + 1)
    x_end = min(w, x_start + width - 1)
    y_end = min(h, y_start + height - 1)
    img[y_start:y_end, x_start:x_end]
end

"""
    crop_to(target_height, target_width)

Crop image to match target dimensions, cropping from center if needed.
Returns a curried function that takes an image.
"""
crop_to(target_height, target_width) = function(img)
    h, w = size(img)

    if h == target_height && w == target_width
        return img
    end

    # Calculate crop dimensions
    crop_h = min(h, target_height)
    crop_w = min(w, target_width)

    # Calculate starting positions (center crop)
    start_y = max(1, (h - crop_h) ÷ 2 + 1)
    start_x = max(1, (w - crop_w) ÷ 2 + 1)

    img[start_y:(start_y + crop_h - 1), start_x:(start_x + crop_w - 1)]
end

"""
    scale_crop(target_height, target_width)

Scale image up if needed, then crop to exact target dimensions.
If image is smaller than target, it will be scaled up first (maintaining aspect ratio),
then center-cropped to exact dimensions.
Returns a curried function that takes an image.
"""
scale_crop(target_height, target_width) = function(img)
    h, w = size(img)

    if h == target_height && w == target_width
        return img
    end

    # Calculate scale factor needed to ensure image covers target dimensions
    scale_h = target_height / h
    scale_w = target_width / w
    scale_factor = max(scale_h, scale_w)

    # Only scale if we need to grow the image
    if scale_factor > 1.0
        new_h = round(Int, h * scale_factor)
        new_w = round(Int, w * scale_factor)
        img = imresize(img, (new_h, new_w))
        h, w = new_h, new_w
    end

    # Now crop to exact dimensions from center
    start_y = max(1, (h - target_height) ÷ 2 + 1)
    start_x = max(1, (w - target_width) ÷ 2 + 1)

    img[start_y:(start_y + target_height - 1), start_x:(start_x + target_width - 1)]
end

"""
    glow(blur_amount=5.0, opacity=0.5)

Creates a glow effect by duplicating the layer, applying gaussian blur and reducing opacity
to the bottom layer, then adding them together.

# Arguments
- `blur_amount`: Sigma value for gaussian blur (default: 5.0)
- `opacity`: Opacity multiplier for the blurred layer (0.0-1.0, default: 0.5)

Returns a curried function that takes an image.
"""
glow(blur_amount=5.0, opacity=0.5) = function(x)
    # Create blurred and dimmed bottom layer
    glow_layer = x |> gaussian(blur_amount)
    glow_layer = map(pixel -> RGBA(pixel.r * opacity, pixel.g * opacity, pixel.b * opacity,
                                     alpha(pixel) * opacity), glow_layer)

    # Add original on top
    x + glow_layer
end

"""
    text_overlay(source_file, height, width; font_size=12, x_offset=10, y_offset=10, fg_color=RGB(1,1,1), fg_alpha=0.7, bg_color=RGB(0,0,0), bg_alpha=0.0, font_face="monospace", symbol_font="Noto Sans Symbols", hieroglyph_font="Noto Sans Egyptian Hieroglyphs")

Render text from a source code file as an overlay bitmap using Luxor.
Returns a bitmap with transparency that can be composited separately.
Supports full Unicode including emojis and special characters with automatic font fallback.

# Arguments
- `source_file`: Path to the source file to read and render
- `height`: Height of the output bitmap in pixels
- `width`: Width of the output bitmap in pixels
- `font_size`: Font size in points (default: 12)
- `x_offset`: Horizontal pixel offset for text placement (default: 10)
- `y_offset`: Vertical pixel offset for text placement (default: 10)
- `fg_color`: Foreground color for text (default: white)
- `fg_alpha`: Alpha/opacity of the foreground text (0.0-1.0, default: 0.7)
- `bg_color`: Background color for text (default: black)
- `bg_alpha`: Alpha/opacity of the background (0.0-1.0, default: 0.0 - transparent)
- `font_face`: Primary font family to use (default: "monospace")
- `symbol_font`: Font for symbols and non-standard Unicode (default: "Noto Sans Symbols")
- `hieroglyph_font`: Font for Egyptian hieroglyphs (default: "Noto Sans Egyptian Hieroglyphs")

Returns the text overlay bitmap.
"""
function text_overlay(source_file, height, width; font_size=12, x_offset=10, y_offset=10,
                      fg_color=RGB(1.0,1.0,1.0), fg_alpha=0.7,
                      bg_color=RGB(0.0,0.0,0.0), bg_alpha=0.0,
                      font_face="monospace", symbol_font="Noto Sans Symbols",
                      hieroglyph_font="Noto Sans Egyptian Hieroglyphs")
    # Auto-convert tuples to RGB
    fg_color = fg_color isa Tuple ? RGB(fg_color...) : fg_color
    bg_color = bg_color isa Tuple ? RGB(bg_color...) : bg_color

    # Read the source file with UTF-8 encoding
    source_text = read(source_file, String)
    lines = split(source_text, '\n')

    # Debug: print the text to console to verify Unicode characters
    println("Text to render:")
    for line in lines
        println(line)
    end
    println("---")

    # Create a temporary PNG file for Luxor to render text
    temp_file = tempname() * ".png"

    # Create Luxor drawing
    Drawing(width, height, temp_file)
    origin()
    background(0, 0, 0, 0)  # Transparent background

    fontsize(font_size)

    # Helper to determine which font to use for a character
    function get_font_for_char(c)
        cp = codepoint(c)

        # Egyptian Hieroglyphs: U+13000–U+1342F
        if cp >= 0x13000 && cp <= 0x1342F
            return hieroglyph_font
        # Geometric Shapes: U+25A0–U+25FF
        elseif cp >= 0x25A0 && cp <= 0x25FF
            return "Menlo"
        # Basic Latin, Latin Extended, common punctuation: U+0000–U+024F
        elseif cp <= 0x024F
            return font_face
        # Everything else (symbols, emojis, etc.)
        else
            return symbol_font
        end
    end

    # Render each line
    line_height = font_size * 1.2
    for (idx, line) in enumerate(lines)
        y = y_offset + (idx - 1) * line_height - height/2

        # Render character by character with font switching
        sethue(fg_color.r, fg_color.g, fg_color.b)
        setopacity(fg_alpha)

        current_x = x_offset - width/2
        for char in line
            # Select appropriate font for this character
            selected_font = get_font_for_char(char)
            fontface(selected_font)

            # Render the character
            char_str = string(char)

            # Get text extents: [x_bearing, y_bearing, width, height, x_advance, y_advance]
            extents = textextents(char_str)

            text(char_str, Point(current_x, y), halign=:left, valign=:top)

            # Use x_advance (index 5) for proper character spacing
            # This accounts for the intended spacing between characters
            current_x += extents[5]
        end
    end

    finish()

    # Load the rendered text overlay and return it
    text_layer = load(temp_file)
    rm(temp_file)

    text_layer = text_layer |> sharpen(1.0)
end

end
