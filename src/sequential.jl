struct DisjointSet <: AbstractDisjointSet
    nodes::Memory{Node}
    function DisjointSet(n)
        nodes = Memory{Node}(undef, n)
        @inbounds for i in eachindex(nodes)
            nodes[i] = Node(i)
        end
        return new(nodes)
    end
end

Base.@propagate_inbounds Base.getindex(ds::DisjointSet, i::Integer) =
    ds.nodes[i]
Base.@propagate_inbounds Base.setindex!(ds::DisjointSet, r::Node, i::Integer) =
    ds.nodes[i] = r

function same_set(ds::DisjointSet, i::Integer, j::Integer)
    u = find(ds, i)
    v = find(ds, j)
    return u == v
end

function Base.union!(ds::DisjointSet, i::Integer, j::Integer)
    u = find(ds, i)
    v = find(ds, j)
    return if u ≠ v
        parent(link(ds, u, v))
    else
        parent(u)
    end
end

find(ds::DisjointSet, args...) = find_halve(ds, args...)
link(ds::DisjointSet, args...) = link_byrank(ds, args...)

# particular implementations of find
function find_naive(ds::DisjointSet, i::Integer)
    u = ds[i]
    @inbounds v = ds[parent(u)]
    @inbounds while v ≠ u
        u = v
        v = ds[parent(u)]
    end
    return v
end

function find_compress(ds::DisjointSet, i::Integer)
    root = find_naive(ds, i)
    u = ds[i]
    @inbounds while u ≠ root
        u = ds[i]
        ds[i] = root # u.parent = root
        i = parent(u)
    end
    return root
end

function find_split(ds::DisjointSet, i::Integer)
    u = ds[i]
    @inbounds v = ds[parent(u)]
    @inbounds w = ds[parent(v)]
    @inbounds while u ≠ w # in the paper v ≠ w is a mistake
        ds[i] = v # this is `u.parent = w` since `parent(v) == w`
        i = parent(u)
        u = v
        v = ds[parent(u)]
        w = ds[parent(v)]
    end
    return v
end

function find_halve(ds::DisjointSet, i::Integer)
    u = ds[i]
    @inbounds v = ds[parent(u)]
    @inbounds w = ds[parent(v)]
    @inbounds while v ≠ w
        ds[i] = v # u.parent = w
        i = parent(v)
        u = w
        v = ds[parent(u)]
        w = ds[parent(v)]
    end
    return v
end

function link_byrank(ds::DisjointSet, u::Node, v::Node)
    r, s = rank(u), rank(v)
    return if r < s
        @inbounds ds[parent(v)] = u
    elseif r > s
        @inbounds ds[parent(u)] = v
    else
        root = Node(parent(u), rank(u) + oftype(r, 1))
        @inbounds ds[parent(v)] = root
        @inbounds ds[parent(u)] = root
    end
end

function link_byindex(ds::DisjointSet, u::Node, v::Node)
    return if u < v # comparison by parents
        @inbounds ds[parent(u)] = v
    else
        @inbounds ds[parent(v)] = u
    end
end
