using Mustache
using DrWatson
using Dates

mkpath(datadir())

function tostr(v,n)
  lpad(v,n,'0')
end

function jobtitle(params)
  cx = params[:cx]
  px = params[:px]
  ha = params[:ha]
  nr = params[:nr]
  ns = params[:ns]
  ps = params[:ps]
  km = params[:km]
  title="ha$(tostr(ha,5))cx$(tostr(cx,3))px$(tostr(px,2))ns$(tostr(ns,3))ps$(tostr(ps,2))km$(tostr(km,1))"
end

function petsc_options(i)
  if i == 1
    "-snes_monitor -ksp_error_if_not_converged true -ksp_converged_reason -ksp_type preonly -pc_type lu -pc_factor_mat_solver_type mumps"
  else
    error()
  end
end

# Small convergence test

allparams = Dict(
 :ha=>[500],
 :cx=>[15,30,45,64,90,129,179],
 :px=>[2],
 :nr=>[1],
 :ns=>[100],
 :ps=>[1],
 :km=>[1])

params = dict_list(allparams)
dicts = map(params) do params
  cx = params[:cx]
  px = params[:px]
  ha = params[:ha]
  nr = params[:nr]
  ns = params[:ns]
  ps = params[:ps]
  km = params[:km]
  title=jobtitle(params)
  Dict(
   :q=>"normal",
   :walltime=>"00:30:00",
   :ncpus=>px^2,
   :mem=>"180gb",
   :jobfs=>"1gb",
   :name=>title,
   :n=>px^2,
   :nc=>(cx,cx),
   :np=>(px,px),
   :B=>(0.,Float64(ha),0.),
   :debug=>"false",
   :vtk=>"false",
   :title=>title,
   :path=>datadir(),
   :nruns=>nr,
   :nsums=>ns,
   :kmap=>km,
   :petsc_options=>petsc_options(ps),
  )
end

template = read(scriptsdir("jobtemplate"),String)

for dict in dicts
  jobfile = datadir(dict[:name]*".sh")
  open(jobfile,"w") do io
    render(io,template,dict|>tostringdict)
  end
end

# Scaling

allparams = Dict(
 :ha=>[500],
 :cx=>[179],
 :px=>[2,3,4,6,8,12,16],
 :nr=>[2],
 :ns=>[100],
 :ps=>[1],
 :km=>[1])

function get_walltime(tmax,tmin,n)
  msmax = Millisecond(tmax)
  msmin = Millisecond(tmin)
  ms = Millisecond(ceil(msmax.value/n))
  s = convert(Time,convert(DateTime,ms))
  smin = convert(Time,convert(DateTime,msmin))
  s < smin ? smin : s
end

params = dict_list(allparams)
dicts = map(params) do params
  cx = params[:cx]
  px = params[:px]
  ha = params[:ha]
  nr = params[:nr]
  ns = params[:ns]
  ps = params[:ps]
  km = params[:km]

  n = px^2
  wt = Hour(1)
  nnodes = ceil(n/48) |> Int
  title=jobtitle(params)
  Dict(
   :q=>"normal",
   :walltime=>get_walltime(Hour(1),Minute(30),n),
   :ncpus=>48*nnodes,
   :mem=>"$(185*nnodes)gb",
   :jobfs=>"1gb",
   :name=>title,
   :n=>n,
   :nc=>(cx,cx),
   :np=>(px,px),
   :B=>(0.,Float64(ha),0.),
   :debug=>"false",
   :vtk=>"false",
   :title=>title,
   :path=>datadir(),
   :nruns=>nr,
   :nsums=>ns,
   :kmap=>km,
   :petsc_options=>petsc_options(ps),
  )
end

template = read(scriptsdir("jobtemplate"),String)

for dict in dicts
  jobfile = datadir(dict[:name]*".sh")
  open(jobfile,"w") do io
    render(io,template,dict|>tostringdict)
  end
end

