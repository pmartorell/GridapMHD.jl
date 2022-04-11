
# MHD equations
# ∇⋅u = 0 in fluid
# u⋅∇(u) -ν*Δ(u) + (1/ρ)*∇(p) - (1/ρ)*(j×B) = (1/ρ)*f in fluid
# ∇⋅j = 0 in fluid and solid
# j + σ*∇(φ) - σ*(u×B) = 0 in fluid
# j + σ*∇(φ) = 0 in solid
# solving for u,p,j,φ for a given B,ν,ρ,σ
#
# One can provide characteristic quantities
# u0,B0,L
#
# To introduce these change of variables
# u = u0*ū, B = B0*B̄, j = σ*u0*B0*j̄, φ = u0*B0*L*φ̄ (I am not sure about L in φ)
# p = ρ*u0^2*p̄, f = (ρ*u0^2/L)*f̄ (option 1)
# p = σ*u0*B0*L*p̄, f = (σ*u0*B0^2)*f̄ (option 2)
#
# To solve the following equations in a scaled domain according to L
# ∇⋅ū = 0 in fluid
# ∇⋅j̄ = 0 in fluid and solid
# j̄ + ∇(φ̄) - ū×B̄ = 0 in fluid
# j̄ + ∇(φ̄) = 0 in solid
# ū⋅∇(ū) -(1/Re)*Δ(ū) + ∇(p̄) - N*(j̄×B̄) = f̄ in fluid (Option 1, CFD)
# (1/N)*ū⋅∇(ū) - (1/Ha^2)*Δ(ū) + ∇(p̄) - (j̄×B̄) = f̄ in fluid (Option 2,MHD)
#
# with
#  Re = u0*L/ν
#  Ha = B0*L*sqrt(σ/(ρ*ν))
#  N = Ha^2/Re

# In order to account for both options, the code solves these equations
#
# ∇⋅ū = 0 in fluid
# ∇⋅j̄ = 0 in fluid and solid
# j̄ + σ̄*∇(φ̄) - σ̄*(ū×B̄) = 0 in fluid
# j̄ + σ̄*∇(φ̄) = 0 in solid
# α*ū⋅∇(ū) - β*Δ(ū) + ∇(p̄) - γ*(j̄×B̄) = f̄ in fluid
#
# α = 1, β = (1/Re), γ = N (option 1,CFD)
# α = (1/N), β = (1/Ha^2), γ = 1 (option 2,MHD)
# σ̄ is 1, but is included just in case you want to solve
# the un-scaled equations directly
#
# Some boundary conditions
# (for simplicity we drop the bars, i.e. ū is simply u)
# 
# Velocity bc
# u = u (imposed strongly)
#
# Charge bc
# j = j (imposed strongly in the normal direction to the boundary)
#
# Traction bC
# # n⋅∇(u) - p*n = t
#
# Potential bc
# φ = φ (Imposed weakly)
#
# Thin wall bc
# j⋅n + cw*n⋅∇(j)⋅n = jw (imposed weakly via a penalty of value τ)

function doc_main()
  Dict(
    :ptimer=>"Instance of PTimer used to monitor times. New times are added to the given timer.",
    :debug=>"true or false. If true, setup the problem, but do not solve it. Otherwise, solve it.",
    :solver=>"Non linear solver to compute the solution. It should be an instance of some type implementing the NonlinearSolver interface of Gridap.",
    :matrix_type=>"Matrix type to assemble the problem.",
    :vector_type=>"Vector type to assemble the problem.",
    :model=>"The finite element mesh representing the union of the fluid and solid domains.",
    :k=>"Maximum interpolation order (i.e., the order used for the velocity).",
    :fluid=>"A Dict defining the fluid domain and fluid parameters. Call `doc_fluid()` for further details.",
    :solid=>"A Dict defining the solid domain and solid parameters. If not provided or set to `nothing` the solid domain is not taken into account Call `doc_solid()` for further details.",
    :bcs=>"A Dict defining the boundary conditions and other external loads. Call `doc_bcs()` for further details.",
    :unused=>"true or false. If true, allow for unused parameters. Otherwise, raise an error if unused params found."
  )
