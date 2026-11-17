* Artifacts for the Penelopt benchmarks: https://github.com/JuliaSmoothOptimizers/Penelopt.jl/actions/runs/43953883491

* Artifacts for the IPOPT benchmarks: https://github.com/JuliaSmoothOptimizers/Penelopt.jl/actions/runs/43102707373

* Artifacts for the MadNLP benchmarks: https://github.com/MaxenceGollier/Benchmark-runners/actions/runs/43512053245

* Artifacts for the Uno benchmarks: https://github.com/MaxenceGollier/Benchmark-runners/actions/runs/43512064959

* Artifacts for Penelopt without watchdog benchmarks: https://github.com/JuliaSmoothOptimizers/Penelopt.jl/actions/runs/43954434444

* Artifacts for monotone Penelopt benchmarks: https://github.com/JuliaSmoothOptimizers/Penelopt.jl/actions/runs/43954397609

## How to reproduce the figures
```julia
using Pkg
Pkg.activate("code")
Pkg.instantiate()

include("code/plot-paper.jl")
```

## How to reproduce the benchmark runs

### Option 1: Through GitHub actions

1. Fork https://github.com/JuliaSmoothOptimizers/Penelopt.jl on the `v1.0.0` tag.

2. Go to the `actions` tab of the forked repository.

   2.1 Penelopt benchmarks: run the `Save benchmarks on main` action. Once it finishes, download the artifacts and add them in the `code/artifacts/Penelopt/` folder of this repository.

   2.2 Ipopt benchmarks: run the `Run IPOPT benchmarks` action. Once it finishes, download the artifacts and add them in the `code/artifacts/IPOPT/` folder of this repository.

   2.3 Penelopt without watchdog benchmarks: copy this PR onto your fork: https://github.com/JuliaSmoothOptimizers/Penelopt.jl/pull/272 and give it the `run CUTEst benchmark` label. This triggers the `Run Benchmark` action, download the artifacts and add them in the `code/artifacts/Penelopt-no-watchdog/` folder of this repository.

   2.4 Penelopt monotone benchmarks: copy this PR onto your fork: https://github.com/JuliaSmoothOptimizers/Penelopt.jl/pull/269 and give it the `run CUTEst benchmark` label. This triggers the `Run Benchmark` action, download the artifacts and add them in the `code/artifacts/Penelopt-monotone/` folder of this repository.

3. Go to the `actions` tab of this repository.

   3.1 Uno benchmarks: run the `Run Uno Benchmark` action. Once it finishes, download the artifacts and add them in the `code/artifacts/Uno/` folder of this repository.

   3.2 MadNLP benchmarks: run the `Run MadNLP Benchmark` action. Once it finishes, download the artifacts and add them in the `code/artifacts/MadNLP/` folder of this repository.

4. Reproduce the figures using the guide above.

### Option 2: Locally

You need Julia 1.x and git. The GitHub runs used the latest stable Julia release on `windows-latest` runners. The commands below are for bash (Linux, macOS, or Git Bash on Windows). In PowerShell, replace `CUTEST_SPLIT=1 julia ...` with `$env:CUTEST_SPLIT=1; julia ...`.

Each benchmark script handles one part ("split") of the CUTEst problem set. `CUTEST_SPLIT` picks the split, so every script has to be run once per split. Splits are independent, so you can run them in parallel in separate terminals. Parallel runs share the CPU, though, which skews the timings.

Results are moved into `Benchmark-runners/code/artifacts/<solver>/` and replace the results that ship with this repository. Running `git checkout code/artifacts` restores the originals. `plot-paper.jl` reads every `.jld2` file in each folder, subfolders included, so the commands below empty each folder before moving new results in.

1. Clone both repositories side by side, with Penelopt at the `v1.0.0` tag:

   ```bash
   mkdir penelopt-benchmarks && cd penelopt-benchmarks
   git clone --branch v1.0.0 https://github.com/JuliaSmoothOptimizers/Penelopt.jl
   git clone https://github.com/MaxenceGollier/Benchmark-runners
   ```

2. Set up the Penelopt benchmark environment:

   ```bash
   cd Penelopt.jl
   julia --project=benchmark -e 'using Pkg; Pkg.instantiate()'
   mkdir -p benchmark/result
   ```

