using SemidefiniteOptInterface
SOI = SemidefiniteOptInterface

using MathOptInterface
MOI = MathOptInterface

export CSDPSolver

struct CSDPSolver <: SOI.AbstractSDSolver
    options::Dict{Symbol,Any}
end
CSDPSolver(;kwargs...) = CSDPSolver(Dict{Symbol,Any}(kwargs))

type CSDPSolverInstance <: SOI.AbstractSDSolverInstance
    C
    b
    As
    X
    y
    Z
    status::Cint
    pobj::Cdouble
    dobj::Cdouble
    options::Dict{Symbol,Any}
    function CSDPSolverInstance(; kwargs...)
        new(nothing, nothing, nothing, nothing, nothing, nothing,
            -1, 0.0, 0.0, Dict{Symbol, Any}(kwargs))
    end
end
SOI.SDSolverInstance(s::CSDPSolver) = CSDPSolverInstance(; s.options...)

function SOI.initinstance!(m::CSDPSolverInstance, blkdims::Vector{Int}, constr::Int)
    m.C = blockmatzeros(blkdims)
    m.b = zeros(Cdouble, constr)
    m.As = [constrmatzeros(i, blkdims) for i in 1:constr]
end

function SOI.setconstraintconstant!(m::CSDPSolverInstance, val, constr::Integer)
    println("b[$constr] = $val")
    m.b[constr] = val
end
function SOI.setconstraintcoefficient!(m::CSDPSolverInstance, coef, constr::Integer, blk::Integer, i::Integer, j::Integer)
    println("A[$constr][$blk][$i, $j] = $coef")
    m.As[constr][blk][i,j] = coef
end
function SOI.setobjectivecoefficient!(m::CSDPSolverInstance, coef, blk::Integer, i::Integer, j::Integer)
    m.C[blk][i,j] = coef
end

function MOI.optimize!(m::CSDPSolverInstance)
    As = map(A->A.csdp, m.As)

    let wrt = string(get(m.options, :write_prob, ""))
        if length(wrt) > 0
            k = 1
            wrtf = "$wrt.$k"
            while isfile(wrtf)
                wrtf = "$wrt.$k"
                k += 1
            end
            info("Writing problem to $(pwd())/$(wrtf)")
            write_prob(wrtf, m.C, m.b, As)
        end
    end

    verbose = get(m.options, :verbose, true)

    m.X, m.y, m.Z = initsoln(m.C, m.b, As)
    m.status, m.pobj, m.dobj = easy_sdp(m.C, m.b, As, m.X, m.y, m.Z, verbose)
end

function MOI.getattribute(m::CSDPSolverInstance, ::MOI.TerminationStatus)
    status = m.status
    if 0 <= status <= 2
        return MOI.Success
    elseif status == 3
        return MOI.AlmostSuccess
    elseif status == 4
        return MOI.IterationLimit
    elseif 5 <= status <= 7
        return MOI.SlowProgress
    elseif 8 <= status <= 9
        return MOI.NumericalError
    else
        error("Internal library error: status=$status")
    end
end

MOI.cangetattribute(m::CSDPSolverInstance, ::MOI.PrimalStatus) = m.status == 0 || m.status >= 2
function MOI.getattribute(m::CSDPSolverInstance, ::MOI.PrimalStatus)
    status = m.status
    if status == 0
        return MOI.FeasiblePoint
    elseif status == 1
        return MOI.InfeasiblePoint
    elseif status == 2
        return MOI.InfeasibilityCertificate
    elseif status == 3
        return MOI.NearlyFeasiblePoint
    elseif 4 <= status <= 9
        return MOI.UnknownResultStatus
    else
        error("Internal library error: status=$status")
    end
end

MOI.cangetattribute(m::CSDPSolverInstance, ::MOI.DualStatus) = 0 <= m.status <= 1 || m.status >= 3
function MOI.getattribute(m::CSDPSolverInstance, ::MOI.DualStatus)
    status = m.status
    if status == 0
        return MOI.FeasiblePoint
    elseif status == 1
        return MOI.InfeasibilityCertificate
    elseif status == 2
        return MOI.InfeasiblePoint
    elseif status == 3
        return MOI.NearlyFeasiblePoint
    elseif 4 <= status <= 9
        return MOI.UnknownResultStatus
    else
        error("Internal library error: status=$status")
    end
end

function SOI.getprimalobjectivevalue(m::CSDPSolverInstance)
    m.pobj
end
function SOI.getdualobjectivevalue(m::CSDPSolverInstance)
    m.dobj
end
function SOI.getX(m::CSDPSolverInstance)
    m.X
end
function SOI.gety(m::CSDPSolverInstance)
    m.y
end
function SOI.getZ(m::CSDPSolverInstance)
    m.Z
end