end

"""
    init_params!(params::Dict{Symbol})

Check validity of the main parameter dictionary `params`.
Valid mandatory and optional keys are detailed as follows.
If an optional key is not in `params`, it will be added in-place with its corresponding default value.


# Mandatory keys
- `:model`: The finite element mesh representing the union of the fluid and solid domains.
- `:fluid`: A `Dict` defining the fluid domain and fluid parameters.
   See [`init_params_fluid!`](@ref) for further details.
- `:bcs`: A `Dict` defining the boundary conditions and other external loads.
  See [`init_params_bcs!`](@ref) for further details.

# Optional keys
- `:solid => nothing`:
  A `Dict` defining the solid domain and solid parameters.
  If not provided or set to `nothing` the solid domain is not taken into account.
  See [`init_params_solid!`](@ref) for further details.
- `:k => 2`:
  Maximum interpolation order (i.e., the order used for the fluid velocity).
- `:solver => default_solver()`:
  Nonlinear solver to compute the solution.
    It should be an instance of some type implementing the `NonlinearSolver` interface of Gridap.
- `:debug => false`:
  If true, setup the problem, but do not solve it. Otherwise, solve it.
- `:check_valid => true`: If `true`, check that all given keys are valid. Otherwise, silently ignore invalid keys.
- `:matrix_type => SparseMatrixCSC{Float64,Int32}`:
   Matrix type to assemble the problem.
- `:vector_type => Vector{Float64}`:
  Vector type to assemble the problem.
- `:ptimer => default_ptimer(params[:model])`:
  Instance of `PTimer` used to monitor times. New time measurements are added to the given timer.
"""
function init_params!(params)

  if !isa(params,Dict{Symbol})
    error("The main paramter dict has to be a Dict{Symbol}")
  end

  # Define mandatory and optional parameters at this level
  mandatory = Dict(
    :ptimer=>false,
    :debug=>false,
    :solver=>false,
    :matrix_type=>false,
    :vector_type=>false,
    :model=>true,
    :k=>false,
    :fluid=>true,
    :solid=>false,
    :bcs=>true,
    :check_valid=>false,
    :solver_postpro=>false,
  )

  # Check that all mandatory key are in params
  for key in keys(mandatory)
    if mandatory[key] && !haskey(params,key)
      error("Key :$key is a mandatory key in the main parameter dict, but it is not provided. See docs for init_params! for a list of mandatory keys and their meaning.")
    end
  end

  # Compute default values for optional keys
  optional = Dict(
    :solid=>nothing,
    :ptimer=>default_ptimer(params[:model]),
    :debug=>false,
    :solver=>NLSolver(show_trace=true,method=:newton),
    :solver_postpro => (x->nothing),
    :matrix_type=>SparseMatrixCSC{Float64,Int32},
    :vector_type=>Vector{Float64},
    :k=>2,
    :check_valid=>true,
  )

  # Check that we have computed defaults for all optionals
  for key in keys(mandatory)
    if !mandatory[key] && !haskey(optional,key)
      error("Internal error")
    end
  end

  # Set default args
  for key in keys(optional)
    if !haskey(params,key)
      params[key] = optional[key]
    end
  end

  # Check that we dont have unused params
  if params[:check_valid]
    for key in keys(params)
      if !haskey(mandatory,key)
        error("Key :$key is not a valid key in the main parameter dict. See docs for init_params! for a list of valid keys. Set key :check_valid to false to ignore invalid keys.")
      end
    end
  end

  init_params_fluid!(params[:fluid],params)
  if params[:solid] !== nothing
    init_params_solid!(params[:solid],params)
  end
  #init_params_bcs!(params[:bcs],params)

  params
end

default_ptimer(model) = PTimer(get_part_ids(sequential,1))
default_ptimer(model::GridapDistributed.DistributedDiscreteModel) = PTimer(get_part_ids(model.models))


