using CUTEst, MadNLP, NLPModels, SolverCore, SolverBenchmark, JLD2

include(joinpath(@__DIR__, "..", "common", "infeasibility-checker.jl"))
include(joinpath(@__DIR__, "madnlp-stats-adapter.jl"))

const BENCHMARK_TOL = 1e-6
const BENCHMARK_MAX_TIME = 300.0

problem_names = CUTEst.select_sif_problems(
  min_con = 1,
  only_equ_con = true,
  custom_filter = meta -> (
    meta["variables"]["number"] >= meta["constraints"]["number"] &&
    meta["variables"]["free"] + meta["variables"]["fixed"] == meta["variables"]["number"]
  ),
)

split = parse(Int, get(ENV, "CUTEST_SPLIT", "1"))
n_splits = 2

@assert 1 <= split <= n_splits "CUTEST_SPLIT=$split is out of range 1:$n_splits"

problem_names = collect(problem_names)

n = length(problem_names)
first = fld((split - 1) * n, n_splits) + 1
last = fld(split * n, n_splits)

problem_names = problem_names[first:last]

@info "Running CUTEst split $split/$n_splits: problems $first:$last ($(length(problem_names)) problems)"

# Problems that hang indefinitely (both MadNLP and Uno) on this CUTEst set.
const EXCLUDED_PROBLEMS = ["CYCLOOCF", "CYCLOOCT"]

problem_list = (CUTEstModel(name) for name in problem_names)

solvers = Dict(:madnlp_exact => 
  nlp -> begin
    stats = madnlp_exact(
      nlp,
      print_level = MadNLP.ERROR,
      # Tolerances
      tol = BENCHMARK_TOL,
      acceptable_iter = 0,
      acceptable_tol = 0.0,
      # Deactivate residual scaling
      s_max = floatmax(Float64),
      # Iteration limits
      max_wall_time = BENCHMARK_MAX_TIME,
      max_iter = typemax(Int),
    )

    set_solver_specific!(stats, :certified_infeasible, false)
    if stats.status == :infeasible
      set_solver_specific!(
        stats,
        :certified_infeasible,
        certify_local_infeasibility(nlp, stats.solution),
      )
    end
    return stats
  end
)

stats = bmark_solvers(solvers, problem_list; skipif = nlp -> nlp.meta.name in EXCLUDED_PROBLEMS, prune = false)

# skipif rows come back hardcoded as status=:exception, elapsed_time=Inf
# (SolverBenchmark.jl doesn't let skipif customize that) - relabel them.
for df in values(stats), row in eachrow(df)
  if row.name in EXCLUDED_PROBLEMS
    row.status = :max_time
    row.elapsed_time = BENCHMARK_MAX_TIME
  end
end

result_dir = joinpath(@__DIR__, "result")
mkpath(result_dir)
@save joinpath(result_dir, "stats_madnlp_exact_$(split).jld2") stats
