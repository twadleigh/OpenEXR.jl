module OpenEXR

export load_exr, save_exr

using FileIO

module C
using OpenEXR_jll
using Colors
const ImfHalf = Float16
const ImfRgba = RGBA{ImfHalf}
include("OpenEXR_common.jl")
include("OpenEXR_api.jl")
const IMF_WRITE_RGBA = IMF_WRITE_RGB + IMF_WRITE_A
end  # module C

const MAGIC = Cint(C.IMF_MAGIC)

@enum Compression::Cint begin
    NO_COMPRESSION = C.IMF_NO_COMPRESSION
    RLE_COMPRESSION = C.IMF_RLE_COMPRESSION
    ZIPS_COMPRESSION = C.IMF_ZIPS_COMPRESSION
    ZIP_COMPRESSION = C.IMF_ZIP_COMPRESSION
    PIZ_COMPRESSION = C.IMF_PIZ_COMPRESSION
    PXR24_COMPRESSION = C.IMF_PXR24_COMPRESSION
    B44_COMPRESSION = C.IMF_B44_COMPRESSION
    B44A_COMPRESSION = C.IMF_B44A_COMPRESSION
    DWAA_COMPRESSION = C.IMF_DWAA_COMPRESSION
    DWAB_COMPRESSION = C.IMF_DWAB_COMPRESSION
end

@enum RgbaChannels::Cint begin
    WRITE_R = C.IMF_WRITE_R
    WRITE_G = C.IMF_WRITE_G
    WRITE_B = C.IMF_WRITE_B
    WRITE_A = C.IMF_WRITE_A
    WRITE_Y = C.IMF_WRITE_Y
    WRITE_C = C.IMF_WRITE_C
    WRITE_RGB = C.IMF_WRITE_RGB
    WRITE_RGBA = C.IMF_WRITE_RGBA
    WRITE_YC = C.IMF_WRITE_YC
    WRITE_YA = C.IMF_WRITE_YA
    WRITE_YCA = C.IMF_WRITE_YCA
end

function check(ret)
    ret == typeof(ret)(0) && error(unsafe_string(C.ImfErrorMessage()))
end

"""
    load_exr(filename)

If `filename` is a file in OpenEXR format, return a tuple containing the corresponding
RGBA{Float16} image along with in integer encoding the populated channels.
"""
function load_exr(filename)
    infile = C.ImfOpenInputFile(filename)  # open the file
    check(infile)
    try
        # get the header
        hdr = C.ImfInputHeader(infile)

        # read its data window
        xmin = Ref{Cint}()
        ymin = Ref{Cint}()
        xmax = Ref{Cint}() 
        ymax = Ref{Cint}()
        C.ImfHeaderDataWindow(hdr, xmin, ymin, xmax, ymax)

        # compute the window size
        width = xmax[]-xmin[]+1
        height = ymax[]-ymin[]+1

        # allocate space for the result and get its strides
        data = Array{C.ImfRgba, 2}(undef, height, width)
        (xstride, ystride) = strides(data)

        # get the pointer to the data, shifting it according to the expected window
        dataptr = Base.unsafe_convert(Ptr{C.ImfRgba}, data) - xmin[] * xstride - ymin[] * ystride

        # copy the data
        check(C.ImfInputSetFrameBuffer(infile, dataptr, ystride, xstride))
        check(C.ImfInputReadPixels(infile, ymin[], ymax[]))

        # return the loaded raster along with the channels
        return (data, C.ImfInputChannels(infile))
    finally
        check(C.ImfCloseInputFile(infile))
    end
end

"""
    save_exr(filename, image[, channels])

Save the channels of `image` indicated by `channels` (by default, all are saved) into a
file in OpenEXR format named `filename`.
"""
function save_exr(filename, image::AbstractArray{C.ImfRgba, 2}, channels = WRITE_RGBA)
    # get the size of the data
    (height, width) = size(image)

    # create a new header
    hdr = C.ImfNewHeader()
    check(hdr)
    try
        # set the correct window sizes
        C.ImfHeaderSetDataWindow(hdr, 0, 0, width-1, height-1)
        C.ImfHeaderSetDisplayWindow(hdr, 0, 0, width-1, height-1)

        # open the output file
        outfile = C.ImfOpenOutputFile(filename, hdr, channels)
        check(outfile)
        try
            # get the strides and a pointer to the raster
            (xstride, ystride) = strides(image)
            dataptr = Base.unsafe_convert(Ptr{C.ImfRgba}, image)

            # copy the data
            check(C.ImfOutputSetFrameBuffer(outfile, dataptr, ystride, xstride))
            check(C.ImfOutputWritePixels(outfile, height))
        finally
            check(C.ImfCloseOutputFile(outfile))
        end
    finally
        C.ImfDeleteHeader(hdr)
    end
    nothing
end

function save_exr(f, image::AbstractArray{T, 2}, channels = IMF_WRITE_RGBA) where T
    save_exr(f, (c->convert(C.ImfRgba, c)).(image), channels)
end

# FileIO interface
load(f::File{DataFormat{:EXR}}) = load_exr(f.filename)[1]
save(f::File{DataFormat{:EXR}}, args...) = save_exr(f.filename, args...)

end  # module OpenEXR
