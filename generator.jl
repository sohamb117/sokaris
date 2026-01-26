using Images, ImageFiltering, ImageTransformations, Colors, Random
using Sokaris.Glyph
using Sokaris.Imhotep

img = load("inputs/input.png") ▷ float
overlay = load("inputs/overlay.png") ▷ float

processed = (
    img
    ▷ invert
    ▷ gamma(0.85)
    ▷ noise(0.1)
    ▷ gaussian(2)
    ▷ 𓇬
)

save("output.png", processed)