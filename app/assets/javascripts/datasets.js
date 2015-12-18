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

    $(".orcid-search-btn").click(function(){
        //alert("orcid-search-btn clicked");
        var creator_index = $(this).data('id');
        $("#creator-index").val(creator_index);
        var creatorFamilyName =  $("#dataset_creators_attributes_" + creator_index + "_family_name").val();
        var creatorGivenName = $("#dataset_creators_attributes_" + creator_index + "_given_name").val();
        $("#creator-family").val(creatorFamilyName);
        $("#creator-given").val(creatorGivenName);
        $('#orcid_search').modal('show');
    });

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

function handle_contact_change(){
    // set is_contact value to match selection staus and highlight required email input field if blank

    var selectedVal = $("input[type='radio'][name='primary_contact']:checked").val();
    $("input[name='dataset[creators_attributes][" + selectedVal + "][is_contact]']").val('true');

    $('#creator_table tr').each(function (i) {

        if (i > 0) {
            var creator_index = $(this).find('td').first().next().find('input').first().attr('id').split('_')[3];

            if (selectedVal != creator_index) {
                $("#dataset_creators_attributes_" + creator_index + "_email").parent().removeClass('input-field-required');
                $("input[name='dataset[creators_attributes][" + creator_index + "][is_contact]']").val('false');
            }
        }
    });

    if ($("input[name='dataset[creators_attributes][" + selectedVal + "][email]']").val() == ""){
        $("#email_required_span").addClass('highlight');
        $("input[name='dataset[creators_attributes][" + selectedVal + "][email]']").parent().addClass('input-field-required');
        $("input[name='dataset[creators_attributes][" + selectedVal + "][email]']").focus();
    }
}

function add_creator_row(){


    var listStr = $('#creator_index_list').val();
    var listArr = listStr.split(",").map(Number);

    var maxId = Math.max(...listArr);
    var newId = maxId + 1;

    var creator_row = '<tr class="item row" id="creator_index_' + newId + '">' +
        '<td class="col-md-1"></td>' +

        '<td class="col-md-2">' +
        '<input type="hidden" value="' + $('#creator_table tr').length + '" name="dataset[creators_attributes][' + newId + '][row_position]" id="dataset_creators_attributes_' + newId + '_row_position" />' +
        '<input value="0" type="hidden" name="dataset[creators_attributes][' + newId + '][type_of]" id="dataset_creators_attributes_' + newId + '_type_of" />' +
        '<input onchange="generate_creator_preview()" class="form-control dataset creator family-name" placeholder="[Family Name, e.g.: Smith]" type="text" name="dataset[creators_attributes][' + newId + '][family_name]" id="dataset_creators_attributes_' + newId + '_family_name" /><strong>,</strong>' +
        '</td>' +

        '<td class="col-md-2">' +
       '<input onchange="generate_creator_preview()" class="form-control dataset creator" placeholder="[Given Name, e.g.: John W., Jr. ]" type="text" name="dataset[creators_attributes][' + newId + '][given_name]" id="dataset_creators_attributes_' + newId + '_given_name" />' +
        '</td>' +

        '<td class="col-md-2">' +
        '<input value="ORCID" type="hidden" name="dataset[creators_attributes][' + newId + '][identifier_scheme]" id="dataset_creators_attributes_' + newId + '_identifier_scheme" />' +
         '<input class="form-control dataset" placeholder="[xxxx-xxxx-xxxx-xxxx]" type="text" name="dataset[creators_attributes][' + newId + '][identifier]" id="dataset_creators_attributes_' + newId + '_identifier" />' +
        '</td>'+

        '<td class="col-md-1">' +
        '<a class="btn btn-primary btn-sm orcid-search-btn" data-id="' + newId + '" data-toggle="modal"><span class="glyphicon glyphicon-search"></span>&nbsp;Look Up</a>' +
        '</td>' +
        '<td class="col-md-2">' +
        '<input onchange="handle_creator_email_change(this)" class="form-control dataset creator-email" placeholder="[Email, e.g.: jws@example.edu]" type="email" name="dataset[creators_attributes][' + newId + '][email]" id="dataset_creators_attributes_' + newId + '_email" />' +
        '</td>' +
        '<td class="col-md-1" align="center"><input name="dataset[creators_attributes][' +  newId + '][is_contact]" type="hidden" value="false"><input class="dataset contact_radio" name="primary_contact" onchange="handle_contact_change()" type="radio" value="false"></td>' +
        '<td class="col-md-1"></td>' +
        '</tr>';
    $("#creator_table tbody:last-child").append(creator_row);

    var newList = listStr + "," + newId;
    $('#creator_index_list').val(newList);

    handleCreatorTable();

}

function remove_creator_row(creator_index) {


    if($("#dataset_creators_attributes_" + creator_index + "_id").val() != undefined) {
        $("#dataset_creators_attributes_" + creator_index + "__destroy").val("true");
    }

    $("#deleted_creator_table > tbody:last-child").append($("#creator_index_" + creator_index));

    $("#creator_index_" + creator_index).hide();
    $('#creator_table').sortable('refresh');

    if ($("#creator_table tr").length < 2){
        add_creator_row();
    }
    handleCreatorTable();
    generate_creator_preview();


}

