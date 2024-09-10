import DataStructures as DS
using Random

in_same_set(ds::DS.IntDisjointSets, x, y) = DS.in_same_set(ds, x, y)
in_same_set(ds::CDS.AbstractDisjointSet, x, y) = CDS.same_set(ds, x, y)

function union_bench(ds, r)
    for i in axes(r, 2)
        x, y = r[1, i], r[2, i]
        union!(ds, x, y)
    end

    ans = [true for _ in axes(r, 2)]
    for i in axes(r, 2)
        x, y = r[1, i], r[2, i]
        ans[i] = in_same_set(ds, x, y)
    end
    @assert all(ans)

    return ds
end

function union_bench_thr(ds, r)
    Threads.@threads for i in axes(r, 2)
        x, y = r[1, i], r[2, i]
        union!(ds, x, y)
    end
    ans = [true for _ in axes(r, 2)]
    Threads.@threads for i in axes(r, 2)
        x, y = r[1, i], r[2, i]
        ans[i] = in_same_set(ds, x, y)
    end
    @assert all(ans)
    return ds
end

@testset "Correctness vs DataStructures" begin
    for N in 3:2:20
        for K in 3:2:N+1
            Random.seed!(13)
            r = rand(1:2^N, 2, 2^K)
            n = 2^N

            cds = union_bench_thr(CDS.ConcurrentDisjointSet(n), r)
            ds = union_bench(CDS.DisjointSet(n), r)
            baseline = union_bench(DS.IntDisjointSets(n), r)
            ans = true
            for (x, y) in eachrow(r)
                ans &=
                    in_same_set(cds, x, y) ==
                    in_same_set(ds, x, y) ==
                    in_same_set(baseline, x, y)
            end
            @test ans
        end
    end
end
