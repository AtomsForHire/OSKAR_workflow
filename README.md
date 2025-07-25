# OSKAR_workflow
A nextflow pipline for running OSKAR simulations with different telescope
models, sky models, and various other parameters like pointing and errors,
followed by calibration with Hyperdrive.

> [!WARNING]
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

> [!WARNING]
> Nextflow is a great tool, *once* it works. It is very picky about syntax, and
> the errors produced by nextflow are not informative at all. **Make sure you
> check for syntax problems!**

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

Define what sky models you want to simulate:
```nextflow
params.sky_models = [ "/path/to/sky_model.osm",
    "/path/to/another_sky_model.osm",
]
```

Define telescope models you want to use (note there is no `/` at the end of the
paths):
```nextflow
params.telescope_models = [ "/path/to/telescope_model",
    "/path/to/another_tm",
]
```

Define pointings you want to use:
```nextflow
params.pointings = [
    [ name: 'EoR0', 
        ra: 0.0, 
        dec: -27.0, 
        start_time_utc: '2000-01-01 00:00:00.0',
        x_gain: 0.0,
        y_gain: 0.0,
        x_gain_error_time: 0.0,
        y_gain_error_time: 0.0,
    ],
    [ name: 'LST_5.2', 
        ra: 78.0, 
        dec: -30.0, 
        start_time_utc: '2000-01-01 00:00:00.0',
        x_gain: 0.0,
        y_gain: 0.0,
        x_gain_error_time: 1.0,
        y_gain_error_time: 1.0,
    ],
]
```

Define beam simulation settings:
```nextflow
params.beam_settings = [ 
    General: [ app: 'oskar_sim_beam_pattern' ], // Do not change this
    beam_pattern: [
        'beam_image/fov_deg':180.0,
        'station_outputs/fits_image/amp':true,
        'root_path': null,
        // Add other options here if you need
    ]
]
```

Define interferometer simulation settings:
```nextflow
params.interferometer_settings = [
    General: [ app: 'oskar_sim_interferometer' ], // Do not change this
    interferometer: [
        ms_filename: null, // This will be set dynamically by the process
        channel_bandwidth_hz: 1e6,
        time_average_sec: 1.0
        // Add other options here if you need
    ]
]
```

Define global/base OSKAR settings that will be used throughout all runs:
```nextflow
params.oskar_settings = [
    General: [
        version: "2.11.0"
    ],
    simulator: [
        use_gpus: true,
        double_precision: true,
    ],
    sky: [
        'oskar_sky_model/file': null // This will be set dynamically by the process
    ],
    observation: [
        start_frequency_hz: 100e6,
        num_channels: 3,
        frequency_inc_hz: 1e6,
        phase_centre_ra_deg: 20.0,
        phase_centre_dec_deg: -30.0,
        num_time_steps: 10,
        length: '02:00:00.0'
    ],
    telescope: [
        input_directory: null // This will be set dynamically by the process
    ],
]
```

Define Hyperdrive settings (you are not able to add more than these):
```nextflow
params.hyperdrive_settings = [
    veto_threshold: 0.01,
    source_dist_cutoff: 5,
    source_list: '/path/to/srclist',
]
```

## Running
To execute the workflow after preparing the settings, simply run:
```
nextflow run main.nf
```
