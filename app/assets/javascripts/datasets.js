var MAX_FILESIZE = 2147483648;
var MIN_FILESIZE = 1;

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
        handleNotAgreed();
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
        $('#dataset-submit-button').click();
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

    $('[data-toggle="tooltip"]').tooltip();

    handleNotAgreed();
}

function handleNotAgreed(){

    $('#new-save-button').attr("disabled", true);
    $('#new-save-button').text('<- Deposit Agreement Required to Save');
    //$('.file-field').attr("disabled", true);
    //$('.add-attachment-subform-button').attr("disabled", true);
    //$('.add-attachment-subform-button').hide();
    //$('.deposit-agreement-file-warning').text("Deposit Agreement Required to Add Files");
    $('#show-agreement-modal-link').show();
}

function handleFilesize(){
    f = this.files[0];
    num_bytes = f.size||f.fileSize;
    if (num_bytes > MAX_FILESIZE){
        alert("For files larger than 2GB, please contact the Research Data Service.");
        this.value = '';
    }
    else if (num_bytes == null || num_bytes < MIN_FILESIZE){
        alert("No file contents found, please contact the Research Data Service for assistance.");
        this.value = '';
    }
    else {
        //alert(num_bytes);
    }

}

function setDepositor(email, name){
    $('#depositor_email').val(email);
    $('#depositor_name').val(name);
    $('#new-save-button').text('Save & Review');
    $('#new-save-button').removeAttr("disabled");
    $('.file-field').removeAttr("disabled");
    $('.add-attachment-subform-button').show();
    $('.add-attachment-subform-button').removeAttr("disabled");
    $('.deposit-agreement-file-warning').text("");
    $('#show-agreement-modal-link').hide();
}

$(document).ready(ready);
$(document).on('page:load', ready);

