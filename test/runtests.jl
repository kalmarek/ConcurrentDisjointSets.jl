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

    include("correctness.jl")
end

