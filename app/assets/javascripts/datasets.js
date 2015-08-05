// work-around turbo links to trigger ready function stuff on every page.

var ready;
ready = function() {

    $("#checkFileSelectedCount").html('0');

    $("#checkAllFiles").click(function () {
        $(".checkFileGroup").prop('checked', $(this).prop('checked'));
        $("#checkFileSelectedCount").html($('.checkFile:checked').size());
    });

    $(".checkFileGroup").change(function () {
        $("#checkFileSelectedCount").html($('.checkFile:checked').size());
    });

    $('#term-supports').tooltip();

}

$(document).ready(ready);
$(document).on('page:load', ready);