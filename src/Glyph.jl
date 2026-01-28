module Glyph

using Colors
using ImageCore: clamp01

▷(x, f) = f(x)
🝡(x, f) = f(x)
☽(f, g) = x -> f(g(x))
⊙(a, b) = a .* b
∅(x, f) = map(f, x)
✧(x, f) = foldl(f, x)
⇉(f, g) = x -> (f(x), g(x))
⚕(x, default) = isnothing(x) || (x isa Number && isnan(x)) ? default : x

# Clamp function that works with both grayscale and RGB images
# For color types, clamp each channel component
𓇬(x::AbstractArray{<:Colorant}) = map(c -> clamp01(c), x)
𓇬(x::AbstractArray{<:Number}) = clamp.(x, 0.0, 1.0)
𓇬(x) = clamp.(x, 0.0, 1.0)

function ☿(f)
    cache = Dict()
    return function(x)
        if !haskey(cache, x)
            cache[x] = f(x)
        end
        cache[x]
    end
end

function ⚹(arr::AbstractMatrix, i::Int, j::Int)
    offsets = [(0,1), (1,0), (1,-1), (0,-1), (-1,0), (-1,1)]
    neighbors = eltype(arr)[]
    for (di, dj) in offsets
        ni, nj = i + di, j + dj
        if checkbounds(Bool, arr, ni, nj)
            push!(neighbors, arr[ni, nj])
        end
    end
    neighbors
end

✦(a, b) = [(x, y) for x in a, y in b]
☥(x) = deepcopy(x)
⚸(x, f) = accumulate(f, x)

# Export bindings
export ⊙, ☽, ∅, ▷, ✧, 🝡, ⚕, ☿, ⚹, ✦, ☥, ⚸, ⇉, 𓇬

end
