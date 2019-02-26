var dcn_ready;
dcn_ready = function () {

    $(".dcn-contact").click(function () {
        window.location.href = "mailto:researchdata@illinois.library.illinois.edu"
    });

    $(".dcn-login").click(function () {
        window.location.href = "/data_curation_network/log_in"
    });

    $(".dcn-home").click(function () {
        window.location.href = "/data_curation_network"
    });

}
$(document).ready(dcn_ready);
$(document).on('page:load', dcn_ready);