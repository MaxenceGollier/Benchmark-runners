using CUTEst, UnoSolver, NLPModels, SolverCore, NLPModelsIpopt, NLPModelsModifiers,
  LinearAlgebra, DataFrames, JLD2

include(joinpath(@__DIR__, "..", "common", "load-stats-splits.jl"))
include(joinpath(@__DIR__, "uno-stats-adapter.jl"))
include(joinpath(@__DIR__, "uno-exact-solve.jl")) # defines BENCHMARK_MAX_TIME + uno_exact_solve
include(joinpath(@__DIR__, "..", "common", "remove-fixed-var.jl")) # uses BENCHMARK_MAX_TIME, must come after
include(joinpath(@__DIR__, "..", "common", "infeasibility-checker.jl")) # uses BENCHMARK_MAX_TIME, must come after


result_dir = joinpath(@__DIR__, "result")
stats = load_stats_splits(result_dir, "stats_uno_exact")

infeasibility_certification =
  certify_local_infeasibility(stats, :uno_exact, uno_exact_solve)

@info "Infeasibility certification results:\n" * sprint(
  io -> show(io, infeasibility_certification; allrows = true, allcols = true),
)

@save joinpath(result_dir, "infeasibility_certification.jld2") infeasibility_certification
