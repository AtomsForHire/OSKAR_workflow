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

process run_oskar {
    input:
        val(sky_model), val(telescope_model), val(pointing)
}

process run_hyperdrive {
    tag "Calibrating ${measurement_set}"

    input:
        path(measurement_set)

    output:
        path("*.uvfits"), emit: solutions
        path("*.png")
        path("*.fits")

    script:
    command = """
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

    """
    #!/bin/bash
    ${command}
    """
};

workflow PROCESS_PARALLEL {
    take:
        input_val

    main:
}
