using DataFrames
using JLD2
using Measures
using Printf
using SolverBenchmark
using Plots
using PrettyTables

const METHODS = (:exact, :lbfgs)

function load_stats(dir::AbstractString, stats, suffix = ""; methods = METHODS)

  for method in METHODS

    @info "Loading $(method) benchmark results"

    file_splits = String[]

    for (root, _, files) in walkdir(dir)
      for file in files
        if (
          startswith(file, "stats_$(method)") ||
          (startswith(file, "stats_ipopt_$(method)") && suffix == "")
        ) && occursin(r"\d+\.jld2$", file)
          push!(file_splits, joinpath(root, file))
        end
      end
    end

    sort!(file_splits)

    n_splits = length(file_splits)

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

function plot_perf_profile(stats::Dict; prefix::String = "", certified_infeasible = Dict{Symbol,Set{String}}(), keys = (:l2penalty, :ipopt))
  
  solved(df) = begin
    # Retrieve certification
    solver = df[1, :solver_name]
    cert = get(certified_infeasible, solver, Set{String}())

    # Successful status if either first order or infeasible and certified
    return (df.status .== :first_order) .|
    ((df.status .== :infeasible) .& in.(df.name, Ref(cert)))
  end
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
    for s in series
      if s[:label] == String(keys[1])
        continue
      elseif s[:label] == String(keys[2])
        s[:linecolor] = :gray
      else
        s[:linecolor] = :black
      end
    end
    for s in series
      s[:label] = label_dict[Symbol(s[:label])]
    end
    name =
      prefix == "" ? "paper/figs/CUTEst-$(abv).pdf" :
      "paper/figs/CUTEst-" * prefix * "-" * String(keys[2]) * "-$(abv).pdf"
    savefig(name)
  end
end

function load_precomputed_certification(dir::AbstractString)
  cert_file = nothing
  for (root, _, files) in walkdir(dir)
    "infeasibility_certification.jld2" in files &&
      (cert_file = joinpath(root, "infeasibility_certification.jld2"))
  end

  if cert_file === nothing
    @warn "No precomputed infeasibility certification found under $(dir)."
    return nothing
  end

  @info "Loading precomputed infeasibility certification from $cert_file"
  return load(cert_file)["infeasibility_certification"]
end

function lookup_certification(report, name::AbstractString, hessian::Symbol)
  report === nothing && return "N/A"
  idx = findfirst(row -> row.name == name && row.hessian == hessian, eachrow(report))
  idx === nothing && return "N/A"
  return report[idx, :certified_locally_infeasible]
end

function register_certified!(
  certified_infeasible::Dict{Symbol,Set{String}},
  report,
  key::Symbol,
)
  report === nothing && return certified_infeasible
  hessian = Symbol.(split(string(key), "_"))[2]
  for row in eachrow(report)
    if row.hessian == hessian && row.certified_locally_infeasible === true
      push!(get!(() -> Set{String}(), certified_infeasible, key), row.name)
    end
  end
  return certified_infeasible
end

function infeasibility_table(stats::Dict; prefix::String = "", certified_infeasible::Dict{Symbol,Set{String}})

  keys = (:l2penalty, :ipopt)
  keys = prefix == "" ? keys : Symbol.(string.(keys) .* "_" .* prefix)

  penelopt_key = Symbol("l2penalty_$(prefix)")
  ipopt_key = Symbol("ipopt_$(prefix)")

  df = DataFrame(
    name = stats[keys[1]].name,
    n = stats[keys[1]].nvar,
    m = stats[keys[1]].ncon,
    penelopt_status = stats[penelopt_key].status,
    penelopt_certified = string.(in.(stats[penelopt_key].name, Ref(certified_infeasible[penelopt_key]))),
    ipopt_status = stats[ipopt_key].status,
    ipopt_certified = string.(in.(stats[ipopt_key].name, Ref(certified_infeasible[ipopt_key])))
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

# load infeasibility results
penelopt_certification =
  load_precomputed_certification(penelopt_dir)
ipopt_certification =
  load_precomputed_certification(ipopt_dir)

certified_infeasible = Dict{Symbol,Set{String}}()

# reference isn't paired against ipopt below, so register it directly.
register_certified!(
  certified_infeasible,
  penelopt_certification,
  :l2penalty_exact,
)
register_certified!(
  certified_infeasible,
  penelopt_certification,
  :l2penalty_lbfgs,
)

register_certified!(certified_infeasible, ipopt_certification, :ipopt_exact)
register_certified!(certified_infeasible, ipopt_certification, :ipopt_lbfgs)

register_certified!(certified_infeasible, ipopt_certification, :ipopt_exact)
register_certified!(certified_infeasible, ipopt_certification, :ipopt_lbfgs)

# plot performance profiles
plot_perf_profile(stats, prefix = "lbfgs", certified_infeasible = certified_infeasible)
plot_perf_profile(stats, prefix = "exact", certified_infeasible = certified_infeasible)

# generate tables
infeasibility_table(stats, prefix = "exact", certified_infeasible = certified_infeasible)

## MadNLP and Uno benchmarks

madnlp_dir = joinpath("code/artifacts", "MadNLP")
@info "Loading madnlp benchmark results"
load_stats(madnlp_dir, stats, "", methods = (:exact,))

uno_dir = joinpath("code/artifacts", "Uno")
@info "Loading uno benchmark results"
load_stats(uno_dir, stats, "", methods = (:exact,))

madnlp_certification =
  load_precomputed_certification(madnlp_dir)
uno_certification =
  load_precomputed_certification(uno_dir)

register_certified!(
  certified_infeasible,
  madnlp_certification,
  :madnlp_exact,
)
register_certified!(
  certified_infeasible,
  uno_certification,
  :uno_exact,
)

plot_perf_profile(stats, prefix = "exact", certified_infeasible = certified_infeasible, keys = (:l2penalty, :madnlp))
plot_perf_profile(stats, prefix = "exact", certified_infeasible = certified_infeasible, keys = (:l2penalty, :uno))