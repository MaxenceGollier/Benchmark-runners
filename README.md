## How to reproduce the figures

1. Clone this repository.

    ```bash
    mkdir penelopt-benchmarks && cd penelopt-benchmarks

    git clone --branch v1.0.0 https://github.com/MaxenceGollier/Benchmark-runners
    ```

2. Run the following Julia script.
    ```julia
    using Pkg
    Pkg.activate("Benchmark-runners/code")
    Pkg.instantiate()

    include("Benchmark-runners/code/plot-paper.jl")
    ```

3. Figures are in the `Benchmark-runners/paper/figs/` folder.

## How to reproduce the benchmark runs

1. Clone both repositories side by side, with Penelopt at the `v1.0.0` tag:

   ```bash
   mkdir penelopt-benchmarks && cd penelopt-benchmarks
   git clone --branch v1.0.0 https://github.com/JuliaSmoothOptimizers/Penelopt.jl
   git clone --branch v1.0.0 https://github.com/MaxenceGollier/Benchmark-runners
   ```

2. Run the following Julia script:

   ```julia
    using Pkg
    Pkg.activate("Benchmark-runners/code")
    Pkg.instantiate()

    Pkg.develop(path = "Penelopt.jl") # Use local Penelopt installation

    include("Benchmark-runners/code/run-benchmarks.jl")
   ```

   Note: on MacOS/Linux you need `gfortran` to be installed to let the script generate the CUTEst problems.

3. Artifacts can be found in the `Benchmark-runners/code/artifacts/` folder.

## Precomputed artifacts source
The repository contains precomputed artifacts generated from GitHub actions.
These runs are publicly available at the following addresses:

* Artifacts for the Penelopt benchmarks: https://github.com/JuliaSmoothOptimizers/Penelopt.jl/actions/runs/43953883491
* Artifacts for the IPOPT benchmarks: https://github.com/JuliaSmoothOptimizers/Penelopt.jl/actions/runs/43102707373
* Artifacts for the MadNLP benchmarks: https://github.com/MaxenceGollier/Benchmark-runners/actions/runs/43512053245
* Artifacts for the Uno benchmarks: https://github.com/MaxenceGollier/Benchmark-runners/actions/runs/43512064959
* Artifacts for Penelopt without watchdog benchmarks: https://github.com/JuliaSmoothOptimizers/Penelopt.jl/actions/runs/43954434444
* Artifacts for monotone Penelopt benchmarks: https://github.com/JuliaSmoothOptimizers/Penelopt.jl/actions/runs/43954397609
