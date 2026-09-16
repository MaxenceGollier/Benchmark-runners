using MadNLP

const BENCHMARK_TOL = 1e-6
const BENCHMARK_MAX_TIME = 300.0

madnlp_exact_solve(nlp) = madnlp_exact(
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
