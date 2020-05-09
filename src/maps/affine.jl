
import Base: convert

# These are temporary definitions until StaticArrays updates
Base.convert(::Type{AbstractArray{T}}, v::SVector{N,S}) where {N,T,S} =
    convert(SVector{N,T}, v)
Base.convert(::Type{AbstractVector{T}}, v::SVector{N,S}) where {N,T,S} =
    convert(SVector{N,T}, v)
Base.convert(::Type{AbstractArray{T}}, v::SMatrix{M,N,S}) where {M,N,T,S} =
    convert(SMatrix{M,N,T}, v)
Base.convert(::Type{AbstractMatrix{T}}, v::SMatrix{M,N,S}) where {M,N,T,S} =
    convert(SMatrix{M,N,T}, v)

tomatrix(::Type{T}, a::Number) where {T<:Number} = a
tomatrix(::Type{SVector{N,T}}, a::Number) where {N,T} = a * one(SMatrix{N,N,T})
tomatrix(::Type{<:AbstractVector{T}}, a::Number) where {T} = a * I

"""
An affine map has the general form `y = A*x + b`.

We use `matrix(m)` and `vector(m)` to denote `A` and `b` respectively.
"""
abstract type AbstractAffineMap{T} <: Map{T} end

"Return the matrix `A` in the affine map `Ax+b`."
matrix(m::AbstractAffineMap) = copy(unsafe_matrix(m))

"Return the vector `b` in the affine map `Ax+b`."
vector(m::AbstractAffineMap) = copy(unsafe_vector(m))

applymap(m::AbstractAffineMap, x) = unsafe_matrix(m) * x + unsafe_vector(m)
function applymap!(y, m::AbstractAffineMap, x)
    mul!(y, unsafe_matrix(m), x)
    y .+= unsafe_vector(m)
    y
end

isreal(m::AbstractAffineMap{T}) where {T} = isreal(unsafe_matrix(m)) && isreal(unsafe_vector(m))

jacobian(m::AbstractAffineMap{T}) where {T} = ConstantMap{T}(matrix(m))
jacobian(m::AbstractAffineMap, x) = matrix(m)
jacdet(m::AbstractAffineMap, x) = det(unsafe_matrix(m))

islinear(map::Map) = false
islinear(map::AbstractAffineMap) = all(unsafe_vector(map) .== 0)

isaffine(map::Map) = islinear(map)
isaffine(map::AbstractAffineMap) = true

==(m1::AbstractAffineMap, m2::AbstractAffineMap) =
    (unsafe_matrix(m1) == unsafe_matrix(m2)) && (unsafe_vector(m1)==unsafe_vector(m2))

dimension(m::AbstractAffineMap) = length(unsafe_vector(m))


"A `LinearMap` is an affine map that represents `y = A*x`."
struct LinearMap{T,AA} <: AbstractAffineMap{T}
    A   ::  AA
end

# We allow any object A
LinearMap{T}(A) where {T} = LinearMap{T,typeof(A)}(A)

# But we provide more support for three cases:
# a is a scalar, a static matrix or a general matrix
const ScalarLinearMap{T,AA<:Number} = LinearMap{T,AA}
const StaticLinearMap{T<:SVector,AA<:SMatrix} = LinearMap{T,AA}
const ArrayLinearMap{T<:AbstractVector,AA<:AbstractArray} = LinearMap{T,AA}

# For scalars and arrays, we make sure the element types match with T
# - A is a number: convert to eltype(T)
LinearMap{T}(A::S) where {T,S <: Number} = LinearMap{T,eltype(T)}(A)
# - T is an abstract array: convert the eltype of A to eltype(T)
LinearMap{T}(A::AbstractMatrix) where {T <: AbstractVector} = LinearMap{T}(convert(AbstractArray{eltype(T)}, A))
LinearMap{T}(A::AbstractMatrix{S}) where {S,T <: AbstractVector{S}} = LinearMap{T,typeof(A)}(A)
# - T is an SVector: convert A to an SMatrix (fails if A is rectangular)
LinearMap{T}(A::AbstractMatrix{S}) where {N,S,T <: SVector{N,S}} = LinearMap{T}(convert(SMatrix{N,N,S},A))
LinearMap{T}(A::SMatrix{M,N,S}) where {M,N,S,T <: SVector{N,S}} = LinearMap{T,typeof(A)}(A)

LinearMap(A::T) where {T <: Number} = LinearMap{T}(A)
LinearMap(A::SMatrix{M,N,T}) where {M,N,T} = LinearMap{SVector{N,T}}(A)
LinearMap(A::AbstractArray{T}) where {T} = LinearMap{Vector{T}}(A)

unsafe_matrix(m::LinearMap) = m.A
unsafe_matrix(m::ScalarLinearMap{T}) where {T<:AbstractVector} = tomatrix(T, m.A)

