using UnoSolver, NLPModels, SolverCore

# UnoSolver.jl's `uno(nlp; ...)` returns its own stats struct (fields like
# `solution_status`, `number_objective_evaluations`, ...) rather than a
# SolverCore.GenericExecutionStats, so it isn't directly usable with
# SolverBenchmark.bmark_solvers the way `ipopt(...)` / `madnlp(...)` are.
# This file adapts it.
#
# Docs / example this is based on:
#   https://unosolver.readthedocs.io/en/latest/interfaces/julia/

"""
    uno_status_to_symbol(solution_status, optimization_status)

Maps Uno's status codes to the status symbols used across this
benchmark comparison. See:
https://github.com/cvanaret/Uno/blob/b7dbdfba95e6d6758bdcbeba3aeb871d65202680/interfaces/Julia/src/libuno.jl#L33-L39
"""
function uno_status_to_symbol(solution_status::Integer, optimization_status::Integer)
  if solution_status == UnoSolver.UNO_FEASIBLE_KKT_POINT
    return :first_order
  elseif solution_status == UnoSolver.UNO_FEASIBLE_FJ_POINT    # stationary but degenerate
    return :first_order          # (Fritz-John, not a regular KKT point — judgment call, see README)
  elseif solution_status == UnoSolver.UNO_INFEASIBLE_STATIONARY_POINT    # certified local infeasibility
    return :infeasible
  elseif solution_status in (UnoSolver.UNO_DIVERGING_ITERATE, UnoSolver.UNO_UNBOUNDED_OBJECTIVE)
    return :unbounded
  elseif solution_status in (UnoSolver.UNO_FEASIBLE_SMALL_STEP, UnoSolver.UNO_INFEASIBLE_SMALL_STEP)  # stalled, not certified
    return :small_step
  else                            # solution_status == 0 (NOT_OPTIMAL): use optimization_status
    if optimization_status == UnoSolver.UNO_ITERATION_LIMIT
      return :max_iter
    elseif optimization_status == UnoSolver.UNO_TIME_LIMIT
      return :max_time
    elseif optimization_status in (UnoSolver.UNO_EVALUATION_ERROR, UnoSolver.UNO_ALGORITHMIC_ERROR)
      return :exception
    elseif optimization_status == UnoSolver.UNO_USER_TERMINATION
      return :user_terminated
    else
      return :unknown
    end
  end
end

"""
    uno_exact(nlp; kwargs...)

Run Uno through `UnoSolver.jl`'s NLPModels interface and repackage the
result as a `SolverCore.GenericExecutionStats`, so it plugs into
`SolverBenchmark.bmark_solvers` exactly like `ipopt(...)` and `madnlp(...)`
do elsewhere in this comparison.

The `neval_*` columns come for free: `GenericExecutionStats(nlp; ...)`
snapshots `nlp.counters`, and UnoSolver's NLPModels interface calls the
standard NLPModels API (obj/grad/cons/jac/hess) under the hood, so those
counters are already correct by the time this function returns — no manual
bookkeeping needed here.
"""
function uno_exact(nlp; kwargs...)
  raw = uno(nlp; kwargs...)

  return GenericExecutionStats(
    nlp;
    status = uno_status_to_symbol(raw.solution_status, raw.optimization_status),
    solution = raw.solution,
    objective = raw.objective,
    dual_feas = raw.dual_feas,
    primal_feas = raw.primal_feas,
    multipliers = raw.multipliers,
    multipliers_L = raw.multipliers_L,
    multipliers_U = raw.multipliers_U,
    iter = raw.iter,
    elapsed_time = raw.elapsed_time,
  )
end
