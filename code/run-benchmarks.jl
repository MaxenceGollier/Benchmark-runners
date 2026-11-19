artifacts_path = joinpath(@__DIR__, "artifacts")

# The Penelopt and IPOPT scripts save their results to "benchmark/result/", relative to the current directory
mkpath("benchmark/result")

# 1. Penelopt Benchmarks run

penelopt_path = joinpath(@__DIR__, "benchmarks", "Penelopt")

for k = 1:2
  # Run Penelopt benchmarks with exact Hessian on the k-th CUTEst split
  ENV["CUTEST_SPLIT"] = string(k)
  include(joinpath(penelopt_path, "Penelopt-exact-hessian.jl"))

  # Move the generated artifacts into the appropriate directory
  mv("benchmark/result/stats_exact_$k.jld2", joinpath(artifacts_path, "Penelopt/stats_exact_$k.jld2"), force = true)
end

for k = 1:4
  # Run Penelopt benchmarks with L-BFGS on the k-th CUTEst split
  ENV["CUTEST_SPLIT"] = string(k)
  include(joinpath(penelopt_path, "Penelopt-bfgs.jl"))

  # Move the generated artifacts into the appropriate directory
  mv("benchmark/result/stats_lbfgs_$k.jld2", joinpath(artifacts_path, "Penelopt/stats_lbfgs_$k.jld2"), force = true)
end

# 2. IPOPT Benchmarks run

ipopt_path = joinpath(@__DIR__, "benchmarks", "IPOPT")

for k = 1:2
  # Run IPOPT benchmarks with exact Hessian on the k-th CUTEst split
  ENV["CUTEST_SPLIT"] = string(k)
  include(joinpath(ipopt_path, "Ipopt-exact-hessian.jl"))

  # Move the generated artifacts into the appropriate directory
  mv("benchmark/result/stats_ipopt_exact_$k.jld2", joinpath(artifacts_path, "IPOPT/stats_ipopt_exact_$k.jld2"), force = true)
end

for k = 1:4
  # Run IPOPT benchmarks with L-BFGS on the k-th CUTEst split
  ENV["CUTEST_SPLIT"] = string(k)
  include(joinpath(ipopt_path, "Ipopt-lbfgs.jl"))

  # Move the generated artifacts into the appropriate directory
  mv("benchmark/result/stats_ipopt_lbfgs_$k.jld2", joinpath(artifacts_path, "IPOPT/stats_ipopt_lbfgs_$k.jld2"), force = true)
end

# 3. Penelopt without watchdog Benchmarks run

for k = 1:2
  # Run Penelopt benchmarks without watchdog on the k-th CUTEst split
  ENV["CUTEST_SPLIT"] = string(k)
  include(joinpath(penelopt_path, "Penelopt-no-watchdog.jl"))

  # Move the generated artifacts into the appropriate directory
  mv("benchmark/result/stats_exact_$k.jld2", joinpath(artifacts_path, "Penelopt-no-watchdog/stats_exact_$k.jld2"), force = true)
end

# 4. Monotone Penelopt Benchmarks run

for k = 1:2
  # Run monotone Penelopt benchmarks on the k-th CUTEst split
  ENV["CUTEST_SPLIT"] = string(k)
  include(joinpath(penelopt_path, "Penelopt-monotone.jl"))

  # Move the generated artifacts into the appropriate directory
  mv("benchmark/result/stats_exact_$k.jld2", joinpath(artifacts_path, "Penelopt-monotone/stats_exact_$k.jld2"), force = true)
end

# 5. Uno Benchmarks run

uno_path = joinpath(@__DIR__, "benchmarks", "Uno")

for k = 1:2
  # Run Uno benchmarks with exact Hessian on the k-th CUTEst split
  ENV["CUTEST_SPLIT"] = string(k)
  include(joinpath(uno_path, "benchmark-cutest-uno-exact-hessian.jl"))

  # Move the generated artifacts into the appropriate directory
  mv(joinpath(uno_path, "result/stats_uno_exact_$k.jld2"), joinpath(artifacts_path, "Uno/stats_uno_exact_$k.jld2"), force = true)
end

# 6. MadNLP Benchmarks run

madnlp_path = joinpath(@__DIR__, "benchmarks", "MadNLP")

for k = 1:2
  # Run MadNLP benchmarks with exact Hessian on the k-th CUTEst split
  ENV["CUTEST_SPLIT"] = string(k)
  include(joinpath(madnlp_path, "benchmark-cutest-madnlp-exact-hessian.jl"))

  # Move the generated artifacts into the appropriate directory
  mv(joinpath(madnlp_path, "result/stats_madnlp_exact_$k.jld2"), joinpath(artifacts_path, "MadNLP/stats_madnlp_exact_$k.jld2"), force = true)
end
