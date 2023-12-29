module GridapMHD

using Random
using LinearAlgebra
using SparseArrays
using SparseMatricesCSR
using BlockArrays

using FileIO
using BSON
using DrWatson

using Gridap
using Gridap.Helpers, Gridap.Algebra, Gridap.CellData, Gridap.ReferenceFEs
using Gridap.Geometry, Gridap.FESpaces, Gridap.MultiField

using GridapDistributed
using GridapGmsh
using GridapPETSc

using GridapSolvers
using GridapSolvers.LinearSolvers, GridapSolvers.NonlinearSolvers, GridapSolvers.BlockSolvers

using PartitionedArrays
using PartitionedArrays: getany

# Mesh generation
include("Meshers/meshers.jl")

# Solvers
include("Solvers/petsc.jl")
include("Solvers/li2019.jl")
include("Solvers/badia2024.jl")

# Main driver
include("Fixes.jl")
include("ExtraFunctions.jl")
include("parameters.jl")
include("weakforms.jl")
include("Main.jl")

# Applications
include("Applications/hunt.jl")
include("Applications/expansion.jl")
include("Applications/cavity.jl")

export hunt, expansion, cavity

end # module
