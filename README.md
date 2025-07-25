# OSKAR_workflow
A nextflow pipline for running OSKAR simulations with different telescope
models, sky models, and various other parameters like pointing and errors,
followed by calibration with Hyperdrive.

> ![WARNING]
> Due to the resource limitations of the machine I'm running this on, I have
> implemented only a serial pipeline. i.e. For a set of observing parameters,
> OSKAR will be run first then Hyperdrive then WSCLEAN. Only once the first set
> is of parameters is done, the next set can begin.

# Installation
You will need to install [nextflow](https://www.nextflow.io/) to run this
script.

# Usage
All settings can be found in the `nextflow.config` file. Comments are in there
to help the user understand what each option does.

## Important Settings 
Define what processes you want to run in the first `params` block:
```nextflow
params {
    // What do you want to run?
    run_beam_sim = <true|false>
    run_int_sim = <true|false>
    run_hyperdrive = <true|false>
    run_wsclean = <true|false>

    ...
}

```