"""
    init_params_fluid!(fluid::Dict{Symbol},params::Dict{Symbol})

Check validity of the fluid-related parameter dictionary `fluid`.
Valid mandatory and optional keys for `fluid` are detailed below.
If an optional key is not in `fluid`, it will be added in-place in `fluid`
with its corresponding default value.
The main parameter dictionary `params` is passed since the computation of some default
values might rely on it.

The dict `fluid` specifies the different parameters in the MHD equation:

     ∇⋅j = 0
     j + σ*∇(φ) - σ*(u×B) = 0
     ∇⋅u = 0
     α*u⋅∇(u) - β*Δ(u) + ∇(p) - γ*(j×B) = f

where `u,p,j,φ` are the unknowns and `α,β,γ,σ,B,f` are parameters.

# Mandatory keys
- `domain`: Domain where to solve the MHD problem.
  The domain is represented either with a `Triangulation` or with a `Integer`/`String`
  tag in the underlying discrete model.
-  `:α`: Value of the parameter `α`.
-  `:β`: Value of the parameter `β`.
-  `:γ`: Value of the parameter `γ`.
-  `:B`: Value of the parameter `B`.

# Optional keys
-  `:f=>VectorValue(0,0,0)`: Value of the parameter `f`.
-  `:σ=>1`: Value of the parameter `σ`.
"""
function init_params_fluid!(fluid,params)

  if !isa(fluid,Dict{Symbol})
    error("The value params[:fluid] has to be a Dict{Symbol}, where params is the main paramter dict.")
  end

  mandatory = Dict(
   :domain=>true,
   :α=>true,
   :β=>true,
   :γ=>true,
   :B=>true,
   :f=>false,
   :σ=>false,
  )

  # Check that all mandatory key are in fluid
  for key in keys(mandatory)
    if mandatory[key] && !haskey(fluid,key)
      error("Key :$key is a mandatory key in params[:fluid], being params the main parameter dict. See docs for init_params_fluid! for a list of mandatory keys and their meaning.")
    end
  end

  optional = Dict(:σ=>1,:f=>VectorValue(0,0,0))

  # Check that we have computed defaults for all optionals
  for key in keys(mandatory)
    if !mandatory[key] && !haskey(optional,key)
      error("Internal error")
    end
  end

  # Set default args
  for key in keys(optional)
    if !haskey(fluid,key)
      fluid[key] = optional[key]
    end
  end

  # Check that we dont have unused params
  if params[:check_valid]
    for key in keys(fluid)
      if !haskey(mandatory,key)
        error("Key :$key is not a valid key in params[:fluid], where params is the main parameter dict. See docs for init_params_fluid! for a list of valid keys. Set params[:check_valid]=false to ignore invalid keys.")
      end
    end
  end


end

"""
    init_params_solid!(solid::Dict{Symbol},params::Dict{Symbol})

Check validity of the solid-related parameter dictionary `solid`.
Valid mandatory and optional keys for `solid` are detailed below.
If an optional key is not in `solid`, it will be added in-place in `solid`
with its corresponding default value.
The main parameter dictionary `params` is passed since the computation of some default
values might rely on it.

The dict `solid` specifies the different parameters in the electric problem:

     ∇⋅j = 0
     j + σ*∇(φ) - σ*(u×B) = 0

where `j,φ` are the unknowns and `σ` is a parameter.

# Mandatory keys
- `domain`: Domain occupied by the solid.
  The domain is represented either with a `Triangulation` or with a `Integer`/`String`
  tag in the underlying discrete model.
# Optional keys
-  `:σ=>1`: Value of the parameter `σ`.
"""
function init_params_solid!(solid,params)
  if !isa(solid,Dict{Symbol})
    error("The value params[:solid] has to be a Dict{Symbol}, where params is the main paramter dict.")
  end

  mandatory = Dict(
   :domain=>true,
   :σ=>false,
  )

  # Check that all mandatory key are in solid
  for key in keys(mandatory)
    if mandatory[key] && !haskey(solid,key)
      error("Key :$key is a mandatory key in params[:solid], being params the main parameter dict. See docs for init_params_solid! for a list of mandatory keys and their meaning.")
    end
  end

  optional = Dict(:σ=>1)

  # Check that we have computed defaults for all optionals
  for key in keys(mandatory)
    if !mandatory[key] && !haskey(optional,key)
      error("Internal error")
    end
  end

  # Set default args
  for key in keys(optional)
    if !haskey(solid,key)
      solid[key] = optional[key]
    end
  end

  # Check that we dont have unused params
  if params[:check_valid]
    for key in keys(solid)
      if !haskey(mandatory,key)
        error("Key :$key is not a valid key in params[:solid], where params is the main parameter dict. See docs for init_params_solid! for a list of valid keys. Set params[:check_valid]=false to ignore invalid keys.")
      end
    end
  end

