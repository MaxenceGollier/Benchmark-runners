# Adapted from Penelopt.jl's benchmark/utils/infeasibility-checker.jl

using CUTEst, NLPModels, NLPModelsIpopt, NLPModelsModifiers, LinearAlgebra, DataFrames

include(joinpath(@__DIR__, "trust-region-nls.jl"))

"""
    certify_local_infeasibility(nlp, xbar; Δ=10.0, tol=1e-9, feas_tol=1e-3)

Check whether `x̄ = xbar` is a locally infeasible point of `nlp` by solving

    min_x 1/2 ||c(x)||² s.t. ||J(x̄)(x - x̄)|| ≤ Δ

with IPOPT, starting from `x̄`. Certified infeasible if the trust-region
constraint is inactive at the solution and ||c(x)|| > feas_tol.

Returns `true`/`false` when conclusive, `missing` if the inner solve didn't
reach `:first_order` or stopped at the trust-region boundary.

(Copied verbatim from Penelopt.jl.)
"""
function certify_local_infeasibility(
  nlp::AbstractNLPModel,
  xbar::AbstractVector;
  Δ = 10.0,
  tol = 1e-9,
  feas_tol = 1e-3,
)
  M = TrustRegionNLS(nlp, xbar, Δ)
  model = FeasibilityFormNLS(M)

  # r₀ = c(x̄), so the F(x) - r = 0 block is satisfied at x0
  x0 = vcat(xbar, cons(nlp, xbar))

  stats = ipopt(
    model,
    x0 = x0,
    print_level = 0,
    tol = tol,
    dual_inf_tol = tol,
    constr_viol_tol = tol,
    compl_inf_tol = tol,
    acceptable_iter = 0,
    max_cpu_time = BENCHMARK_MAX_TIME,
  )

  if stats.status != :first_order
    @warn "Local infeasibility check for $(nlp.meta.name) was inconclusive (inner IPOPT solve terminated with status $(stats.status))"
    return missing
  end

  n = nlp.meta.nvar
  xsol = stats.solution[1:n]
  tr_residual = norm(M.Jxbar * (xsol - xbar))
  primal_feas = norm(cons(nlp, xsol))

  if tr_residual >= Δ - tol
    @warn "Local infeasibility check for $(nlp.meta.name) was inconclusive (trust-region constraint active at the solution; Δ = $Δ may be too small)"
    return missing
  end

  certified = primal_feas > feas_tol

  @debug "Local infeasibility check for $(nlp.meta.name): ||c(x̄)|| = $primal_feas, ||J(x̄)(x-x̄)|| = $tr_residual -> $(certified ? "certified infeasible" : "not certified")"

  return certified
end

"""
    certify_local_infeasibility(name, solve_fn)

Reproduce the benchmarked run for CUTEst problem `name` using `solve_fn`
(a function `nlp -> stats`, exactly the function passed to `bmark_solvers`
in the corresponding benchmark script, e.g. `madnlp_exact_solve` /
`uno_exact_solve` — must return something with a `.solution` field), then
certify the resulting candidate point.

(Adapted from Penelopt.jl's `certify_local_infeasibility(name, key)`,
which looked `solve_fn` up from Penelopt's own `BENCHMARK_SOLVERS` dict;
here it's passed in directly. See the note at the top of this file.)
"""
function certify_local_infeasibility(name::AbstractString, solve_fn::Function)
  nlp = CUTEstModel(name)
  try
    x = try
      solve_fn(nlp).solution
    catch e
      @warn "Could not reproduce the run for $(name): $(e)"
      return missing
    end

    preprocess_nlp = nlp
    if length(nlp.meta.ifix) > 0
      preprocess_nlp = remove_fixed_variables(nlp)
      x = x[nlp.meta.ifree]
    end

    return certify_local_infeasibility(preprocess_nlp, x)
  finally
    finalize(nlp)
  end
end

"""
    certify_local_infeasibility(stats, key, solve_fn)

Given a benchmark stats dictionary and a key (e.g. `:madnlp_exact`),
certify every problem in `stats[key]` that has status `:infeasible`, using
`solve_fn` to reproduce each candidate point.

Returns a DataFrame with columns `name`, `hessian`, `status`,
`certified_locally_infeasible` — same schema as Penelopt.jl's
`infeasibility_certification.jld2`, so `plot-paper.jl`'s
`load_precomputed_certification`/`register_certified!` work unchanged.
"""
function certify_local_infeasibility(stats::Dict{Symbol,DataFrame}, key::Symbol, solve_fn::Function)
  df = stats[key]
  hessian = Symbol.(split(string(key), "_"))[2]

  @info "Certifying infeasibility results for $(key)."

  rows = NamedTuple[]
  for i = 1:nrow(df)
    name = df[i, :name]
    status = df[i, :status]
    status != :infeasible && continue

    certified = certify_local_infeasibility(name, solve_fn)

    push!(
      rows,
      (
        name = name,
        hessian = hessian,
        status = status,
        certified_locally_infeasible = certified,
      ),
    )
  end

  return isempty(rows) ?
         DataFrame(
    name = String[],
    hessian = Symbol[],
    status = Symbol[],
    certified_locally_infeasible = Union{Bool,Missing}[],
  ) : DataFrame(rows)
end