3. Penelopt benchmarks (L-BFGS: 4 splits, exact Hessian: 2 splits):

   ```bash
   for s in 1 2 3 4; do CUTEST_SPLIT=$s julia --project=benchmark benchmark/benchmark-cutest-lbfgs.jl; done
   for s in 1 2;     do CUTEST_SPLIT=$s julia --project=benchmark benchmark/benchmark-cutest-exact-hessian.jl; done

   rm -rf ../Benchmark-runners/code/artifacts/Penelopt/*
   mv benchmark/result/stats_lbfgs_*.jld2 benchmark/result/stats_exact_*.jld2 ../Benchmark-runners/code/artifacts/Penelopt/
   ```

4. Ipopt benchmarks:

   ```bash
   for s in 1 2 3 4; do CUTEST_SPLIT=$s julia --project=benchmark benchmark/benchmark-cutest-ipopt-lbfgs.jl; done
   for s in 1 2;     do CUTEST_SPLIT=$s julia --project=benchmark benchmark/benchmark-cutest-ipopt-exact-hessian.jl; done

   rm -rf ../Benchmark-runners/code/artifacts/IPOPT/*
   mv benchmark/result/stats_ipopt_*.jld2 ../Benchmark-runners/code/artifacts/IPOPT/
   ```

5. Penelopt without watchdog. In `benchmark/benchmark-cutest-exact-hessian.jl`, add `r2n_watchdog = false` to the `L2Penalty` call. This is the same one-line change as [PR #272](https://github.com/JuliaSmoothOptimizers/Penelopt.jl/pull/272):

   ```julia
   stats = L2Penalty(
     nlp,
     ...
     linear_solver = "mumps",
     r2n_watchdog = false,
   )
   ```

   Then run the exact-Hessian benchmark, move the results, and undo the change:

   ```bash
   for s in 1 2; do CUTEST_SPLIT=$s julia --project=benchmark benchmark/benchmark-cutest-exact-hessian.jl; done

   mkdir -p ../Benchmark-runners/code/artifacts/Penelopt-no-watchdog
   rm -rf ../Benchmark-runners/code/artifacts/Penelopt-no-watchdog/*
   mv benchmark/result/stats_exact_*.jld2 ../Benchmark-runners/code/artifacts/Penelopt-no-watchdog/
   git checkout benchmark/benchmark-cutest-exact-hessian.jl
   ```

6. Monotone Penelopt. Do the same as step 5, but add `r2n_m_monotone = 1` instead. This is the change in [PR #269](https://github.com/JuliaSmoothOptimizers/Penelopt.jl/pull/269):

   ```bash
   for s in 1 2; do CUTEST_SPLIT=$s julia --project=benchmark benchmark/benchmark-cutest-exact-hessian.jl; done

   mkdir -p ../Benchmark-runners/code/artifacts/Penelopt-monotone
   rm -rf ../Benchmark-runners/code/artifacts/Penelopt-monotone/*
   mv benchmark/result/stats_exact_*.jld2 ../Benchmark-runners/code/artifacts/Penelopt-monotone/
   git checkout benchmark/benchmark-cutest-exact-hessian.jl
   ```

7. Uno and MadNLP benchmarks, from this repository:

   ```bash
   cd ../Benchmark-runners

   julia --project=code/benchmarks/Uno -e 'using Pkg; Pkg.instantiate()'
   for s in 1 2; do CUTEST_SPLIT=$s julia --project=code/benchmarks/Uno code/benchmarks/Uno/benchmark-cutest-uno-exact-hessian.jl; done
   rm -rf code/artifacts/Uno/*
   mv code/benchmarks/Uno/result/stats_uno_exact_*.jld2 code/artifacts/Uno/

   julia --project=code/benchmarks/MadNLP -e 'using Pkg; Pkg.instantiate()'
   for s in 1 2; do CUTEST_SPLIT=$s julia --project=code/benchmarks/MadNLP code/benchmarks/MadNLP/benchmark-cutest-madnlp-exact-hessian.jl; done
   rm -rf code/artifacts/MadNLP/*
   mv code/benchmarks/MadNLP/result/stats_madnlp_exact_*.jld2 code/artifacts/MadNLP/
   ```

8. From the root of this repository, rebuild the figures as described in [How to reproduce the figures](#how-to-reproduce-the-figures). Figures are written to `paper/figs/` and tables to `paper/tables/`.

Each problem has a 300 s time limit, so a full run takes several hours. Timings will also differ from the published results, which were run on GitHub's `windows-latest` runners.