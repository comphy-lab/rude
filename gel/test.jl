println("Hello, Julia is working!")

# Simple calculation
a = 2 + 2
println("2 + 2 = ", a)

using Flux, Optimization, OptimizationOptimisers, SciMLSensitivity
using DifferentialEquations
using Zygote, PyPlot, LinearAlgebra, OrdinaryDiffEq, DelimitedFiles
using DataInterpolations
using BSON: @save, @load
using FFTW
using Pkg

deps = Pkg.dependencies()
function get_version(pkgname)
    for (uuid, pkg) in deps
        if pkg.name == pkgname
            return pkg.version
        end
    end
    return "Not found"
end

println("Package versions:")
println("Flux: ", get_version("Flux"))
println("Optimization: ", get_version("Optimization"))
println("OptimizationOptimisers: ", get_version("OptimizationOptimisers"))
println("SciMLSensitivity: ", get_version("SciMLSensitivity"))
println("DifferentialEquations: ", get_version("DifferentialEquations"))
println("Zygote: ", get_version("Zygote"))
println("PyPlot: ", get_version("PyPlot"))
println("LinearAlgebra: ", get_version("LinearAlgebra"))
println("OrdinaryDiffEq: ", get_version("OrdinaryDiffEq"))
println("DelimitedFiles: ", get_version("DelimitedFiles"))
println("DataInterpolations: ", get_version("DataInterpolations"))
println("BSON: ", get_version("BSON"))
println("FFTW: ", get_version("FFTW"))

println("Pkg: ", pkgversion(Pkg))



