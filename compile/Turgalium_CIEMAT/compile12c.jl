using PackageCompiler

create_sysimage([:Gridap,:PartitionedArrays,:GridapMHD],
  sysimage_path=joinpath(@__DIR__,"..","GridapMHD12c.so"),
  precompile_execution_file=joinpath(@__DIR__,"warmup.jl"))
