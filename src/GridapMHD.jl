module GridapMHD

# using Profile
# using FileIO
# using MPI

using Random
using LinearAlgebra
using SparseArrays
using SparseMatricesCSR
using BlockArrays

using FileIO
using BSON
using DrWatson

using Gridap
using Gridap.Helpers
using Gridap.Algebra
using Gridap.CellData
using Gridap.ReferenceFEs
using Gridap.Geometry
using Gridap.FESpaces
using Gridap.MultiField

using GridapDistributed
using GridapGmsh

using GridapPETSc
using GridapPETSc.PETSC

using GridapSolvers
using GridapSolvers.LinearSolvers
using GridapSolvers.LinearSolvers: allocate_in_domain, allocate_in_range

using PartitionedArrays
using PartitionedArrays: getany

# Mesh generation
include("Meshers/meshers.jl")

# Solvers
include("Li2019/Li2019.jl")

# Main driver
include("Fixes.jl")
include("ExtraFunctions.jl")
include("parameters.jl")
include("Main.jl")

# Applications
include("Applications/hunt.jl")
include("Applications/expansion.jl")
include("Applications/cavity.jl")

export hunt, expansion, cavity

end # module
