using Images, ImageFiltering, ImageTransformations, Colors, Random, Seraph.Glyph

img = load("inputs/input.png")

processed = img

save("output.png", processed)