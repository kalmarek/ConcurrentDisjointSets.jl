using ConcurrentDisjointSets
import ConcurrentDisjointSets as CDS
using Test


@testset "ConcurrentDisjointSet" begin
    @testset "Node" begin
        r = CDS.Node(15)
        @test parent(r) == 15
        @test CDS.rank(r) == 0

        r2 = CDS.Node(parent(r), CDS.rank(r) + 1)
        r3 = CDS.Node(parent(r) + 1, CDS.rank(r))

        @test parent(r) == 15
        @test CDS.rank(r) == 0
        @test CDS.rank(CDS.Node(1, 257)) == 1

        @test r == r2
        @test r != r3

        @test r ≤ r2
        @test !(r < r2)
        @test r < r3
        @test !(r3 < r2)
        @test !(r3 ≤ r2)
    end

    @testset "DisjointSet" begin
        U = CDS.DisjointSet(5)
        @test length(U) == 5
        @test collect(U) isa Vector{Int}
        @test collect(U) == 1:5

        @test union!(U, 3, 4) == 3
        @test length(U) == 4
        @test collect(U) == [1, 2, 3, 5]
    end

    @testset "ConcurrentDisjointSet" begin
        U = CDS.ConcurrentDisjointSet(5)
        @test parent(CDS.find(U, 2)) == 2
        @test union!(U, 1, 2) == 1
        @test parent(CDS.find(U, 2)) == 1
        @test U[1] == CDS.Node(1, 1)
        @test U[2] == CDS.Node(1, 0)
        @test length(U) == 4
        @test collect(U) == [1, 3, 4, 5]
    end

    @testset "compressing, halving, splitting" begin
        function example_DS(DS, N)
            U = DS(N)
            for i in 2:N
                U[i] = CDS.Node(i - 1)
            end
            return U
        end

        @testset "sequential" begin
            N = 8
            dU = example_DS(CDS.DisjointSet, N)

            CDS.find_compress(dU, N)
            # all pointing to CDS.Node(1)
            @test all(dU[i] == CDS.Node(1) for i in 1:N)

            dU = example_DS(CDS.DisjointSet, N)
            CDS.find_halve(dU, N)
            # 1 ← 2 ← 4 ← 6 ← 8
            #       ↖   ↖   ↖
            #         3   5   7
            @test dU[8] == dU[7] == CDS.Node(6)
            @test dU[6] == dU[5] == CDS.Node(4)
            @test dU[4] == dU[3] == CDS.Node(2)
            @test dU[2] == dU[1] == CDS.Node(1)

            dU = example_DS(CDS.DisjointSet, N)
            CDS.find_split(dU, N)
            # 1 ← 2 ← 4 ← 6 ← 8
            #   ↖
            #     3 ← 5 ← 7
            @test dU[8] == CDS.Node(6)
            @test dU[6] == CDS.Node(4)
            @test dU[4] == CDS.Node(2)
            @test dU[2] == CDS.Node(1)

            @test dU[7] == CDS.Node(5)
            @test dU[5] == CDS.Node(3)
            @test dU[3] == CDS.Node(1)
        end
        @testset "concurrent" begin
            N = 8
            dU = example_DS(CDS.ConcurrentDisjointSet, N)

            CDS.find_split(dU, N)
            # 1 ← 2 ← 4 ← 6 ← 8
            #   ↖
            #     3 ← 5 ← 7
            @test dU[8] == CDS.Node(6)
            @test dU[6] == CDS.Node(4)
            @test dU[4] == CDS.Node(2)
            @test dU[2] == CDS.Node(1)

            @test dU[7] == CDS.Node(5)
            @test dU[5] == CDS.Node(3)
            @test dU[3] == CDS.Node(1)

            CDS.find_split2(dU, N)
            # 1 ← 2 ← 4 ← 6 ← 8
            #   ↖
            #     3 ← 5 ← 7
            @test dU[8] == CDS.Node(6)
            @test dU[6] == CDS.Node(4)
            @test dU[4] == CDS.Node(2)
            @test dU[2] == CDS.Node(1)

            @test dU[7] == CDS.Node(5)
            @test dU[5] == CDS.Node(3)
            @test dU[3] == CDS.Node(1)
        end
    end

    include("correctness.jl")
end
