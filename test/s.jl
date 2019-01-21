using LinearAlgebra: I

@testset "S" begin
    @testset "scard" begin
        cell = SpiceDoubleCell(10)
        darray = [[1.0, 3.0], [7.0, 11.0], [23.0, 27.0]]
        @test card(cell) == 0
        for w in darray
            wninsd!(cell, w...)
        end
        @test card(cell) == 6
        scard!(cell, 0)
        @test card(cell) == 0
    end
    @test spd() == 86400.0
    furnsh(path(CORE, :spk))
    @test sxform("J2000", "J2000", 0.0) ≈ Matrix{Float64}(I, 6, 6)
    @test_throws SpiceError sxform("J2000", "Norbert", 0.0)
    @test spkezr("EARTH", 0.0, "J2000", "EARTH") == ([0.0, 0.0, 0.0, 0.0, 0.0, 0.0], 0.0)
    @test spkezr(399, 0.0, "J2000", "EARTH") == ([0.0, 0.0, 0.0, 0.0, 0.0, 0.0], 0.0)
    @test spkezr("EARTH", 0.0, "J2000", 399) == ([0.0, 0.0, 0.0, 0.0, 0.0, 0.0], 0.0)
    @test spkezr(399, 0.0, "J2000", 399) == ([0.0, 0.0, 0.0, 0.0, 0.0, 0.0], 0.0)
    @test spkpos("EARTH", 0.0, "J2000", "EARTH") == ([0.0, 0.0, 0.0], 0.0)
    @test spkpos(399, 0.0, "J2000", "EARTH") == ([0.0, 0.0, 0.0], 0.0)
    @test spkpos("EARTH", 0.0, "J2000", 399) == ([0.0, 0.0, 0.0], 0.0)
    @test spkpos(399, 0.0, "J2000", 399) == ([0.0, 0.0, 0.0], 0.0)
    kclear()


    @testset "subslr" begin
        try
            furnsh(
                path(CORE, :lsk),
                path(CORE, :pck),
                path(CORE, :spk),
            ) 
            et = str2et("2008 aug 11 00:00:00")
            re, _, rp = bodvrd("MARS", "RADII", 3)
            f = (re - rp) / re
            methods = ["INTERCEPT/ELLIPSOID", "NEAR POINT/ELLIPSOID"]
            expecteds = [
                [
                    0.0,
                    175.8106755102322,
                    23.668550281477703,
                    -175.81067551023222,
                    23.420819936106213,
                    175.810721536362,
                    23.42082337182491,
                    -175.810721536362,
                    23.42081994605096,
                ],
                [
                    0.0,
                    175.8106754100492,
                    23.420823361866685,
                    -175.81067551023222,
                    23.175085577910583,
                    175.81072152220804,
                    23.420823371828,
                    -175.81072152220804,
                    23.420819946054046,
                ]
            ]
            for (expected, method) in zip(expecteds, methods)
                spoint, trgepc, srfvec = subslr(method, "Mars", et, "IAU_MARS", "Earth", abcorr="LT+S")
                spglon, spglat, spgalt = recpgr("mars", spoint, re, f)

                @test spgalt ≈ expected[1]
                @test rad2deg(spglon) ≈ expected[2]
                @test rad2deg(spglat) ≈ expected[3]
                spcrad, spclon, spclat = reclat(spoint)
                @test rad2deg(spclon) ≈ expected[4]
                @test rad2deg(spclat) ≈ expected[5]
                sunpos, sunlt = spkpos("sun", trgepc, "iau_mars", "mars", abcorr="LT+S")
                supgln, supglt, supgal = recpgr("mars", sunpos, re, f)
                @test rad2deg(supgln) ≈ expected[6]
                @test rad2deg(supglt) ≈ expected[7]
                supcrd, supcln, supclt = reclat(sunpos)
                @test rad2deg(supcln) ≈ expected[8]
                @test rad2deg(supclt) ≈ expected[9]
            end
        finally
            kclear()
        end
    end
end
