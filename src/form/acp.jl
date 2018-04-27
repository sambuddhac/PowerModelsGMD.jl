

"default AC constructor for GMD type problems"
ACPPowerModel(data::Dict{String,Any}; kwargs...) =
    GenericGMDPowerModel(data, PowerModels.StandardACPForm; kwargs...)

""
function variable_ac_current(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true) where T <: PowerModels.AbstractACPForm
   variable_ac_current_mag(pm,n;bounded=bounded)
end

""
function variable_ac_current_on_off(pm::GenericPowerModel{T},n::Int=pm.cnw) where T <: PowerModels.AbstractACPForm
   variable_ac_current_mag(pm,n;bounded=false) # needs to be false because this is an on/off variable
end

""
function variable_dc_current(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true) where T <: PowerModels.AbstractACPForm
   variable_dc_current_mag(pm,n;bounded=bounded)
end

""
function variable_reactive_loss(pm::GenericPowerModel{T},n::Int=pm.cnw; bounded = true) where T <: PowerModels.AbstractACPForm
   variable_qloss(pm,n;bounded=bounded)
end    
     
"""
```
sum(p[a] for a in bus_arcs)  == sum(pg[g] for g in bus_gens) - pd - gs*v^2 + pd_ls
sum(q[a] for a in bus_arcs)  == sum(qg[g] for g in bus_gens) - qd + bs*v^2 + qd_ls - qloss
```
"""
function constraint_kcl_shunt_gmd_ls(pm::GenericPowerModel{T}, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_gens, bus_loads, bus_shunts, pd, qd, gs, bs) where T <: PowerModels.AbstractACPForm
    vm = pm.var[:nw][n][:vm][i]
    p = pm.var[:nw][n][:p]
    q = pm.var[:nw][n][:q]
    pg = pm.var[:nw][n][:pg]
    qg = pm.var[:nw][n][:qg]
    qloss = pm.var[:nw][n][:qloss]
    pd_ls = pm.var[:nw][n][:pd]
    qd_ls = pm.var[:nw][n][:qd]

    @constraint(pm.model, sum(p[a]            for a in bus_arcs) == sum(pg[g] for g in bus_gens) - sum(pd[d] for d in bus_loads) - sum(gs[s] for s in bus_shunts)*vm^2 + sum(pd_ls[d] for d in bus_loads))
    @constraint(pm.model, sum(q[a] + qloss[a] for a in bus_arcs) == sum(qg[g] for g in bus_gens) - sum(qd[d] for d in bus_loads) + sum(bs[s] for s in bus_shunts)*vm^2 + sum(qd_ls[d] for d in bus_loads))
end

"Constraint for relating current to power flow"
function constraint_current(pm::GenericPowerModel{T}, n::Int, i, f_idx, f_bus, t_bus, tm) where T <: PowerModels.AbstractACPForm
    i_ac_mag = pm.var[:nw][n][:i_ac_mag][i] 
    p_fr     = pm.var[:nw][n][:p][f_idx]
    q_fr     = pm.var[:nw][n][:q][f_idx]
    vm       = pm.var[:nw][n][:vm][f_bus]          
      
    @NLconstraint(pm.model, p_fr^2 + q_fr^2 == i_ac_mag^2 * vm^2 / tm)    
end

"Constraint for relating current to power flow on/off"
function constraint_current_on_off(pm::GenericPowerModel{T}, n::Int, i, ac_max) where T <: PowerModels.AbstractACPForm
    z  = pm.var[:nw][n][:branch_z][i]
    i_ac = pm.var[:nw][n][:i_ac_mag][i]        
    @constraint(pm.model, i_ac <= z * ac_max)
    @constraint(pm.model, i_ac >= z * 0.0)      
end

"Constraint for computing thermal protection of transformers"
function constraint_thermal_protection(pm::GenericPowerModel{T}, n::Int, i, coeff, ibase) where T <: PowerModels.AbstractACPForm
    i_ac_mag = pm.var[:nw][n][:i_ac_mag][i] 
    ieff = pm.var[:nw][n][:i_dc_mag][i] 

    @constraint(pm.model, i_ac_mag <= coeff[1] + coeff[2]*ieff/ibase + coeff[3]*ieff^2/(ibase^2))    
end

"Constraint for computing qloss"
function constraint_qloss(pm::GenericPowerModel{T}, n::Int, k, i, j, K, branchMVA) where T <: PowerModels.AbstractACPForm
    qloss = pm.var[:nw][n][:qloss]
    i_dc_mag = pm.var[:nw][n][:i_dc_mag][k]
    vm = pm.var[:nw][n][:vm][i]
    
    if getlowerbound(i_dc_mag) > 0.0 || getupperbound(i_dc_mag) < 0.0
        println("Warning: DC voltage magnitude cannot take a 0 value. In ots applications, this may result in incorrect results")  
    end
        
    # K is per phase
    @constraint(pm.model, qloss[(k,i,j)] == K*vm*i_dc_mag/(3.0*branchMVA))
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

"Constraint for computing qloss"
function constraint_qloss(pm::GenericPowerModel{T}, n::Int, k, i, j) where T <: PowerModels.AbstractACPForm
    qloss = pm.var[:nw][n][:qloss]    
    @constraint(pm.model, qloss[(k,i,j)] == 0.0)
    @constraint(pm.model, qloss[(k,j,i)] == 0.0)
end

