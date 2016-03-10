
var databank_ready;
databank_ready = function () {
    $('#describe-btn').click(function () {
        window.location.assign('/help#describe');
    });
    $('#upload-btn').click(function () {
        window.location.assign('/help#upload');
    });
    $('#review-btn').click(function () {
        window.location.assign('/help#review');
    });
    $('#publish-btn').click(function () {
        window.location.assign('/help#publish');
    });
    //alert("databank.js javascript working");
}

$(document).ready(databank_ready);
$(document).on('page:load', databank_ready);