end




function doc_fluid()
  Dict(
   :domain=>"""
   Domain where to solve the fluid MHD problem. Call `doc_domain()` for details on how to represent domains.
   The MHD probles is defined as:
     ∇⋅j = 0
     j + σ*∇(φ) - σ*(u×B) = 0
     ∇⋅u = 0
     α*u⋅∇(u) - β*Δ(u) + ∇(p) - γ*(j×B) = f
     u,p,j,φ are the unknowns. α,β,γ,σ,B,f are parameters (see the other keys in `doc_fluid()`).
   """,
   :α=>"Value of the parameter α",
   :β=>"Value of the parameter β",
   :γ=>"Value of the parameter γ",
   :f=>"Value of the parameter f",
   :B=>"Value of the parameter B",
   :σ=>"Value of the parameter σ",
  )
end

function default_fluid(params)
  Dict(:σ=>1)
end

function doc_solid()
  Dict(
    :domain=>"""
    Domain where to solve the solid elecgtric problem. Call `doc_domain()` for details on how to represent domains.
    The solid electric probles is defined as:
      ∇⋅j = 0
      j + σ*∇(φ) = 0
      j,φ are the unknowns. σ is a parameter (see the other keys in `doc_solid()`).
    """,
    :σ=>"Value of the parameter σ",
  )
end

function default_solid(params)
  Dict(:σ=>1)
end

function doc_domain()
  " A domain is represented either with a Triangulation or with a integer/string tag in the underlying discrete model."
end

function doc_bcs()
  Dict(
  :u=>"A Dict defining strong Dirichlet conditions on the fluid velocity. Call doc_bcs_u() for futher details.",
  :j=>"A Dict defining strong Dirichlet conditions on the charge current. Call doc_bcs_j() for futher details.",
  :φ=>"A Dict or a collection of Dicts. Each Dict defines a weak boundary condition for the potential. Call doc_bcs_φ() for futher details.",
  :t=>"A Dict or a collection of Dicts. Each Dict defines a boundary traction on the fluid. Call doc_bcs_t() for futher details.",
  :thin_wall=>"A Dict or a collection of Dicts. Each Dict defines a thin wall law. Call doc_bcs_thin_wall() for futher details.",
  )
end

function default_bcs(params)
  Dict(
  :u=>default_bcs_u(params),
  :j=>default_bcs_j(params),
  :φ=>default_bcs_φ(params),
  :t=>default_bcs_t(params),
  :thin_wall=>default_bcs_thin_wall(params),
  )
end

function doc_bcs_u()
  Dict(
    :tags=>"Dirichlet tags where to impose strong boundary conditions for the fluid velocity",
    :values=>"The velocity value or function to be imposed at each of the given tags",
  )
end

function default_bcs_u(params)
  bcs = getparam(:bcs,params,"","doc_main")
  u = getparam(:u,bcs,"[:bcs]","doc_bcs")
  tags = getparam(:tags,u,"[:bcs][:u]","doc_bcs_u")
  z = VectorValue(0,0,0)
  if isa(tags,AbstractVector)
    values = fill(z,length(tags))
  else
    values = z
  end
  Dict(:values=>values)
end

