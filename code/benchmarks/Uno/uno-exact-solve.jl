using UnoSolver

const BENCHMARK_TOL = 1e-6
const BENCHMARK_MAX_TIME = 300.0

uno_exact_solve(nlp) = uno_exact(
  nlp,
  # Logging
  logger = "SILENT",
  linear_solver = "MUMPS",
  print_solution = false,
  # Tolerances
  primal_tolerance = BENCHMARK_TOL,
  dual_tolerance = BENCHMARK_TOL,
  acceptable_tolerance = 0.0,
  # Deactivate residual scaling
  residual_scaling_threshold = floatmax(Float64),
  # Iteration limits
  time_limit = BENCHMARK_MAX_TIME,
  max_iterations = typemax(Int32),
)
