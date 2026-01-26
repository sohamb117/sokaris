module Imhotep

using ImageFiltering
using Colors
using Random

export invert, gamma, brightness, contrast, saturate, desaturate, grayscale
export gaussian, box_blur, median_blur, motion_blur
export sharpen, edge_detect, emboss, posterize, threshold, solarize
export noise, pixelate

# Basic transformations
invert(x) = 1 .- x

gamma(γ) = x -> x .^ γ

brightness(factor) = x -> clamp.(x .+ factor, 0, 1)

contrast(factor) = x -> clamp.((x .- 0.5) .* factor .+ 0.5, 0, 1)

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

end
