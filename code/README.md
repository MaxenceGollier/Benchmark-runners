Artifacts for the Penelopt benchmarks: https://github.com/MaxenceGollier/Penelopt.jl/actions/runs/34887009444
Artifacts for the IPOPT benchmarks: https://github.com/MaxenceGollier/Penelopt.jl/actions/runs/34865456975
Artifacts for the MadNLP benchmarks: https://github.com/MaxenceGollier/Benchmark-runners/actions/runs/35108825881
Artifacts for the Uno benchmarks: https://github.com/MaxenceGollier/Benchmark-runners/actions/runs/35129844604

## How to reproduce the figures
```julia
using Pkg
Pkg.activate("code")

include("code/plot-paper.jl")
```