unsafe_vector(m::LinearMap{T}) where {T<:SVector} = zero(T)
unsafe_vector(m::LinearMap{T}) where {T<:Number} = zero(T)
unsafe_vector(m::LinearMap{T}) where {T<:AbstractVector} = zeros(size(m.A,1))

convert(::Type{Map{T}}, m::LinearMap{T}) where {T} = m
convert(::Type{Map{T}}, m::LinearMap{S}) where {S,T} = LinearMap{T}(m.A)

convert(::Type{Map{T}}, a::Number) where {T} = LinearMap{T}(a)

applymap(m::LinearMap, x) = m.A * x
applymap!(y, m::LinearMap, x) = mul!(y, m.A, x)

==(m1::LinearMap, m2::LinearMap) = unsafe_matrix(m1) == unsafe_matrix(m2)

islinear(map::LinearMap) = true

inv(m::LinearMap) = LinearMap(inv(m.A))
# Preserve the action on vectors with a number type
inv(m::LinearMap{T,AA}) where {T<:AbstractVector,AA<:Number} = LinearMap{T}(inv(m.A))

inverse(m::LinearMap, x) = m.A \ x

leftinverse(m::LinearMap) =  LinearMap(pinv(m.A))
rightinverse(m::LinearMap) = LinearMap(pinv(m.A))


"Translation represents `y = x + b`."
struct Translation{T,B} <: AbstractAffineMap{T}
    b   ::  B
end

Translation{T}(b) where {T} = Translation{T,typeof(b)}(b)

Translation{T}(b::Number) where {T<:Number} = Translation{T,T}(b)
Translation{T}(b::AbstractVector{S}) where {S,T<:AbstractVector{S}} =
    Translation{T,typeof(b)}(b)
Translation{T}(b::AbstractVector{S}) where {S,U,T<:AbstractVector{U}} =
    Translation{T}(convert(AbstractVector{U}, b))
Translation{T}(b::AbstractVector{S}) where {N,S,T<:SVector{N,S}} =
    Translation{T}(convert(SVector{N,S}, b))
Translation{T}(b::SVector{N,S}) where {N,S,T<:SVector{N,S}} =
    Translation{T,typeof(b)}(b)

Translation(b::T) where {T} = Translation{T}(b)

size(m::Translation{<:Number}) = (dimension(m), 1)
size(m::Translation) = (dimension(m), dimension(m))

unsafe_matrix(m::Translation) = identitymatrix(m)
unsafe_vector(m::Translation) = m.b

convert(::Type{Map{T}}, m::Translation{T}) where {T} = m
convert(::Type{Map{T}}, m::Translation{S}) where {S,T} = Translation{T}(m.b)

applymap(m::Translation, x) = x + m.b
applymap!(y, m, x) = y .+= x .+ m.b

inv(m::Translation{T}) where {T} = Translation{T}(-m.b)

inverse(m::Translation, x) = x - m.b


"`AffineMap` represents `y = A*x + b`."
struct AffineMap{T,AA,B} <: AbstractAffineMap{T}
    A   ::  AA
    b   ::  B
end

const ScalarAffineMap{T,AA<:Number,B} = AffineMap{T,AA,B}
const StaticAffineMap{T<:SVector,AA<:SMatrix} = AffineMap{T,AA}
const ArrayAffineMap{T<:AbstractVector,AA<:AbstractArray} = AffineMap{T,AA}

# Fallback routine for generic A and b, special cases follow
AffineMap{T}(A, b) where {T} = AffineMap{T,typeof(A),typeof(b)}(A, b)

# We distinguish between (1) T is a number, (2) T is an AbstractVector and (3) T is an SVector
# (1) T is a number: convert A and b to T
AffineMap{T}(A::Number, b::Number) where {T <: Number} = AffineMap{T,T,T}(A, b)
# (2) T is an array
# - A and b are arrays: convert to eltype(T)
AffineMap{T}(A::AbstractMatrix, b::AbstractVector) where {T <: AbstractVector} =
    AffineMap{T}(convert(AbstractMatrix{eltype(T)},A), convert(AbstractVector{eltype(T)}, b))
AffineMap{T}(A::AbstractMatrix{S}, b::AbstractVector{S}) where {S,T <: AbstractVector{S}} =
    AffineMap{T,typeof(A),typeof(b)}(A, b)
# - A is a number, b a vector: convert eltype(b) to eltype(T)
AffineMap{T}(A::Number, b::AbstractVector{S}) where {S,T <: AbstractVector} =
    AffineMap{T}(A, convert(AbstractVector{eltype(T)}, b))
#   and then convert A to eltype(T) as well
AffineMap{T}(A::Number, b::AbstractVector{S}) where {S,T <: AbstractVector{S}} =
    AffineMap{T,S,typeof(b)}(A, b)
# (3) T is an SVector: we will attempt to convert A and b to static arrays too
#     If all are arrays, then the eltypes already match by the rules above
# - A and b are arrays: convert, assuming A is square (though we don't know for sure)
AffineMap{T}(A::AbstractMatrix{S}, b::AbstractVector{S}) where {N,S,T <: SVector{N,S}} =
    AffineMap{T}(convert(SMatrix{N,N,S},A), convert(SVector{N,S}, b))
