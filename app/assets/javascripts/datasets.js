var MAX_FILESIZE = 2147483648;

var confirmOnPageExit
confirmOnPageExit = function (e)
{
    // If we haven't been passed the event get the window.event
    e = e || window.event;

    var message = 'If you navigate away from this page, unsaved changes will be lost.';

    // For IE6-8 and Firefox prior to version 4
    if (e)
    {
        e.returnValue = message;
    }

    // For Chrome, Safari, IE8+ and Opera 12+
    return message;
};

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
        $('#checkAllFiles').prop('checked', false );
    });

    $('#term-supports').tooltip();

    $('#cancel-button').click(function () {
        alert("You must agree to the Deposit Agreement before depositing data into Illinois Data Bank.");
    });

    $('#dropdown-login').click(function(event)
    {
        if (event.stopPropagation){
            event.stopPropagation();
        }
        else if(window.event){
            window.event.cancelBubble=true;
        }
    });

    $('.save-button').click(function () {
        window.onbeforeunload = null;
        //$('.dataset-form')[0].submit();
    });

    $('input.dataset').change(function() {
        if( $(this).val() != "" )
            window.onbeforeunload = confirmOnPageExit;
    });

    $(document).on('change', '.file-field', handleFilesize );

    $('#show-all-radio, #show-my-radio').change(function() {
        var selectedVal = $('input[name=filterOpt]:checked').val();
        if (selectedVal == 'all'){
            window.location.assign('/datasets');
        }
        else {
            window.location.assign('/datasets?depositor_email=' + selectedVal);
        }

    });

}

function handleFilesize(){
    f = this.files[0];
    num_bytes = f.size||f.fileSize;
    if (num_bytes > MAX_FILESIZE){
        alert("For files larger than 2GB, please contact the Research Data Service.");
        this.value = '';
    }
}


function setDepositor(email, name){
    $('#depositor_email').val(email);
    $('#depositor_name').val(name);
}

$(document).ready(ready);
$(document).on('page:load', ready);

