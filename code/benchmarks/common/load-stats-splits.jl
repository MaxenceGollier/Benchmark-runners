using JLD2, DataFrames

"""
    load_stats_splits(dir, prefix)

Load every `<prefix>*.jld2` file found under `dir` whose name ends in a
split number (e.g. `stats_madnlp_exact_1.jld2`, `..._2.jld2`), concatenate
them in split order, and return the merged `Dict{Symbol,DataFrame}`.
"""
function load_stats_splits(dir::AbstractString, prefix::AbstractString)
  file_splits = String[]
  for (root, _, files) in walkdir(dir)
    for file in files
      if startswith(file, prefix) && occursin(r"\d+\.jld2$", file)
        push!(file_splits, joinpath(root, file))
      end
    end
  end
  sort!(file_splits)
  isempty(file_splits) &&
    error("No files matching \"$(prefix)*.jld2\" found under $(dir)")

  @info "Loading $(length(file_splits)) split(s) matching \"$(prefix)*.jld2\" from $(dir)"

  dict = load(file_splits[1])["stats"]
  for file in file_splits[2:end]
    dict_split = load(file)["stats"]
    for key in keys(dict)
      append!(dict[key], dict_split[key])
    end
  end

  return dict
end
