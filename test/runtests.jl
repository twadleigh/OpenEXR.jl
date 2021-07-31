using Test, OpenEXR, FileIO, Colors, FixedPointNumbers

@testset "RoundTrip" begin

    @testset "Identical" begin
        for typ in (RGBA{Float16}, RGB{Float16}, GrayA{Float16}, Gray{Float16})
            img = rand(typ, 256, 512)
            fn = File{DataFormat{:EXR}}(tempname())
            OpenEXR.save(fn, img)
            try
                loaded_img = OpenEXR.load(fn)
                @test typeof(loaded_img) === Array{typ,2}
                @test img == loaded_img
            finally
                rm(fn.filename)
            end
        end
    end

    @testset "Lossless with type conversion" begin
        for (save_type, load_type) in (
            (RGBA{N0f8}, RGBA{Float16}),
            (RGB{N0f8}, RGB{Float16}),
            (GrayA{N0f8}, GrayA{Float16}),
            (Gray{N0f8}, Gray{Float16}),
        )
            img = rand(save_type, 256, 512)
            fn = File{DataFormat{:EXR}}(tempname())
            OpenEXR.save(fn, img)
            try
                loaded_img = OpenEXR.load(fn)
                @test typeof(loaded_img) === Array{load_type,2}
                converted_img = (c -> convert(save_type, c)).(loaded_img)
                @test converted_img == loaded_img
            finally
                rm(fn.filename)
            end
        end
    end

    @testset "Lossy with type conversion" begin

        @testset "Bit depth truncation" begin

            for (save_type, load_type) in (
                (RGBA{Float32}, RGBA{Float16}),
                (RGB{Float32}, RGB{Float16}),
                (GrayA{Float32}, GrayA{Float16}),
                (Gray{Float32}, Gray{Float16}),
            )
                img = rand(save_type, 256, 512)
                fn = File{DataFormat{:EXR}}(tempname())
                OpenEXR.save(fn, img)
                try
                    loaded_img = OpenEXR.load(fn)
                    @test typeof(loaded_img) === Array{load_type,2}
                    diffs = map(colordiff, color.(img), color.(loaded_img))
                    @test diffs ≈ zeros(size(diffs)) rtol = 1e-10
                finally
                    rm(fn.filename)
                end
            end
        end
    end
end