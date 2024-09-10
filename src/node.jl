primitive type Node 64 end

const __RANKSHIFT = 56
const __PARENTMASK = 0x00ffffffffffffff

function Node(parent::Integer, rank::Integer = UInt(0))
    rk = UInt64(rank) << __RANKSHIFT
    prnt = UInt64(parent) & __PARENTMASK
    z = rk | prnt
    return reinterpret(Node, z)
end

function Base.parent(rec::Node)
    z = reinterpret(UInt64, rec)
    return reinterpret(Int, z & __PARENTMASK)
end

function rank(rec::Node)
    z = reinterpret(UInt64, rec)
    return UInt8(z >> __RANKSHIFT)
end

function Base.show(io::IO, r::Node)
    return print(io, (parent = parent(r), rank = rank(r)))
end

Base.hash(rec::Node, h) = hash(parent(rec), hash(Node, h))
Base.:(==)(rec1::Node, rec2::Node) = parent(rec1) == parent(rec2)

Base.isless(x::Node, y::Node) = parent(x) < parent(y)

# function Base.getproperty(rec::Node, s::Symbol)
#     s === :parent && return parent(rec)
#     s === :rank && return rank(rec)
#     throw("$(typeof(rec)) has no field $s")
# end
