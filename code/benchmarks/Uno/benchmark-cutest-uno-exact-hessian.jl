using CUTEst, UnoSolver, NLPModels, SolverCore, SolverBenchmark, JLD2

include(joinpath(@__DIR__, "..", "common", "cutest-exact-hessian-problems.jl"))
include(joinpath(@__DIR__, "uno-stats-adapter.jl"))
include(joinpath(@__DIR__, "uno-exact-solve.jl"))

# Problems that hang indefinitely (both MadNLP and Uno) on this CUTEst set.
const EXCLUDED_PROBLEMS = ["CYCLOOCF", "CYCLOOCT"]

problem_names, split, _n_splits = select_cutest_exact_split(n_splits = 2)

problem_list = (CUTEstModel(name) for name in problem_names)

solvers = Dict(:uno_exact => uno_exact_solve)

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
@save joinpath(result_dir, "stats_uno_exact_$(split).jld2") stats