function default_bcs_j(params)
  bcs = getparam(:bcs,params,"","doc_main")
  j = getparam(:j,bcs,"[:bcs]","doc_bcs")
  tags = getparam(:tags,j,"[:bcs][:j]","doc_bcs_j")
  z = VectorValue(0,0,0)
  if isa(tags,AbstractVector)
    values = fill(z,length(tags))
  else
    values = z
  end
  Dict(:values=>values)
end

function doc_bcs_j()
  Dict(
    :tags=>"Dirichlet tags where to impose strong boundary conditions for the charge current in normal direction",
    :values=>"The charge current value or function to be imposed at each of the given tags",
  )
end

function doc_bcs_φ()
  Dict(
    :domain=>"Domain where to impose the potential weakly. Call `doc_domain()` for details on how to represent domains.",
    :value=>"Value of the electric potential to be imposed weakly",
  )
end

function doc_bcs_t()
  Dict(
    :domain=>"Domain where to impose a fluid boundary traction weakly. Call `doc_domain()` for details on how to represent domains.",
    :value=>"Value of the fluid boundary traction to be imposed weakly",
  )
end

function doc_bcs_thin_wall()
  Dict(
    :domain=>"""
    Domain where to impose the thin wall law. Call `doc_domain()` for details on how to represent domains.
    The thin wall law is
    j⋅n + cw*n⋅∇(j)⋅n = jw
    j is unknown, n is the boundary outward noral, and cw, jw are parameters.
    The thin wall law is imposed weakly via a penalty parameter τ.
    See the other keys in `doc_bcs_thin_wall()` for further details.
    """,
   :cw=>"Value of the parameter cw",
   :jw=>"Value of the parameter jw",
   :τ=>"Value of the parameter τ",
 )
end

function getparam(key,dict,sdict,sfun)
  if !haskey(dict,key)
    error("Missing mandatory key :$key in Dict params$(sdict). Call `$(sfun)()` to learn the correct format of this Dict.")
  end
  dict[key]
end

function checkparam(key,dict,sdict,sfun)
  if !haskey(dict,key)
    error("Missing mandatory key :$key in Dict params$(sdict). Call `$(sfun)()` to learn the correct format of this Dict.")
  end
end

function main(params::Dict)

  defaults = Dict(
    :solver=>NLSolver(show_trace=true,method=:newton),
    :solver_postpro=> (x->nothing),
    :matrix_type=>SparseMatrixCSC{Float64,Int},
    :vector_type=>Vector{Float64},
    :ptimer=>PTimer(get_part_ids(sequential,1)),
    :fluid=>Dict(
      :k=>2,
      :φ=>[],
      :t=>[],
      :thin_wall=>[]
    )
  )
  add_defaults!(params,defaults)

  t = params[:ptimer]
  tic!(t;barrier=true)
  k = params[:fluid][:k]
  Ω = params[:fluid][:domain]
  T = Float64
  D = num_cell_dims(Ω)
  reffe_u = ReferenceFE(lagrangian,VectorValue{D,T},k)
  reffe_p = ReferenceFE(lagrangian,T,k-1;space=:P)
  reffe_j = ReferenceFE(raviart_thomas,T,k-1)
  reffe_φ = ReferenceFE(lagrangian,T,k-1)

  # Test spaces
  V_u = TestFESpace(Ω,reffe_u;dirichlet_tags=params[:fluid][:u][:tags])
  V_p = TestFESpace(Ω,reffe_p;conformity=p_conformity(Ω))
  V_j = TestFESpace(Ω,reffe_j;dirichlet_tags=params[:fluid][:j][:tags])
  V_φ = TestFESpace(Ω,reffe_φ;conformity=:L2)
  V = MultiFieldFESpace([V_u,V_p,V_j,V_φ])

  # Trial spaces
  # TODO improve for parallel computations
  tic!(t;barrier=true)
  z = zero(VectorValue{D,Float64})
  u_bc = params[:fluid][:u][:values]
  j_bc = params[:fluid][:j][:values]
  U_u = u_bc == z ? V_u : TrialFESpace(V_u,u_bc)
  U_j = j_bc == z ? V_j : TrialFESpace(V_j,j_bc)
  U_p = TrialFESpace(V_p)
  U_φ = TrialFESpace(V_φ)
  U = MultiFieldFESpace([U_u,U_p,U_j,U_φ])
  toc!(t,"fe_spaces")

  tic!(t;barrier=true)
  if params[:debug]
    Random.seed!(1234)
    vt = get_vector_type(U)
    free_ids = get_free_dof_ids(U)
    free_vals = _rand(vt,free_ids)
    xh = FEFunction(U,free_vals)
  else
    res, jac = weak_form(params,k)
    Tm = params[:matrix_type]
    Tv = params[:vector_type]
    assem = SparseMatrixAssembler(Tm,Tv,U,V)
    op = FEOperator(res,jac,U,V,assem)
    solver = params[:solver]
    xh = zero(U)
    xh,cache = solve!(xh,solver,op)
    solver_postpro = params[:solver_postpro]
    solver_postpro(cache)
  end
  toc!(t,"solve")

  xh
