module DomainSets

# We use static vectors internally

using StaticArrays
using Base

using LinearAlgebra, Statistics
import LinearAlgebra: cross, ×, pinv

using IntervalSets

################################
## Exhaustive list of imports
################################

# Generated functions
import Base: @ncall

# Operator symbols
import Base: *, +, -, /, \, ^,
    |, &,
    ∪, ∩,
    ==, isapprox,
    ∘,
    # Set operations
    intersect, union, setdiff, in, isempty, minimum, maximum,
    issubset,
    # Arrays
    size, length, ndims, getindex, eltype, ndims, hash,
    inv, isreal, zero,
    # Types, promotions and conversions
    convert, widen, promote_rule,
    # Display
    show,
    # Various
    Bool

# IntervalSets
import IntervalSets: (..), endpoints, Domain, AbstractInterval, TypedEndpointsInterval,
                        leftendpoint, rightendpoint, isleftopen, isleftclosed,
                        isrightopen, isrightclosed, isopen, isclosed,
                        infimum, supremum
export ..


################################
## Exhaustive list of exports
################################

## Utils

# from util/common.jl
export subeltype,
    dimension,
    prectype
# from util/tensorproducts.jl
export cartesianproduct


## Maps

# from maps/maps.jl
export AbstractMap, applymap, jacobian, linearize
export domaintype, codomaintype
export left_inverse, right_inverse
export apply_inverse, apply_left_inverse, apply_right_inverse
export image
# from maps/composite_map.jl
export CompositeMap
export ∘
# from maps/productmap.jl
export ProductMap
export tensorproduct
# from maps/basic_maps.jl
export IdentityMap, ConstantMap
# from maps/affine_maps.jl
export AffineMap, Translation, LinearMap
export islinear
export linear_map, interval_map, scaling_map, rotation_map, translation_map
# from maps/coordinates.jl
export CartToPolarMap, PolarToCartMap


## Generic domains

# from generic/domain.jl
export Domain, EuclideanDomain, VectorDomain,
    approx_in,
    isclosed, iscompact,
    boundary, ∂,
    point_in_domain

# from generic/derived_domain.jl
export DerivedDomain
export superdomain

# from generic/productdomain.jl
export ProductDomain, cross, ×

# from generic/setoperations.jl
export UnionDomain, IntersectionDomain, DifferenceDomain
export TranslatedDomain

# from generic/mapped_domain.jl
export source, target


# from generic/arithmetics.jl
export rotate

export infimum, supremum


## Specific domains

# from domains/trivial.jl
export EmptySpace, FullSpace,
    ℤ, ℚ, ℝ, ℂ, ℝ1, ℝ2, ℝ3, ℝ4
# from domains/interval.jl
export AbstractInterval, Interval, UnitInterval, ChebyshevInterval,
    OpenInterval, ClosedInterval,
    leftendpoint, rightendpoint, isleftopen, isrightopen,
    cardinality,
    HalfLine, NegativeHalfLine
# from domains/simplex.jl
export EuclideanUnitSimplex, VectorUnitSimplex,
    center, corners
# from domains/point.jl
export Point
# from domains/ball.jl
export UnitCircle, UnitSphere, UnitHyperSphere,
    UnitDisk, UnitBall, UnitHyperBall,
    EuclideanUnitBall, VectorUnitBall,
    EuclideanUnitSphere, VectorUnitSphere,
    ellipse, ellipse_shape, cylinder,
    parameterization, gradient

include("util/common.jl")
include("util/products.jl")

include("maps/maps.jl")
include("maps/composite_map.jl")
include("maps/productmap.jl")
include("maps/basic_maps.jl")
include("maps/affine_map.jl")
include("maps/coordinates.jl")

include("generic/domain.jl")
include("generic/lazy.jl")
include("generic/derived_domain.jl")
include("generic/productdomain.jl")
include("generic/setoperations.jl")
include("generic/mapped_domain.jl")
include("generic/promotion.jl")
include("generic/arithmetics.jl")

include("domains/trivial.jl")
include("domains/point.jl")
include("domains/interval.jl")
include("domains/simplex.jl")
include("domains/ball.jl")

end # module
