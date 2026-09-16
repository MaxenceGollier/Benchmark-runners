using MadNLP, NLPModels, SolverCore

# `MadNLPExecutionStats` (fields: options, status, solution, objective,
# constraints, dual_feas, primal_feas, multipliers, multipliers_L,
# multipliers_U, iter, counters) is NOT a `SolverCore.GenericExecutionStats`
# and has no `solver_specific` field, which `SolverBenchmark.run_solver`
# expects — confirmed by a real run raising
# `FieldError: type MadNLPExecutionStats has no field solver_specific`.
# So, same as UnoSolver, this needs an adapter before it can go into
# `bmark_solvers`.
#
# Also note: `MadNLPExecutionStats` has no elapsed-time field, so this
# adapter times the `madnlp(...)` call itself with `@elapsed`.

"""
    madnlp_status_to_symbol(status)

Best-effort translation from MadNLP's `status` to the status symbols used
across this benchmark comparison (`:first_order`, `:infeasible`,
`:max_iter`, `:max_time`, `:unbounded`, `:unknown`).
"""
function madnlp_status_to_symbol(status)
  s = Symbol(lowercase(string(status)))
  if s in (:solve_succeeded, :solved_to_acceptable_level, :success, :optimal, :first_order)
    return :first_order
  elseif s in (:infeasible_problem_detected, :infeasible, :locally_infeasible)
    return :infeasible
  elseif s in (:maximum_iterations_exceeded, :max_iter, :max_iterations)
    return :max_iter
  elseif s in (:maximum_wall_time_exceeded, :max_time, :max_wall_time)
    return :max_time
  elseif s in (:diverging_iterates, :unbounded)
    return :unbounded
  else
    @warn "madnlp_status_to_symbol: unrecognized MadNLP status $(repr(status)); mapping to :unknown. Please check MadNLP's real status names and extend this mapping." maxlog = 5
    return :unknown
  end
end

"""
    madnlp_exact(nlp; kwargs...)

Run MadNLP and repackage the result as a `SolverCore.GenericExecutionStats`,
so it plugs into `SolverBenchmark.bmark_solvers` exactly like `ipopt(...)`
and `uno_exact(...)` do elsewhere in this comparison.

The `neval_*` columns come for free: `GenericExecutionStats(nlp; ...)`
snapshots `nlp.counters`, which MadNLP updates through the standard
NLPModels API (obj/grad/cons/jac/hess) under the hood.
"""
function madnlp_exact(nlp; kwargs...)
  elapsed = @elapsed (raw = madnlp(nlp; kwargs...))

  return GenericExecutionStats(
    nlp;
    status = madnlp_status_to_symbol(raw.status),
    solution = raw.solution,
    objective = raw.objective,
    dual_feas = raw.dual_feas,
    primal_feas = raw.primal_feas,
    multipliers = raw.multipliers,
    multipliers_L = raw.multipliers_L,
    multipliers_U = raw.multipliers_U,
    iter = raw.iter,
    elapsed_time = elapsed,
  )
end
