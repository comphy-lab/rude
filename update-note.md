# RUDE Repository Update Note

## Original Setup and Encountered Issues

The Rheological Universal Differential Equations (RUDE) repository was originally developed using Julia v1.8.3 with specific package versions [see requirements-old.txt](requirements-old.txt):

- Flux v0.13.9
- Optimization v3.10.0
- Optimisers v0.2.14
- OptimizationOptimisers v0.1.1
- SciMLSensitivity v7.11.1
- DifferentialEquations v7.6.0
- Zygote v0.6.51
- Enzyme v0.10.12
- PyPlot v2.11.0
- OrdinaryDiffEq v6.35.1
- DataInterpolations v3.10.1
- BSON v0.3.6
- FFTW v1.5.0

When attempting to install these specific package versions using the original installation script, several errors were encountered:

1. Precompilation failures for differential equation packages:
   - OrdinaryDiffEq
   - StochasticDiffEq
   - DelayDiffEq
   - SciMLSensitivity
   - DifferentialEquations

2. The primary error was: `UndefVarError: AbstractDiffEqLinearOperator not defined`
   - This suggests a version mismatch between interdependent packages in the SciML ecosystem

3. Multiple downgrade/upgrade cycles in the package resolution process indicates complex compatibility constraints between packages

> Note to reproduce
Run
```bash
bash install_dependencies-old.sh
```

## Update Plan

Instead of trying to maintain the original package versions, I will update the repository to work with the latest Julia and package versions. This approach should provide:

1. Improved performance from newer implementations
2. Better compatibility with current systems
3. Access to new features and bug fixes
4. Better long-term maintenance

### Tasks

- [X] Upgrade to latest stable Julia version (currently 1.10.x)
- [X] Create a fresh environment with latest package versions
- [ ] Test all functionality against example cases
- [ ] Compare results with the original implementation
- [ ] Document any behavior differences

### Erorrs due to invompatibility:

This error are most likely due to the incompatibility of the codebase with the latest Julia (and other package) version._

```
MethodError: Cannot `convert` an object of type VectorOfArray{Float32, 2, Vector{Vector{Float32}}} to an object of type ODESolution{...}
```
> The error occurs in the `loss_univ` function at line 185 of (older version of) rude.jl and propagates through the Zygote automatic differentiation system. It's essentially a compatibility issue where a solution from a differential equation solver needs to be converted to another type for gradient calculation, but the conversion method doesn't exist.


## Progress Updates

This section will be updated as the migration progresses.

*Last updated: April 17, 2025*