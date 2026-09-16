Artifacts for the Penelopt benchmarks: https://github.com/MaxenceGollier/Penelopt.jl/actions/runs/34887009444
Artifacts for the IPOPT benchmarks: https://github.com/MaxenceGollier/Penelopt.jl/actions/runs/34865456975
MadNLP benchmarks: run `Run MadNLP Benchmark` in this repo's Actions tab (code/benchmarks/MadNLP), then place the downloaded artifacts under code/artifacts/MadNLP. TODO: link the run once it has been executed.
Uno benchmarks: run `Run Uno Benchmark` in this repo's Actions tab (code/benchmarks/Uno), then place the downloaded artifacts under code/artifacts/Uno. TODO: link the run once it has been executed.


## How to reproduce the figures
```julia
using Pkg
Pkg.activate("code")

include("code/plot-paper.jl")
```