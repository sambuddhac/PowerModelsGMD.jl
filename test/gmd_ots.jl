@testset "test qc gmd ots" begin
    @testset "OTS Test" begin
        result = run_qc_gmd_ots("../test/data/ots_test.json", gurobi_solver)
        
        println(result["objective"])
        println(result["status"])          
        
        
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 2.3416780903493064e6; atol = 1e-1)      
    end
end

@testset "test ac gmd ots" begin
    @testset "OTS Test" begin
        result = run_ac_gmd_ots("../test/data/ots_test.json", bonmin_solver)        
        @test result["status"] == :LocalOptimal || result["status"] == :Optimal
        @test isapprox(result["objective"], 2.341798831737309e6; atol = 1e-1)          
    end
end
















