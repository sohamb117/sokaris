# Sokaris

There are several components to Sokaris, so far.
1. **Horus** - the image viewer. It supports auto-reload, so when you generate a new image, it will automatically update the view.
2. **Glyph** - the operator bindings. This makes writing complex pipe systems and certain optimisations much easier and cleaner. 
3. **Imhotep** - the image editing macros. This defines a number of functions that can be used to perform edits on an image array.

How to use: Edit generator.jl to perform the edits you want to perform. The sample generator.jl provides a basic structure. Run generation with `generate.sh` or directly with Julia REPL if you prefer.

Dependency management not yet handled, just install the necessary packages with Julia.

More documentation coming soon.