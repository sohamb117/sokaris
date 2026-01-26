using Pkg
Pkg.activate(@__DIR__)

using Seraph
using GLMakie: events

# Get image path from command line or use default
image_path = length(ARGS) >= 1 ? ARGS[1] : "output.png"

fig = view_image(image_path)

println("Seraph started. Press R to reload, close window to exit.")
while events(fig).window_open[]
    sleep(0.1)
end
