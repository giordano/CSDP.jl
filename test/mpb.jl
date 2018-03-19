const solver = CSDP.CSDPSolver(printlevel=0)

@testset "Linear tests" begin
    include(joinpath(Pkg.dir("MathProgBase"),"test","linproginterface.jl"))
    linprogsolvertest(solver, 1e-7)
end

@testset "Conic tests" begin
    include(joinpath(Pkg.dir("MathProgBase"),"test","conicinterface.jl"))
    # FIXME fails on Windows 32 bits... Maybe I should put linear vars/cons
    # in a diagonal matrix in SemidefiniteModels.jl instead of many 1x1 blocks
    @static if !is_windows() || Sys.WORD_SIZE != 32
        @testset "Conic linear tests" begin
            coniclineartest(solver, duals=true, tol=1e-6)
        end

        @testset "Conic SOC tests" begin
            conicSOCtest(CSDP.CSDPSolver(printlevel=0, write_prob="soc.prob"), duals=true, tol=1e-6)
        end

        @testset "Conic SOC rotated tests" begin
            conicSOCRotatedtest(solver, duals=true, tol=1e-6)
        end
    end

    @testset "Conic SDP tests" begin
        conicSDPtest(solver, duals=false, tol=1e-6)
    end
end
