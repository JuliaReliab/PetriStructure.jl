"""
WELL1024a random number generator

Copyright:  Francois Panneton and Pierre L'Ecuyer, Université de Montréal
            Makoto Matsumoto, Hiroshima University

Notice:     This code can be used freely for personal, academic,
            or non-commercial purposes. For commercial purposes,
            please contact P. L'Ecuyer at: lecuyer@iro.UMontreal.ca

This code can also be used under the terms of the GNU General Public
License as published by the Free Software Foundation, either version 3
of the License, or any later version. See the GPL licence at URL
http://www.gnu.org/licenses
"""

using Random
import Random: rand, AbstractRNG

"""
    WELL1024a

WELL1024a random number generator state.

# Fields
- `state::Vector{UInt32}`: Internal state array of 32 unsigned integers
- `state_i::Int`: Current state index

# Example
```julia
rng = WELL1024a(123456789)
x = rand(rng)  # Generate a random Float64 in [0, 1)
```
"""
mutable struct WELL1024a <: AbstractRNG
    state::Vector{UInt32}
    state_i::Int
end

"""
    WELL1024a(seed::Integer)

Create a WELL1024a RNG initialized with the given seed.
"""
function WELL1024a(seed::Integer)
    rng = WELL1024a(Vector{UInt32}(undef, 32), 1)
    init_well1024a!(rng, UInt32(seed))
    return rng
end

"""
    WELL1024a(init::Vector{UInt32})

Create a WELL1024a RNG initialized with an array of initial values.
"""
function WELL1024a(init::Vector{UInt32})
    length(init) == 32 || throw(ArgumentError("init must have length 32"))
    rng = WELL1024a(copy(init), 1)
    return rng
end

"""
    init_well1024a!(rng::WELL1024a, seed::UInt32)

Initialize the WELL1024a generator with a seed value.
"""
function init_well1024a!(rng::WELL1024a, seed::UInt32)
    MASK32 = 0xffffffff % UInt32
    JMAX = 32
    
    A = Vector{UInt32}(undef, JMAX)
    A[1] = seed
    for i in 2:JMAX
        A[i] = (663608941 % UInt32 * A[i-1]) & MASK32
    end
    
    init_well1024a!(rng, A)
end

"""
    init_well1024a!(rng::WELL1024a, init::Vector{UInt32})

Initialize the WELL1024a generator with an array of initial values.
"""
function init_well1024a!(rng::WELL1024a, init::Vector{UInt32})
    length(init) == 32 || throw(ArgumentError("init must have length 32"))
    rng.state_i = 1  # Julia uses 1-based indexing
    copyto!(rng.state, init)
    return rng
end

# Helper macros translated from C
@inline function mat0pos(t::Int, v::UInt32)
    v ⊻ (v >> t)
end

@inline function mat0neg(t::Int, v::UInt32)
    v ⊻ (v << (-t))
end

@inline identity_op(v::UInt32) = v

# Constants for WELL1024a
const R = 32
const M1 = 3
const M2 = 24
const M3 = 10
const FACT = 2.32830643653869628906e-10

"""
    rand(rng::WELL1024a, ::Type{Float64})

Generate a random Float64 value in [0, 1) using the WELL1024a algorithm.
"""
function Base.rand(rng::WELL1024a, ::Type{Float64})
    
    # Compute indices (convert to 1-based indexing)
    state_i = rng.state_i
    
    # V0, VM1, VM2, VM3, VRm1 with 1-based indexing
    # In C: state_i ranges from 0 to 31
    # In Julia: state_i ranges from 1 to 32
    idx_v0 = state_i
    idx_vm1 = mod1(state_i + M1, R)
    idx_vm2 = mod1(state_i + M2, R)
    idx_vm3 = mod1(state_i + M3, R)
    idx_vrm1 = mod1(state_i + 31, R)
    idx_newv0 = mod1(state_i + 31, R)
    idx_newv1 = state_i
    
    V0 = rng.state[idx_v0]
    VM1 = rng.state[idx_vm1]
    VM2 = rng.state[idx_vm2]
    VM3 = rng.state[idx_vm3]
    VRm1 = rng.state[idx_vrm1]
    
    # WELL1024a algorithm
    z0 = VRm1
    z1 = identity_op(V0) ⊻ mat0pos(8, VM1)
    z2 = mat0neg(-19, VM2) ⊻ mat0neg(-14, VM3)
    
    newV1 = z1 ⊻ z2
    newV0 = mat0neg(-11, z0) ⊻ mat0neg(-7, z1) ⊻ mat0neg(-13, z2)
    
    # Update state
    rng.state[idx_newv1] = newV1
    rng.state[idx_newv0] = newV0
    
    # Update state_i: (state_i + 31) & 0x1f in C
    # In Julia with 1-based: move backwards by 1, wrap around
    rng.state_i = mod1(state_i + 31, R)
    
    # Return random value
    return Float64(rng.state[rng.state_i]) * FACT
end

# Support for rand() without type specification
Base.rand(rng::WELL1024a) = rand(rng, Float64)

# Support for generating arrays
function Base.rand(rng::WELL1024a, dims::Integer...)
    return [rand(rng, Float64) for _ in 1:prod(dims)]
end

function Base.rand(rng::WELL1024a, ::Type{Float64}, dims::Integer...)
    return [rand(rng, Float64) for _ in 1:prod(dims)]
end
