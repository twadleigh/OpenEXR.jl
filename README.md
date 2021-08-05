# OpenEXR.jl

[![Build Status](https://github.com/twadleigh/OpenEXR.jl/workflows/CI/badge.svg)](https://github.com/twadleigh/OpenEXR.jl/actions?query=workflow%3A%22CI%22+branch%3Amaster)
[![codecov.io](http://codecov.io/github/twadleigh/OpenEXR.jl/coverage.svg?branch=master)](http://codecov.io/github/twadleigh/OpenEXR.jl?branch=master)

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
