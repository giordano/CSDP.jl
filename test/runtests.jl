using CSDP
using Base.Test

vec = Cdouble[1.0, 2.0, 0.0, -1.0]
l = length(vec)
inc = 1
const llapack = Libdl.dlpath(LinAlg.LAPACK.liblapack)
const dasum = WORD_SIZE == 64 ? :dasum_64_ : :dasum_
n1 = ccall((dasum, llapack), Float64, (Ptr{Int}, Ptr{Cdouble}, Ptr{Int}), &l, vec, &inc)
@assert abs(n1 - 4) < 1e-15 "n1 = $n1"

n1 = ccall( (:norm1, CSDP.csdp), Float64, (Cint, Ptr{Cdouble}), length(vec), vec)
@assert abs(n1 - 4) < 1e-15 "n1 = $n1"
