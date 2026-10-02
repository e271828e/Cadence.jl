The pass also parametrizes FlightPhysics' payload and value types, the walked
tier of [§7.2][s7-2], about 25 structs. These are the quaternion/attitude
family, `Wrench`, `FrameTransform`, `MassProperties`, `KinData`, `AirData`,
geodesy value types, `TerrainData` and continuous output structs. What
actually needs genericity covers roughly half of Flight.jl's type inventory.
`Quaternion` becomes `Quaternion{N,T} <: AbstractVector{T}`. By invariance,
`Float64` instances still match every existing `AbstractVector{Float64}`
method, so existing behavior is untouched. Flight.jl's parameters and
definitions, the pinned tier of [§7.2][s7-2], stay `Float64` and need no
migration. Flight.jl's math already mostly follows the first author rule of
[§7.2][s7-2], writing `<:Real` or nothing in place of a `::Float64` argument
annotation. The `*` method in Flight.jl's
`attitude.jl` is the live example pattern for the third rule, no
`::SomeType{Float64}` return-type annotations on the continuous path.