end

function _rand(vt::Type{<:Vector{T}},r::AbstractUnitRange) where T
  rand(T,length(r))
end

function _rand(vt::Type{<:PVector{T,A}},ids::PRange) where {T,A}
  values = map_parts(ids.partition) do partition
    Tv = eltype(A)
    _rand(Tv,1:num_lids(partition))
  end
  PVector(values,ids)
end

function p_conformity(poly::Polytope)
  if is_simplex(poly)
    conf = :H1
  elseif is_n_cube(poly)
    conf = :L2
  else
    @unreachable "unsupported cell topology"
  end
  conf
end

function p_conformity(Ω::Triangulation)
  reffes = get_reffes(Ω)
  @assert length(reffes) == 1
  reffe = first(reffes)
  poly = get_polytope(reffe)
  p_conformity(poly)
end

function p_conformity(Ω::GridapDistributed.DistributedTriangulation)
  p = map_parts(Ω.trians) do Ω
    reffes = get_reffes(Ω)
    @assert length(reffes) == 1
    reffe = first(reffes)
    poly = get_polytope(reffe)
    poly
  end
  poly = get_part(p) # We assume same polytope in all parts
  p_conformity(poly)
end

function p_conformity(model::DiscreteModel)
  Ω = Interior(model)
  p_conformity(Ω)
end

function p_conformity(model::GridapDistributed.DistributedDiscreteModel)
  Ω = Interior(model)
  p_conformity(Ω)
end

function add_defaults!(params,defaults)
  for (key,val) in defaults
    if !haskey(params,key)
      params[key] = val
    elseif isa(val,AbstractDict)
      @assert isa(params[key],AbstractDict)
      add_defaults!(params[key],val)
    end
  end
end

