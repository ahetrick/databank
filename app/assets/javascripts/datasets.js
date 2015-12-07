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

    $('#update-save-button').click(function () {
        window.onbeforeunload = null;
        $("[id^=edit_dataset]").submit();

    });

    //$('#test-id').click(function () {
    //    $('#box-upload-in-progress').show();
    //    window.location.assign('/datasets/' + dataset_key + '/download_box_file/42384177089');
    //});

    $('input.dataset').change(function() {
        if( $(this).val() != "" )
            window.onbeforeunload = confirmOnPageExit;
     });

    $('#dataset_title').change(function() {
        $('#title-preview').html($(this).val() + '.');
    });

    //TODO creator preview


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
                row = row + '<a data-confirm="Are you sure?" class="btn btn-danger btn-sm" rel="nofollow" data-method="delete" href="/datafiles/' + file.web_id + '"><span class="glyphicon glyphicon-trash"></span> File</a></span>';
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
        setCreatorRowNums();
        placeAddCreatorButton();
        set_creator_form_id_list();
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
                console.log(item_id);
                position = ui.item.index();
                console.log("position: " + position)
                setCreatorRowNums();
                placeAddCreatorButton();
                return $.ajax({
                    type: 'POST',
                    url: '/creators/update_row_order',
                    dataType: 'json',
                    data: {
                        creator: {
                            creator_id: item_id,
                            row_order_position: position
                        }
                    }
                });
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

function setCreatorRowNums(){
    $('#creator_table tr').each(function (i) {
        $("td:first", this).html("Creator #" + i);
    });
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
    $('#show-agreement-modal-link').show();
    $('#new-save-button').hide();
    $('.deposit-agreement-warning').show();
    $('.search').removeAttr("disabled");
    $('.deposit-agreement-btn').removeAttr("disabled");
    window.scrollTo(0,0);
}

function setDepositor(email, name){

    $('#depositor_email').val(email);
    $('#depositor_name').val(name);
    $('.save').show();
    $('#new-save-button').show();
    $('.dataset').removeAttr("disabled");
    $('.file-field').removeAttr("disabled");
    $('.add-attachment-subform-button').show();
    $('.deposit-agreement-warning').hide();
    //$('#show-agreement-modal-link').hide();
}

function handleAgreeModal(email, name){

    if ($('#owner-yes').is(":checked") && $('#agree-yes').is(":checked") && ($('#public-yes').is(":checked") ||$('#public-na').is(":checked") ) )  {
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

function add_creator_row(){

    var listStr = $('#creator_form_id_list').val();
    var listArr = listStr.split(",").map(Number);

    var maxId = Math.max(...listArr);
    var newId = maxId + 1;
    var creator_row = "<tr class='item' data-item-id='25'>" +
        "<td></td>" +
        "<td><input value='0' type='hidden' name='dataset[creators_attributes][" + newId + "][type_of]' id='dataset_creators_attributes_" + newId + "_type_of' />" +
        "<input class='form-control dataset creator' type='text' name='dataset[creators_attributes][" + newId + "][family_name]' id='dataset_creators_attributes_" + newId + "_family_name' /></td>" +
        "<td><input class='form-control dataset creator' type='text' name='dataset[creators_attributes][" + newId + "][given_name]' id='dataset_creators_attributes_" + newId + "_given_name' /></td>" +
        "<td><input name='dataset[creators_attributes][" + newId + "][is_contact]' type='hidden' value='0' />" +
        "<input class='form-control dataset' type='checkbox' value='1' name='dataset[creators_attributes][" + newId + "][is_contact]' id='dataset_creators_attributes_" + newId + "_is_contact' /></td>" +
        "<td><input class='form-control dataset' type='text' name='dataset[creators_attributes][" + newId + "][email]' id='dataset_creators_attributes_" + newId + "_email' /></td>" +
        "<td></td></tr>";
    $("#creator_table tbody:last-child").append(creator_row);
    setCreatorRowNums();
    placeAddCreatorButton();
    var newList = listStr + "," + newId;
    $('#creator_form_id_list').val(newList);


}

function placeAddCreatorButton(){


    $('#creator_table tr').each(function (i) {
        if ((i + 1) == ($("#creator_table tr").length)){
            $("td:last-child", this).html("<button class='btn btn-success btn-sm' onclick='add_creator_row()' type='button'><span class='glyphicon glyphicon-plus'></span></button>");
        } else
        {
            $("td:last-child", this).empty();
        }

    });
}

function set_creator_form_id_list(){

    var listStr = "";

    for (i = 0; i < $("#creator_table tr").length; i++) {

        if (i > 0) {
            listStr += ",";
        }

        listStr += i;
    }

    $('#creator_form_id_list').val(listStr);
}


$(document).ready(ready);
$(document).on('page:load', ready);