# - b is an SVector: convert A to SMatrix with the right size
AffineMap{T}(A::AbstractMatrix{S}, b::SVector{M,S}) where {M,N,S,T <: SVector{N,S}} =
    AffineMap{T}(convert(SMatrix{M,N,S},A), b)
AffineMap{T}(A::SMatrix{M,N,S}, b::SVector{M,S}) where {M,N,S,T <: SVector{N,S}} =
    AffineMap{T,typeof(A),typeof(b)}(A, b)
# - A is a number, b is a vector: convert and assume that b has the same length as T (we don't know)
AffineMap{T}(A::Number, b::AbstractVector{S}) where {N,S,T <: SVector{N,S}} =
    AffineMap{T}(A, convert(SVector{N,S}, b))
AffineMap{T}(A::Number, b::SVector{M,S}) where {M,N,S,T <: SVector{N,S}} =
    AffineMap{T,S,typeof(b)}(A, b)


AffineMap(A::Number, b::Number) = AffineMap(promote(A,b)...)
AffineMap(A::T, b::T) where {T<:Number} = AffineMap{T}(A, b)
AffineMap(A::SMatrix{M,N,S}, b::SVector{M,T}) where {M,N,S,T} =
    AffineMap{SVector{N,promote_type(S,T)}}(A, b)
AffineMap(A::S, b::SVector{N,T}) where {S<:Number,N,T} =
    AffineMap{SVector{N,promote_type(S,T)}}(A, b)
AffineMap(A::AbstractMatrix{S}, b::AbstractVector{T}) where {S,T} =
    AffineMap{Vector{promote_type(S,T)}}(A, b)
AffineMap(A::S, b::AbstractVector{T}) where {S<:Number,T} =
    AffineMap{Vector(promote_type(S,T))}(A, b)

convert(::Type{Map{T}}, m::AffineMap{T}) where {T} = m
convert(::Type{Map{T}}, m::AffineMap{S}) where {S,T} = AffineMap{T}(m.A, m.b)
convert(::Type{AffineMap{T}}, m::AffineMap) where {T} = convert(Map{T}, m)

unsafe_matrix(m::AffineMap) = m.A
unsafe_matrix(m::ScalarAffineMap{T}) where {T<:AbstractVector} = tomatrix(T, m.A)

unsafe_vector(m::AffineMap) = m.b

applymap(m::AffineMap, x) = m.A * x .+ m.b
function applymap!(y, m::AffineMap, x)
    mul!(y, m.A, x)
    y .+= m.b
    y
end

# If y = a*x+b, then x = inv(a)*(y-b).
inv(m::AffineMap) = AffineMap(inv(m.A), -inv(m.A)*m.b)

inverse(m::AffineMap, x) = m.A \ (x-m.b)

convert(::Type{AbstractAffineMap{T}}, ::IdentityMap) where {T} = LinearMap{T}(1)
convert(::Type{<:LinearMap{T}}, ::IdentityMap) where {T} = LinearMap{T}(1)


########################
# Some useful functions
########################

"Make the linear map y = a*x + b."
linear_map(a, b) = AffineMap(a, b)

"Map the interval [a,b] to the interval [c,d]."
interval_map(a, b, c, d) = linear_map((d-c)/(b-a), c - a*(d-c)/(b-a))


## Simple scaling maps

"Scale all variables by a."
scaling_map(a) = LinearMap(a)

"Scale the variables by a and b."
scaling_map(a, b) = LinearMap(SMatrix{2,2}(a, 0, 0, b))

"Scale the variables by a, b and c."
scaling_map(a, b, c) = LinearMap(SMatrix{3,3}(a, 0, 0,  0, b, 0,  0, 0,c))

"Scale the variables by a, b, c and d."
scaling_map(a, b, c, d) = LinearMap(SMatrix{4,4}(a,0,0,0, 0,b,0,0, 0,0,c,0, 0,0,0,d))




##############
# Arithmetic
##############

mapcompose(m1::AbstractAffineMap, m2::AbstractAffineMap) = affine_composition(m1, m2)

"""
Compute the affine map that represents map2 after map1, that is:
`y = a2*(a1*x+b1)+b2 = a2*a1*x + a2*b1 + b2`.
"""
affine_composition(map1::AbstractAffineMap, map2::AbstractAffineMap) =
    AffineMap(unsafe_matrix(map2) * unsafe_matrix(map1), unsafe_matrix(map2)*unsafe_vector(map1) + unsafe_vector(map2))

affine_composition(map1::LinearMap, map2::LinearMap) =
    LinearMap(unsafe_matrix(map2) * unsafe_matrix(map1))

affine_composition(map1::Translation, map2::Translation) =
    Translation(unsafe_vector(map2) + unsafe_vector(map1))
