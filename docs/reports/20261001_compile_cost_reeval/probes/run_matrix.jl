# Runs a list of measurements, one process each, and appends one line per run.
#   julia run_matrix.jl <study_dir> <jobs_file> <out_file> [workers = 1] [cap_seconds = 1200]
#
# A job line is `label export opt scenario mode chunk reps`; `#` starts a
# comment. `export` names a directory under <study_dir>. A run over the cap is
# killed and recorded as TIMEOUT.
study, jobs_file, out_file = ARGS[1:3]
workers = length(ARGS) > 3 ? parse(Int, ARGS[4]) : 1
cap = length(ARGS) > 4 ? parse(Int, ARGS[5]) : 1200
measure = joinpath(@__DIR__, "measure.jl")

jobs = NTuple{7,String}[]
for line in eachline(jobs_file)
    fields = split(strip(first(split(line, '#'))))
    isempty(fields) && continue
    label, exp, opt, scenario, mode, chunk, reps = fields
    for rep in 1:parse(Int, reps)
        push!(jobs, (label, exp, opt, scenario, mode, chunk, string(rep)))
    end
end

function measure_once((label, exp, opt, scenario, mode, chunk, rep))
    cmd = `julia -O$opt --project=$(joinpath(study, exp, "test")) $measure $scenario $mode $chunk`
    out = IOBuffer()
    t0 = time()
    proc = run(pipeline(cmd; stdout = out, stderr = devnull); wait = false)
    while process_running(proc) && time() - t0 < cap
        sleep(0.5)
    end
    head = "label=$label export=$exp rep=$rep"
    if process_running(proc)
        kill(proc)
        return "$head TIMEOUT scenario=$scenario mode=$mode chunk=$chunk opt=$opt cap=$cap"
    end
    lines = filter(startswith("RESULT"), split(String(take!(out)), '\n'))
    isempty(lines) ? "$head FAILED scenario=$scenario mode=$mode chunk=$chunk opt=$opt" :
                     "$head $(lines[1])"
end

# Resume: a run already recorded in the output file is skipped.
field(line, key) = (m = match(Regex("(?:^| )$key=(\\S+)"), line); m === nothing ? "" : String(m[1]))
if isfile(out_file)
    recorded = Set((field(l, "label"), field(l, "opt"), field(l, "scenario"), field(l, "mode"),
                    field(l, "rep")) for l in eachline(out_file))
    filter!(j -> (j[1], j[3], j[4], j[5], j[7]) ∉ recorded, jobs)
end
println("$(length(jobs)) runs to do")

lock_out = ReentrantLock()
asyncmap(jobs; ntasks = workers) do job
    line = measure_once(job)
    lock(lock_out) do
        open(io -> println(io, line), out_file, "a")
    end
end
