using CUTEst

"""
    select_cutest_exact_split(; n_splits::Int = 2)

Return `(problem_names, split, n_splits)` for the shard identified by the
`CUTEST_SPLIT` environment variable (1-indexed, defaults to `"1"` when the
variable is unset, e.g. for local runs).
"""
function select_cutest_exact_split(; n_splits::Int = 2)
  problem_names = CUTEst.select_sif_problems(
    min_con = 1,
    only_equ_con = true,
    custom_filter = meta -> (
      meta["variables"]["number"] >= meta["constraints"]["number"] &&
      meta["variables"]["free"] + meta["variables"]["fixed"] == meta["variables"]["number"]
    ),
  )

  split = parse(Int, get(ENV, "CUTEST_SPLIT", "1"))
  @assert 1 <= split <= n_splits "CUTEST_SPLIT=$split is out of range 1:$n_splits"

  problem_names = collect(problem_names)

  n = length(problem_names)
  first = fld((split - 1) * n, n_splits) + 1
  last = fld(split * n, n_splits)

  problem_names = problem_names[first:last]

  @info "Running CUTEst split $split/$n_splits: problems $first:$last ($(length(problem_names)) problems)"

  return problem_names, split, n_splits
end
