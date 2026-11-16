* Artifacts for the Penelopt benchmarks: https://github.com/MaxenceGollier/Penelopt.jl/actions/runs/34887009444

* Artifacts for the IPOPT benchmarks: https://github.com/JuliaSmoothOptimizers/Penelopt.jl/actions/runs/43102707373

* Artifacts for the MadNLP benchmarks: https://github.com/MaxenceGollier/Benchmark-runners/actions/runs/43512053245

* Artifacts for the Uno benchmarks: https://github.com/MaxenceGollier/Benchmark-runners/actions/runs/43512064959

* Artifacts for Penelopt without watchdog benchmarks:

* Artifacts for monotone Penelopt benchmarks:

## How to reproduce the figures
```julia
using Pkg
Pkg.activate("code")

include("code/plot-paper.jl")
```
