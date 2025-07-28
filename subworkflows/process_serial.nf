// Define a function to read in a map and return an equivalent settings string
def buildIniContent(Map settings) {
    def builder = new StringBuilder()
    settings.each { section, pairs ->
        builder.append("[$section]\n")
        pairs.each { key, value ->
            if (value != null) builder.append("$key=$value\n")
        }
        builder.append("\n")
    }
    return builder.toString()
}

def deepCopy(orig) {
    def copy = [:]
    orig.each { key, value ->
        if (value instanceof Map) {
            copy[key] = deepCopy(value)
        } else if (value instanceof List) {
            copy[key] = value.clone()
        }
        else {
            copy[key] = value
        }
    }
    return copy
}

process runEverything {
    tag "Simulating ${pointing.name} with ${file(sky_model).baseName} with ${file(telescope_model)}"

    publishDir "${params.out_dir}/${file(sky_model).baseName}_${file(telescope_model).baseName}_${pointing.name}", mode: 'move'

    input:
    tuple path(sky_model), path(telescope_model), val(pointing)

    output:
    path("*.ms"), emit: measurement_set, optional: true
    path("*.ini"), emit: settings_file
    path("*.fits"), emit: beam_patterns, optional: true

    shell:

    def sm = sky_model
    def tm = telescope_model
    def pt = pointing

    // Prepare base settings used by both int and beam sims
    // def base_settings = params.oskar_settings.clone()
    def base_settings = deepCopy(params.oskar_settings)
    base_settings.sky['oskar_sky_model/file'] = file(sm)
    base_settings.telescope.input_directory = file(tm)
    base_settings.telescope.x_gain = pt.x_gain
    base_settings.telescope.y_gain = pt.y_gain
    base_settings.telescope.x_gain_error_time = pt.x_gain_error_time
    base_settings.telescope.y_gain_error_time = pt.y_gain_error_time
    base_settings.observation.phase_centre_ra_deg = pt.ra
    base_settings.observation.phase_centre_dec_deg = pt.dec
    base_settings.observation.start_time_utc = pt.start_time_utc

    def command = ""

    // == BEAM SIMULATION ==
    if (params.run_beam_sim) {
        def beam_settings = base_settings.clone()
        // Add beam-specific settings
        beam_settings += params.beam_settings
        // Set dynamic values
        def beam_root_path = "${file(sm).baseName}_${file(tm).name}_${pt.name}"
        beam_settings.beam_pattern.root_path = beam_root_path

        def beam_ini_content = buildIniContent(beam_settings)
        def beam_ini_filename = "oskar_sim_beam.ini"

        command += """
        echo "--- Preparing Beam Pattern Simulation ---"
        printf '%s' '${beam_ini_content}' > ${beam_ini_filename}
        #${params.oskar_sim_beam} ${beam_ini_filename}
        """
    }

    // == INTERFEROMETER SIMULATION ==
    if (params.run_int_sim) {
        def int_settings = base_settings.clone()
        // Add interferometer-specific settings
        int_settings += params.interferometer_settings
        // Set dynamic values
        def output_ms = "${file(sm).baseName}_${file(tm).name}_${pt.name}.ms"
        int_settings.interferometer.ms_filename = output_ms

        def int_ini_content = buildIniContent(int_settings)
        def int_ini_filename = "oskar_sim_interferometer.ini"

        command += """
        echo "--- Preparing Interferometer Simulation ---"
        printf '%s' '${int_ini_content}' > ${int_ini_filename}
        #${params.oskar_sim_interferometer} ${int_ini_filename}
        """

        // == HYPERDRIVE ==
        if (params.run_hyperdrive) {
            command += """
            #${params.hyperdrive_command} -d ${output_ms} \
            #-s ${params.hyperdrive_settings.source_list} \
            #--no-precession \
            #--veto-threshold ${params.hyperdrive_settings.veto_threshold} \
            #--source-dist-cutoff ${params.hyperdrive_settings.source_dist_cutoff}

            # ${params.hyperdrive_command} solutions-plot hyperdrive_solutions.fit

            #${params.hyperdrive_command} solutions-apply \
            #-d ${output_ms} \
            #-s hyperdrive_solutions.fits 
            """
        }

        // == WSCLEAN ==
        if (params.run_wsclean) {
            command += """
            """
        }
    }

    // == WSCLEAN ==


    // Execute final command string
    """
    #!/bin/bash
    ${command}
    """
}

workflow PROCESS_SERIAL {
    take:
        input_val

    main:
        runEverything(input_val)
}
