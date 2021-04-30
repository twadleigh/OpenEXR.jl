# OpenEXR.jl
Saving and loading of OpenEXR files.

Basic usage:
```jl
using OpenEXR

# read an EXR file into an `Array{RGBA{Float16},2}`.
myimage = OpenEXR.load(File{DataFormat{:EXR}}("myimage.exr"))

# save an image to an EXR file
OpenEXR.save(File{DataFormat{:EXR}}("myimage2.exr"), myimage)
```

TODO: get this registered with [FileIO](https://github.com/JuliaIO/FileIO.jl).