function initialize_creator_index_list(){

    // when the table is first formed, the creator.index is in the range 0..(number of table rows minus one because of header row)

    var listStr = "";

    for (i = 0; i < ($('#creator_table tr').length) - 1 ; i++) {
        if (i > 0) {
            listStr += ",";
        }
        listStr += i ;
    }

    // set creator form id list value
    $('#creator_index_list').val(listStr);
}

function handleCreatorTable(){

    $('#creator_table tr').each(function (i) {

        // for all but header row, set the row_position value of the input to match the table row position
        if (i > 0) {

            var split_id = (this.id).split('_');
            var creator_index = split_id[2];

            $("#dataset_creators_attributes_" + creator_index + "_row_position").val(i);

            // set creator row num display
            $("td:first", this).html("<span style='display:inline;'>  " + i + "     </span><span style='display:inline;' class='glyphicon glyphicon-resize-vertical'></span>" );

            //console.log("i: " + i);
            //console.log("hidden_row_count: " + hidden_row_count);
            //console.log("table row count: " + $("#creator_table tr").length );

            if ((i + 1 ) == ($("#creator_table tr").length)){
                $("td:last-child", this).html("<button class='btn btn-danger btn-sm' onclick='remove_creator_row(\x22" + creator_index  +  "\x22 )' type='button'><span class='glyphicon glyphicon-trash'></span></button>&nbsp;&nbsp;<button class='btn btn-success btn-sm' onclick='add_creator_row()' type='button'><span class='glyphicon glyphicon-plus'></span></button>");
            } else
            {
                $("td:last-child", this).html("<button class='btn btn-danger btn-sm' onclick='remove_creator_row(\x22" + creator_index  +  "\x22 )' type='button'><span class='glyphicon glyphicon-trash'></span></button>");
            }
        }
    });
}

function handle_creator_email_change(input){

    if ($(input).val() != "") {
        $(input).parent().removeClass('input-field-required');
        $("#email_required_span").removeClass('highlight');
    }
}

function generate_creator_preview(){

    //console.log("inside generate creator 1");

    var creator_list_preview = "";

    $('#creator_table tr').each(function (i) {

        var split_id = (this.id).split('_');
        var creator_index = split_id[2];

        //console.log("inside tr each for creator index " + creator_index);

        //console.log($("#dataset_creators_attributes_" + creator_index + "__destroy").val());
;
        if ((i > 0) && (($("#dataset_creators_attributes_" + creator_index + "_family_name").val() != "") || ($("#dataset_creators_attributes_" + creator_index + "_given_name").val() != "") )){

            //console.log("inside generate creator 2");
            //console.log($("#dataset_creators_attributes_" + creator_index + "_family_name").val());
           
            if (creator_list_preview.length > 0) {

                creator_list_preview = creator_list_preview + "; ";
            }

            creator_list_preview = creator_list_preview + $("#dataset_creators_attributes_" + creator_index + "_family_name").val();
            creator_list_preview = creator_list_preview + ", "
            creator_list_preview = creator_list_preview + $("#dataset_creators_attributes_" + creator_index + "_given_name").val();
        }

    });

    $('#creator-preview').html(creator_list_preview);

}

function set_orcid_from_search_modal(){
    var creator_index = $("#creator-index").val();
    var selected_id = $("#selected-id").val();

    $("#dataset_creators_attributes_" + creator_index  + "_identifier").val(selected_id);
}



function search_orcid(){
    var search_url = 'http://pub.orcid.org/';
    var bio_segment = 'v1.2/search/orcid-bio?q='
    var search_query = 'family-name:' + $("#creator-family").val() + '+AND+given-names:' + $("#creator-given").val();

    var search_string = search_url + bio_segment + search_query + '&start=0&rows=5&wt=json';

    console.log(search_string);

    $.ajax({
        url: search_string,
        dataType: 'jsonp',
        success: function(data){
            var people = data["orcid-search-results"]["orcid-search-result"];
            people_minified = [];
            found_number = people.length;
            for (var person in people){
                console.log(person);
                var given_name = person['orcid-profile']['orcid-bio']['personal-details']['given-names']['value'];
                var family_name = person['orcid-profile']['orcid-bio']['personal-details']['family-name']['value'];
                var orcid = person['orcid-profile']['orcid-identifier']['path'];

                people_minified.push(given_name + ' ' + family_name + ', ' + orcid);

                if(people_minified.length >= found_number){

                    $.each(people_minified, function( index, value ) {
                        $(".response").append("<div class='row'>" + family_name + ", " + given_name + ": " + orcid + "</div>");
                    });

                    clearInterval(timeout);
                }


            };
            timeout = setInterval(function(){response(people_minified)}, 100);
        },
        error: function(xhr){
            console.error(xhr);
        }
    });

}


$(document).ready(ready);
$(document).on('page:load', ready);

