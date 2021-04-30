using Test, OpenEXR, FileIO, Colors

@testset "Roundtrip" begin
  
rgba = rand(RGBA{Float16}, 256, 512)
fn = File{DataFormat{:EXR}}(tempname())
OpenEXR.save(fn, rgba)
try
    loaded_rgba = OpenEXR.load(fn)
    @test rgba == loaded_rgba
finally
    rm(fn.filename)
end

end