function weak_form(params,k)

  fluid = params[:fluid]

  Ω = Triangulation(fluid[:domain])
  dΩ = Measure(Ω,2*k)
  D = num_cell_dims(Ω)
  z = zero(VectorValue{D,Float64})

  α = fluid[:α]
  β = fluid[:β]
  γ = fluid[:γ]
  f = isa(fluid[:f],VectorValue) ? fluid[:f] : z
  B = isa(fluid[:B],VectorValue) ? fluid[:B] : z

  params_φ = []
  for i in 1:length(fluid[:φ])
    φ_i = fluid[:φ][i][:value]
    Γ = fluid[:φ][i][:domain]
    dΓ = Measure(Γ,2*k)
    n_Γ = get_normal_vector(Γ)
    push!(params_φ,(φ_i,n_Γ,dΓ))
  end

  params_thin_wall = []
  for i in 1:length(fluid[:thin_wall])
    τ_i = fluid[:thin_wall][i][:τ]
    cw_i = fluid[:thin_wall][i][:cw]
    jw_i = fluid[:thin_wall][i][:jw]
    Γ = fluid[:thin_wall][i][:domain]
    dΓ = Measure(Γ,2*k)
    n_Γ = get_normal_vector(Γ)
    push!(params_thin_wall,(τ_i,cw_i,jw_i,n_Γ,dΓ))
  end

  params_f = []
  if !isa(fluid[:f],VectorValue)
    for i in 1:length(fluid[:f])
      f_i = fluid[:f][i][:value]
      Ω_i = fluid[:f][i][:domain]
      dΩ_i = Measure(Ω_i,2*k)
      push!(params_f,(f_i,dΩ_i))
    end
  end

  params_B = []
  if !isa(fluid[:B],VectorValue)
    for i in 1:length(fluid[:B])
      B_i = fluid[:B][i][:value]
      Ω_i = fluid[:B][i][:domain]
      dΩ_i = Measure(Ω_i,2*k)
      push!(params_f,(γ,B_i,dΩ_i))
    end
  end

  function a(x,dy)
    r = a_mhd(x,dy,β,γ,B,dΩ)
    for p in params_thin_wall
      r = r + a_thin_wall(x,dy,p...)
    end
    for p in params_B
      r = r + a_B(x,dy,p...)
    end
    r
  end

  function ℓ(dy)
    r = ℓ_mhd(dy,f,dΩ)
    for p in params_φ
      r = r + ℓ_φ(dy,p...)
    end
    for p in params_thin_wall
      r = r + ℓ_thin_wall(dy,p...)
    end
    for p in params_f
      r = r + ℓ_f(dy,p...)
    end
    r
  end

  function c(x,dy)
    r = c_mhd(x,dy,α,dΩ)
    r
  end

  function dc(x,dx,dy)
    r = dc_mhd(x,dx,dy,α,dΩ)
    r
  end

  res(x,dy) = c(x,dy) + a(x,dy) - ℓ(dy)
  jac(x,dx,dy) = dc(x,dx,dy) + a(dx,dy)

  res, jac
end

conv(u,∇u) = (∇u')⋅u

function a_mhd(x,dy,β,γ,B,dΩ)
  u, p, j, φ = x
  v_u, v_p, v_j, v_φ = dy
  ∫(
    β*(∇(u)⊙∇(v_u)) - p*(∇⋅v_u) -(γ*(j×B)⋅v_u) +
    (∇⋅u)*v_p +
    j⋅v_j - φ*(∇⋅v_j) - (u×B)⋅v_j +
    (∇⋅j)*v_φ ) * dΩ
end

function ℓ_mhd(dy,f,dΩ)
  v_u, v_p, v_j, v_φ = dy
  ∫( v_u⋅f )*dΩ
end

function c_mhd(x,dy,α,dΩ)
  u, p, j, φ = x
  v_u, v_p, v_j, v_φ = dy
  ∫( α*v_u⋅(conv∘(u,∇(u))) ) * dΩ
end

function dc_mhd(x,dx,dy,α,dΩ)
  u, p, j, φ = x
  du , dp , dj , dφ  = dx
  v_u, v_p, v_j, v_φ = dy
  ∫( α*v_u⋅( (conv∘(u,∇(du))) + (conv∘(du,∇(u))) ) ) * dΩ
end

function ℓ_φ(dy,φ,n_Γ,dΓ)
  v_u, v_p, v_j, v_φ = dy
  ∫( -(v_j⋅n_Γ)*φ )*dΓ
end

function ℓ_f(dy,f,dΩ)
  v_u, v_p, v_j, v_φ = dy
  ∫( v_u⋅f )*dΩ
end

function ℓ_thin_wall(dy,τ,cw,jw,n_Γ,dΓ)
  v_u, v_p, v_j, v_φ = dy
  ∫( τ*(v_j⋅n_Γ)*jw ) * dΓ
end

function a_thin_wall(x,dy,τ,cw,jw,n_Γ,dΓ)
  u, p, j, φ = x
  v_u, v_p, v_j, v_φ = dy
  ∫( τ*((v_j⋅n_Γ)*(j⋅n_Γ) + cw*(v_j⋅n_Γ)*(n_Γ⋅(∇(j)⋅n_Γ))) )*dΓ
end

function a_B(x,dy,γ,B,dΩ)
  u, p, j, φ = x
  v_u, v_p, v_j, v_φ = dy
  ∫( -(γ*(j×B)⋅v_u) - (u×B)⋅v_j )*dΩ
end

