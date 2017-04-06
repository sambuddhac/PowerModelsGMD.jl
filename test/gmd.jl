@testset "test ac data" begin
    @testset "4-bus case ac opf" begin
        result = run_ac_opf("../test/data/b4gic.json", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 116914; atol = 1e2)
    end

    @testset "6-bus case ac opf" begin
        result = run_ac_opf("../test/data/b6gic_nerc.json", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 980; atol = 1e0)
    end

    @testset "19-bus case ac opf" begin
        result = run_ac_opf("../test/data/epri21.json", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 401802; atol = 1e2)
    end

    @testset "150-bus case ac opf" begin
        result = run_ac_opf("../test/data/uiuc150.json", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 893768; atol = 1e2)
    end
end


@testset "test ac gmd" begin
    @testset "4-bus case solution" begin
        result = run_ac_gmd("../test/data/b4gic.json", ipopt_solver)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 1.398e5; atol = 1e2)
    end

    @testset "4-bus case" begin
        data = PowerModels.parse_file("../test/data/b4gic.json")
        result = run_ac_gmd(data, ipopt_solver, setting=setting)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 1.398e5; atol = 1e2)

        PowerModels.update_data(data, result["solution"])
        PowerModelsGMD.add_gmd_data(data)

        # changes due to the fact that becouse update_data does not do some of the stuff that merge_result does
        @test isapprox(data["bus"]["1"]["gmd_vdc"], -32, atol=0.1)
        #@test isapprox(data["gmd_bus"]["3"]["gmd_vdc"], -32, atol=0.1)
        @test isapprox(data["bus"]["1"]["vm"], 0.933660, atol=1e-3)
        @test isapprox(data["branch"]["3"]["p_from"], -1007.680670, atol=1e-3)
        @test isapprox(data["branch"]["3"]["q_from"], -434.504704, atol=1e-3)
        #@test isapprox(data["branch"]["3"]["q_from"] + data["branch"]["3"]["gmd_qloss"], -434.504704, atol=1e-3)
    end

    @testset "6-bus case" begin
        data = PowerModels.parse_file("../test/data/b6gic_nerc.json")
        result = run_ac_gmd(data, ipopt_solver, setting=setting)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 11832.5; atol = 1e2)

        PowerModels.update_data(data, result["solution"])
        PowerModelsGMD.add_gmd_data(data)

        @test isapprox(data["bus"]["2"]["gmd_vdc"], -23.022192, atol=1e-1)
        @test isapprox(data["bus"]["2"]["vm"], 0.92784494, atol=1e-3)
        # check that kcl with qloss is being done correctly
        # br23
        @test isapprox(data["branch"]["2"]["q_from"], -36.478387, atol=1e-3)
        @test isapprox(data["branch"]["2"]["q_to"], 49.0899781, atol=1e-3)
        # T2 gwye-gwye auto
        @test isapprox(data["branch"]["4"]["q_from"], -36.402340, atol=1e-3)
        @test isapprox(data["branch"]["4"]["q_to"], 36.4783871, atol=1e-3)
        # br45
        @test isapprox(data["branch"]["5"]["p_from"], -100.40386, atol=1e-3)
        @test isapprox(data["branch"]["5"]["p_to"], 100.648681, atol=1e-3)
        @test isapprox(data["branch"]["5"]["q_from"], -49.089978, atol=1e-3)
        @test isapprox(data["branch"]["5"]["q_to"], 48.6800005, atol=1e-3)
    end

    @testset "19-bus case" begin
        data = PowerModels.parse_file("../test/data/epri21.json")
        result = run_ac_gmd(data, ipopt_solver, setting=setting)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 5.08585e5; atol = 1e2)

        PowerModels.update_data(data, result["solution"])
        PowerModelsGMD.add_gmd_data(data)

        @test isapprox(data["bus"]["6"]["gmd_vdc"], 44.31, atol=1e-1) # PowerModels: gmd_vdc = 44.26301987818914
        #@printf "gmd_vdc[17] = %f\n" data["bus"][17]["gmd_vdc"]
        @test isapprox(data["bus"]["17"]["gmd_vdc"],  -41.01, atol=1e-1) # PowerModels: gmd_vdc = -40.95101258160489
        #@test isapprox(data["bus"]["6"]["vm"], 1.05, atol=1e-3)
    end

    @testset "150-bus case" begin
        data = PowerModels.parse_file("../test/data/uiuc150.json")
        result = run_ac_gmd(data, ipopt_solver, setting=setting)

        @test result["status"] == :LocalOptimal
        @test isapprox(result["objective"], 9.52847e5; atol = 1e2)

        PowerModels.update_data(data, result["solution"])
        PowerModelsGMD.add_gmd_data(data)

        @test isapprox(data["bus"]["92"]["gmd_vdc"], 7.00, atol=1e-1) # PowerModels: gmd_vdc = 44.26301987818914
        @test isapprox(data["bus"]["99"]["gmd_vdc"], -32.74, atol=1e-1) # PowerModels: gmd_vdc = 44.26301987818914
    end
end




