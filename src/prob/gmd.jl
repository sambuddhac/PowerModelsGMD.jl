export run_gmd


"FUNCTION: run GIC current model only"
function run_gmd(file, solver; kwargs...)
    return PMs.run_model(file, ACPPowerModel, solver, post_gmd; solution_builder = get_gmd_solution, kwargs...)
end


"FUNCTION: post problem corresponding to the dc gic problem this is a linear constraint satisfaction problem"
function post_gmd(pm::PMs.AbstractPowerModel; kwargs...)

    # -- Variables -- #

    variable_dc_voltage(pm)
    variable_dc_line_flow(pm)

    # -- Constraints -- #

    # - DC network - #

    for i in PMs.ids(pm, :gmd_bus)
        Memento.debug(LOGGER, "Adding constraits for bus $i")
        constraint_dc_kcl_shunt(pm, i)
    end

    for i in PMs.ids(pm, :gmd_branch)
        constraint_dc_ohms(pm, i)
    end

end


