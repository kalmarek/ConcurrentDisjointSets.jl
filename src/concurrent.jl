struct ConcurrentDisjointSet <: AbstractDisjointSet
    nodes::AtomicMemory{Node}
    function ConcurrentDisjointSet(n)
        nodes = AtomicMemory{Node}(undef, n)
        @inbounds for i in eachindex(nodes)
            @atomic nodes[i] = Node(i)
        end
        return new(nodes)
    end
end

Base.@propagate_inbounds Base.getindex(ds::ConcurrentDisjointSet, i::Integer) =
    @atomic ds.nodes[i]
Base.@propagate_inbounds Base.setindex!(
    ds::ConcurrentDisjointSet,
    v::Node,
    i::Integer,
) = @atomic ds.nodes[i] = v

Base.@propagate_inbounds function cas(
    ds::ConcurrentDisjointSet,
    idx,
    expected,
    desired,
)
    return @atomicreplace ds.nodes[idx] expected => desired
end

function same_set(ds::ConcurrentDisjointSet, i::Integer, j::Integer)
    u = find(ds, i)
    v = find(ds, j)
    @inbounds while u ≠ v
        w = ds[parent(u)]
        if u == w
            return false
        else
            u = find(ds, parent(u))
            v = find(ds, parent(v))
        end
    end
    return true
end

function Base.union!(ds::ConcurrentDisjointSet, i::Integer, j::Integer)
    u = find(ds, i)
    v = find(ds, j)
    while u ≠ v
        link(ds, u, v)
        u = find(ds, parent(u))
        v = find(ds, parent(v))
    end
    return parent(u)
end

find(ds::ConcurrentDisjointSet, args...) = find_split(ds, args...)
link(ds::ConcurrentDisjointSet, args...) = link_byrank(ds, args...)

function find_naive(ds::ConcurrentDisjointSet, i::Integer)
    u = ds[i]
    @inbounds v = ds[parent(u)]
    @inbounds while u ≠ v
        u = v
        v = ds[parent(u)]
    end
    return u
end

function find_split(ds::ConcurrentDisjointSet, i::Integer)
    u = ds[i]
    @inbounds v = ds[parent(u)]
    @inbounds w = ds[parent(v)]
    @inbounds while u ≠ w
        cas(ds, i, u, v)
        i = parent(u)
        u = v
        v = ds[parent(u)]
        w = ds[parent(v)]
    end
    return v
end

function find_split2(ds::ConcurrentDisjointSet, i::Integer)
    u = ds[i]
    @inbounds v = ds[parent(u)]
    @inbounds w = ds[parent(v)]
    @inbounds while u ≠ w
        result = cas(ds, i, u, v)
        v = ds[parent(u)]
        w = ds[parent(v)]

        # if !result.success # conditional two-try splitting?
        cas(ds, i, u, v)
        i = parent(u)
        u = v
        v = ds[parent(u)]
        w = ds[parent(v)]
        # end
    end
    return v
end

function link_byindex(ds::ConcurrentDisjointSet, u::Node, v::Node)
    return if u < v
        @inbounds cas(ds, parent(u), u, v)
    else
        @inbounds cas(ds, parent(v), v, u)
    end
end

function link_byrank(ds::ConcurrentDisjointSet, u::Node, v::Node)
    r = rank(u)
    s = rank(v)
    return if r < s
        @inbounds cas(ds, parent(u), u, Node(parent(v), r))
    elseif r > s
        @inbounds cas(ds, parent(v), v, Node(parent(u), s))
    elseif u < v
        # note : these don't link but union! will attempt to link again
        # which will end up in one of the above cases!
        @inbounds cas(ds, parent(u), u, Node(parent(u), r + 1))
    else
        @inbounds cas(ds, parent(v), v, Node(parent(v), s + 1))
    end
end
