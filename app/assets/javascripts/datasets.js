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
        // alert("You must agree to the Deposit Agreement before depositing data into Illinois Data Bank.");
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

    $('#new-save-button').click(function () {
        window.onbeforeunload = null;
        $('#new_dataset').submit();

    });
    $('#new-save-button').hide();

    $('.nav-item').click(function () {

        $('.nav-item').removeClass('current');
        $(this).addClass('current');
    });

    $('#update-save-button').click(function () {
        window.onbeforeunload = null;
        $("[id^=edit_dataset]").submit();

    });

    $('input.dataset').change(function() {
        if ($(this).val() != ""){
            window.onbeforeunload = confirmOnPageExit;
        }
     });

    $('#dataset_title').change(function() {
        $('#title-preview').html($(this).val() + '.');
    });

    $('#dataset_publication_year').change(function() {
        $('#year-preview').html('(' + $(this).val() + '):');
    });

    $('#dataset_identifier').change(function() {
        $('#doi-preview').html("http://dx.doi.org/" + $(this).val());
    });

    $('#show-all-button').click(function () {
        window.location.assign('/datasets');
    });

    $('#show-my-button').click(function () {
        var current_user_email = $('input#current_user_email').val();
        window.location.assign('/datasets?depositor_email=' + current_user_email);
    });

    $('[data-toggle="tooltip"]').tooltip();

    var clip = new ZeroClipboard($("#d_clip_button"))

    $("#login-prompt").modal('show');
    //alert("pre-validity check");
    //alert("dataset key: "+ dataset_key)

    $("#new_datafile").fileupload({
        downloadTemplate: null,
        downloadTemplateId: null,

        add: function(e, data) {
            file = data.files[0];
            num_bytes = file.size||file.fileSize;
            if (num_bytes < 2147483648 ){
                data.context = $(tmpl("template-upload", data.files[0]));
                $('#datafiles_upload_progress').append(data.context);
                return data.submit();
            } else {
                alert("For files larger than 2GB, please contact the Research Data Service.");
            }
      },
        progress: function(e, data) {
            var progress;
            if (data.context) {
                progress = parseInt(data.loaded / data.total * 100, 10);
                return data.context.find('.bar').css('width', progress + '%');
            }
        },
        downloadTemplate: function (o) {
            var file = o.files[0];

            var row = '<tr><td><div class = "row"><span class="col-md-8">' + file.name + '</span><span class="col-md-2">' + file.size + '</span><span class="col-md-2">';
            if (file.error){
                row = row + '<button type="button" class="btn btn-danger"><span class="glyphicon glyphicon-warning-sign"></span>';
            } else {
                row = row + '<a data-confirm="Are you sure?" class="btn btn-danger btn-sm" rel="nofollow" data-method="delete" href="/datafiles/' + file.web_id + '"><span class="glyphicon glyphicon-trash"></span></a></span>';
            }

            row = row + '</span></div></td></tr>';
            if (file.error){
                $("#datafiles > tbody:last-child").append('<tr><td><div class="row"><p>' + file.name + ': ' +  file.error + '</p></div></td></tr>');
            } else {
                $("#datafiles > tbody:last-child").append(row);
            }
        }
    });



    var boxSelect = new BoxSelect();
    // Register a success callback handler
    boxSelect.success(function(response) {
        console.log(response);


        $.each(response, function(i, boxItem){

            boxItem.dataset_key = dataset_key;

            $.ajax({
                type: "POST",
                url: "/datafiles/create_from_box",
                data: boxItem,
                success: function(data) {
                    eval($(data).text());
                },
                dataType: 'script'
            });

        });

    });

    // Register a cancel callback handler
    boxSelect.cancel(function() {
        console.log("The user clicked cancel or closed the popup");
    });

    $('#box-upload-in-progress').hide();

    var cells, desired_width, table_width;
    if ($("#creator_table tr").length > 0) {
        table_width = $('#creator_table').width();
        cells = $('#creator_table').find('tr')[0].cells.length;
        desired_width = table_width / cells + 'px';
        initialize_creator_index_list();
        handleCreatorTable();

        $('#creator_table td').css('width', desired_width);

        return $('#creator_table').sortable({

            axis: 'y',
            items: '.item',
            cursor: 'move',
            sort: function (e, ui) {
                return ui.item.addClass('active-item-shadow');
            },
            stop: function (e, ui) {
                ui.item.removeClass('active-item-shadow');
                return ui.item.children('td').effect('highlight', {}, 1000);
            },
            update: function (e, ui) {
                var item_id, position;
                item_id = ui.item.data('item-id');
                position = ui.item.index();
                handleCreatorTable();
                generate_creator_preview();
            }
        });

    }

    //alert("javascript working");

}


var Reflector = function(obj) {
    this.getProperties = function() {
        var properties = [];
        for (var prop in obj) {
            if (typeof obj[prop] != 'function') {
                properties.push(prop);
            }
        }
        return properties;
    };
}

function cancelUpload(datafile, job) {

    $("#job" + job).hide();

    $.ajax({
        type : 'GET',
        url : '/datasets/'+ dataset_key + '/datafiles/' + datafile + '/cancel_box_upload',
        dataType : 'script'
    });

    return false;
}

function handleNotAgreed(){

    $('.save').hide();
    $('.dataset').attr("disabled", true);
    $('.file-field').attr("disabled", true);
    $('.add-attachment-subform-button').hide();
    //$('#show-agreement-modal-link').show();
    $('.new-dataset-progress').hide();
    $('.deposit-agreement-warning').show();
    $('.search').removeAttr("disabled");
    $('.deposit-agreement-btn').removeAttr("disabled");;
    $('#show-agreement-modal-link').removeClass("btn-success");
    $('#show-agreement-modal-link').addClass("btn-warning");
    $('#new-save-button').hide();
    window.scrollTo(0,0);
}

function setDepositor(email, name){

    $('#depositor_email').val(email);
    $('#depositor_name').val(name);
    $('.save').show();
    $('.new-dataset-progress').show();
    $('.dataset').removeAttr("disabled");
    $('.file-field').removeAttr("disabled");
    $('.add-attachment-subform-button').show();
    $('.deposit-agreement-warning').hide();
    $('#show-agreement-modal-link').removeClass("btn-warning")
    $('#show-agreement-modal-link').addClass("btn-success")
    $('#new-save-button').show();
    //$('#show-agreement-modal-link').hide();
}

function handleAgreeModal(email, name){

    if ($('#owner-yes').is(":checked") && $('#agree-yes').is(":checked") && ($('#private-yes').is(":checked") ||$('#private-na').is(":checked") ) )  {
        setDepositor(email, name);
    } else {
        handleNotAgreed();
    }
}

function download_selected(){
    var file_ids = $("input[name='selected_files[]']:checked").map(function(index,domElement) {
        return $(domElement).val();
    });

    $.each(file_ids, function(i, file_id){
        fileURL = "<iframe class='hidden' src='/datasets/" + dataset_key + "/stream_file/" + file_id + "'></iframe>";
        $('#frames').append(fileURL);
    });
}

function uncheckPrivateNA(){
    $('#private-na').attr('checked', false);
}
function uncheckPrivateYes(){
    $('#private-yes').attr('checked', false);
}

$(document).ready(ready);
$(document).on('page:load', ready);

