using DataFrames
using JLD2
using Measures
using Printf
using SolverBenchmark
using Plots
using PrettyTables

const METHODS = (:exact, :lbfgs)

function load_stats(dir::AbstractString, stats, suffix = ""; methods = METHODS)

  for method in methods

    @info "Loading $(method) benchmark results"

    file_splits = String[]

    for (root, _, files) in walkdir(dir)
      for file in files
        if occursin(Regex("_$(method)_\\d+\\.jld2\$"), file)
          push!(file_splits, joinpath(root, file))
        end
      end
    end

    sort!(file_splits)

    n_splits = length(file_splits)

    n_splits == 0 && continue

    # Load the first split and initialize the dictionary
    file = file_splits[1]
    dict = load(file)["stats"]

    # Load the remaining splits and concatenate the data
    for split = 2:n_splits
      file = file_splits[split]
      dict_split = load(file)["stats"]
      for key in keys(dict)
        append!(dict[key], dict_split[key])
      end
    end

    for key in keys(dict)
      new_key = Symbol("$(key)$suffix")
      stats[new_key] = dict[key]
    end
  end

  return stats
end

function plot_perf_profile(stats::Dict; prefix::String = "", keys = (:l2penalty, :ipopt), show_ylabel::Bool = true)
  
  solved(df) =
    (df.status .== :first_order) .|
    ((df.status .== :infeasible) .& (df.certified_infeasible .== true))

  pairs = [
    ("gradient", "grad", df -> .!solved(df) * Inf + df.neval_grad),
    ("objective", "obj", df -> .!solved(df) * Inf + df.neval_obj),
    ("CPU time", "time", df -> .!solved(df) * Inf + df.elapsed_time),
  ]
  keys = prefix == "" ? keys : Symbol.(string.(keys) .* "_" .* prefix)
  label_dict = Dict(
    :l2penalty_exact => "Penelopt",
    :ipopt_exact => "Ipopt",
    :l2penalty_lbfgs => "Penelopt (BFGS)",
    :ipopt_lbfgs => "Ipopt (BFGS)",
    :madnlp_exact => "MadNLP",
    :uno_exact => "Uno",
  )
  label = prefix == "exact" ? Symbol.(String.(keys)[:1:(end-5)]) : keys
  for (metric, abv, f) in pairs
    stats_subset = Dict(key => stats[key] for key in keys)
    title = metric == "CPU time" ? "CPU Time" : "Number of $(metric) evaluations"
    p = performance_profile(
      stats_subset,
      f,
      title = title,
      c = :black,
      linestyles = [:solid, :dash, :dot],
      legendfontsize = 15,
      guidefontsize = 15,
      legend = :bottomright,
    )
    series = p.series_list
    # Always put Penelopt first (legend order)
    order = s -> s[:label] == String(keys[1]) ? 0 : 1
    sort!(p.series_list, by = order)
    sort!(p.subplots[1].series_list, by = order)
    for s in series
      if s[:label] == String(keys[1])
        s[:linestyle] = :solid
      elseif s[:label] == String(keys[2])
        s[:linecolor] = :gray
        s[:linestyle] = :dash
      else
        s[:linecolor] = :black
      end
    end
    for s in series
      s[:label] = label_dict[Symbol(s[:label])]
    end
    # Axis labels: x only on the CPU time row, y only on the left column
    metric == "CPU time" || plot!(p, xlabel = "")
    show_ylabel || plot!(p, ylabel = "")
    name =
      prefix == "" ? "paper/figs/CUTEst-$(abv).pdf" :
      "paper/figs/CUTEst-" * prefix * "-" * String(keys[2]) * "-$(abv).pdf"
    savefig(name)
  end
end

function infeasibility_table(stats::Dict; prefix::String = "")

  keys = (:l2penalty, :ipopt)
  keys = prefix == "" ? keys : Symbol.(string.(keys) .* "_" .* prefix)

  penelopt_key = Symbol("l2penalty_$(prefix)")
  ipopt_key = Symbol("ipopt_$(prefix)")

  df = DataFrame(
    name = stats[keys[1]].name,
    n = stats[keys[1]].nvar,
    m = stats[keys[1]].ncon,
    penelopt_status = stats[penelopt_key].status,
    penelopt_certified = stats[penelopt_key].certified_infeasible,
    ipopt_status = stats[ipopt_key].status,
    ipopt_certified = stats[penelopt_key].certified_infeasible
  )

  filter!(row -> (row.penelopt_status == :infeasible || row.ipopt_status == :infeasible), df)

  df.penelopt_certified[df.penelopt_status .!= :infeasible] .= ""
  df.ipopt_certified[df.ipopt_status .!= :infeasible] .= ""

  header = prefix == "lbfgs" ?
    ["Problem", "n", "m", "Penelopt (BFGS)", "Certified", "IPOPT (BFGS)", "Certified"] :
    ["Problem", "n", "m", "Penelopt (default)", "Certified", "IPOPT (default)", "Certified"]

  open("paper/tables/infeasibility_table.tex", "w") do io
    pretty_table(io, df;
        backend    = Val(:latex),
        header     = header,
        alignment  = [:r, :c, :c, :c, :c, :c, :c],
        hlines      = [:begin, 1, :end],
        wrap_table = false,
    )
  end
end

stats = Dict{Symbol,DataFrame}()

# load Penelopt
penelopt_dir = joinpath("code/artifacts", "Penelopt")
@info "Loading penelopt benchmark results"
load_stats(penelopt_dir, stats, "")

# load IPOPT
ipopt_dir = joinpath("code/artifacts", "IPOPT")
@info "Loading ipopt benchmark results"
load_stats(ipopt_dir, stats, "")

# plot performance profiles
plot_perf_profile(stats, prefix = "lbfgs", show_ylabel = false)
plot_perf_profile(stats, prefix = "exact")

# generate tables
infeasibility_table(stats, prefix = "exact")

## MadNLP and Uno benchmarks

madnlp_dir = joinpath("code/artifacts", "MadNLP")
@info "Loading madnlp benchmark results"
load_stats(madnlp_dir, stats, "", methods = (:exact,))

uno_dir = joinpath("code/artifacts", "Uno")
@info "Loading uno benchmark results"
load_stats(uno_dir, stats, "", methods = (:exact,))

plot_perf_profile(stats, prefix = "exact", keys = (:l2penalty, :madnlp))
plot_perf_profile(stats, prefix = "exact", keys = (:l2penalty, :uno), show_ylabel = false)