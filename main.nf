include { PROCESS_SERIAL } from './subworkflows/process_serial'

workflow {
    sky_models_ch = Channel.fromList(params.sky_models)
    tel_models_ch = Channel.fromList(params.telescope_models)
    pointings_ch = Channel.fromList(params.pointings)

    combined_ch = sky_models_ch.combine(tel_models_ch).combine(pointings_ch)

    PROCESS_SERIAL(combined_ch)
}
