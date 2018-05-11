// work-around turbo links to trigger ready function stuff on every page.

var files_ready;
files_ready = function () {
    $('.view-load-spinner').hide();

    //alert("files.js javascript working");
}
//work-around turbo links to trigger ready function stuff on every page.


function remove_file_row_pre_confirm(datafile_index){

    if ($("#dataset_datafiles_attributes_" + datafile_index + "_web_id").val() == undefined) {
        console.log("web_id undefined");
    }
    else {

        var old_count = Number($("#datafiles-count").html())
        $("#datafiles-count").html(String(old_count - 1));

        web_id = $("#dataset_datafiles_attributes_" + datafile_index + "_web_id").val();

        $.ajax({
            url: '/datafiles/' + web_id + '.json',
            type: 'DELETE',
            datatype: "json",
            success: function(result) {
                $("#datafile_index_" + datafile_index).remove();
                $("#dataset_datafiles_attributes_" + datafile_index + "_id").remove();
            },
            error: function(xhr, status, error){
                var err = eval("(" + xhr.responseText + ")");
                alert(err.Message);
            }
        });
    }
}

function remove_file_row(datafile_index) {

    if (window.confirm("Are you sure?")) {

        remove_file_row_pre_confirm(datafile_index);

    }

}

function remove_filejob_row(job_id, datafile_id){

    if (window.confirm("Are you sure?")) {

        var maxId = Number($('#datafile_index_max').val());
        var newId = 1;

        if (maxId != NaN) {
            newId = maxId + 1;
        }

        $('#datafile_index_max').val(newId);

        var row = '<tr id= "datafile_index_' + newId + '"><td>' +
            '<input value="true" type="hidden" name="dataset[datafiles_attributes]['+ newId + '][_destroy]" id="dataset_datafiles_attributes_' + newId + '__destroy "/>' +
            '<input value="'+ datafile_id +'" type="hidden" name="dataset[datafiles_attributes]['+ newId + '][_id]" id="dataset_datafiles_attributes_' + newId + '_id "/>' +
            '</td></tr>'

        $("table#datafiles > tbody:last-child").append(row);

        $("#job"+job.id).hide;
    }

}

function download_selected() {
    var file_ids = $("input[name='selected_files[]']:checked").map(function (index, domElement) {
        return $(domElement).val();
    });

    $.each(file_ids, function (i, file_id) {
        fileURL = "<iframe class='hidden' src='/datasets/" + dataset_key + "/stream_file/" + file_id + "'></iframe>";
        $('#frames').append(fileURL);
    });
}

function approve_deckfile(deckfile_id){

    $('#loadingModal').modal('show');

    // Use Ajax to submit form data
    $.ajax({
        url: $('#form_for_deckfile_' + deckfile_id).attr('action'),
        type: 'POST',
        data: $('#form_for_deckfile_' + deckfile_id).serialize(),
        datatype: 'json',
        success: function(data) {

            console.log(data);

            var maxId = Number($('#datafile_index_max').val());
            var newId = 1;

            if (maxId != NaN) {
                newId = maxId + 1;
            }
            $('#datafile_index_max').val(newId);

            var file = data.files[0];

            //console.log(file);

            var row =
                '<tr id="datafile_index_' + newId + '"><td><div class = "row">' +

                '<input value="false" type="hidden" name="dataset[datafiles_attributes][' + newId + '][_destroy]" id="dataset_datafiles_attributes_' + newId + '__destroy" />' +
                '<input type="hidden"  value="'+ file.datafileId + '" name="dataset[datafiles_attributes][' + newId + '][id]" id="dataset_datafiles_attributes_' + newId + '_id" />'+

                '<span class="col-md-8">' + file.name + '<input class="bytestream_name" value="' + file.name + '" style="visibility: hidden;"/></span><span class="col-md-2">' + file.size + '</span><span class="col-md-2">';
            if (file.error) {
                row = row + '<button type="button" class="btn btn-danger"><span class="glyphicon glyphicon-warning-sign"></span>';
            } else {
                row = row + '<button type="button" class="btn btn-danger btn-sm" onclick="remove_file_row(' + newId + ')"><span class="glyphicon glyphicon-trash"></span></button></span>';
            }

            row = row + '</span></div></td></tr>';
            if (file.error) {
                $("#datafiles > tbody:last-child").append('<tr><td><div class="row"><p>' + file.name + ': ' + file.error + '</p></div></td></tr>');
            } else {
                $("#datafiles > tbody:last-child").append(row);
            }

            $("#deckfile_" + deckfile_id).remove();

            if ($('#deckfiles_table tr').length < 1  ){
                $('.deckfiles_div').remove();
            }
            $('#loadingModal').modal('hide');
        }
    });
}

function create_from_remote_unknown_size(){
    $('#loadingModal').modal('show');

    console.log("inside create_from_remote_unknown_size()")

    // Use Ajax to submit form data

    $.ajax({
        url: $('#form_for_remote').attr('action'),
        type: 'POST',
        data: $('#form_for_remote').serialize(),
        datatype: 'json',
        success: function (data) {

            console.log(data);

            var maxId = Number($('#datafile_index_max').val());
            var newId = 1;

            if (maxId != NaN) {
                newId = maxId + 1;
            }
            $('#datafile_index_max').val(newId);

            var file = data.files[0];

            var row =
                '<tr id="datafile_index_' + newId + '"><td><div class = "row">' +

                '<input value="false" type="hidden" name="dataset[datafiles_attributes][' + newId + '][_destroy]" id="dataset_datafiles_attributes_' + newId + '__destroy" />' +
                '<input type="hidden"  value="' + file.datafileId + '" name="dataset[datafiles_attributes][' + newId + '][id]" id="dataset_datafiles_attributes_' + newId + '_id" />' +

                '<span class="col-md-8">' + file.name + '<input class="bytestream_name" value="' + file.name + '" style="visibility: hidden;"/></span><span class="col-md-2">' + file.size + '</span><span class="col-md-2">';
            if (file.error) {
                row = row + '<button type="button" class="btn btn-danger"><span class="glyphicon glyphicon-warning-sign"></span>';
            } else {
                row = row + '<button type="button" class="btn btn-danger btn-sm" onclick="remove_file_row(' + newId + ')"><span class="glyphicon glyphicon-trash"></span></button></span>';
            }

            row = row + '</span></div></td></tr>';
            if (file.error) {
                $("#datafiles > tbody:last-child").append('<tr><td><div class="row"><p>' + file.name + ': ' + file.error + '</p></div></td></tr>');
            } else {
                $("#datafiles > tbody:last-child").append(row);
            }

            $('#loadingModal').modal('hide');
        },
        error: function (data) {
            console.log(data);
            alert("There was a problem ingesting the remote file");
            $('#loadingModal').modal('hide');
        }
    });
}

function create_from_remote(){

    //console.log("inside create from remote");

    if (filename_isdup($('#remote_filename').val())) {
        alert("Duplicate filename error: A file named " + $('#remote_filename').val() + " is already in this dataset.  For help, please contact the Research Data Service.");
    }
    else {

        $.ajax({
            url: "/datafiles/remote_content_length",
            type: 'POST',
            data: $('#form_for_remote').serialize(),
            datatype: 'json',
            success: function (data) {
                //console.log("inside success");
                //console.log(data);
                //console.log(data.status);
                if(data.status == "ok" ) {
                    var content_length = data.remote_content_length;

                    if (content_length > 100000000000){
                        alert("For files larger than 100 GB, please contact the Research Data Service.");
                        //
                        // *** temporarily, at least, don't try to use progress bar
                        // } else if (content_length > 0) {
                        //     item = {
                        //         "name": $('#remote_filename').val(),
                        //         "size": content_length,
                        //         "url": $('#remote_url').val(),
                        //         "dataset_key": dataset_key
                        //     };
                        //
                        //     $.ajax({
                        //         type: "POST",
                        //         url: "/datafiles/create_from_url",
                        //         data: item,
                        //         success: function (data) {
                        //             eval($(data).text());
                        //         },
                        //         error: function (data) {
                        //             console.log(data);
                        //         },
                        //         dataType: 'script'
                        //     });
                    } else {
                        // getting here means not known to be too big
                        //console.log("content length not larger than 0");
                        create_from_remote_unknown_size();
                    }
                }
                else{
                    create_from_remote_unknown_size();
                }

            },
            error: function (data) {
                console.log("content-length unavailable");
                create_from_remote_unknown_size();

            }
        });

    }
}

function preview(web_id){
    console.log("inside preview")
    $("#preview_" + web_id).show();
    $("#preview_glyph_" + web_id).removeClass("glyphicon-eye-open");
    $("#preview_glyph_" + web_id).addClass("glyphicon-eye-close");
    $("#preview_btn_" + web_id).attr('onclick', "hide_preview('" + web_id  + "')");
}

function hide_preview(web_id){
    $("#preview_glyph_" + web_id).removeClass("glyphicon-eye-close");
    $("#preview_glyph_" + web_id).addClass("glyphicon-eye-open");
    $("#preview_btn_" + web_id).attr('onclick', "preview('" + web_id  + "')");
    $("#preview_" + web_id).hide();
}

function preview_image(iiif_root, web_id){

    $("#preview_" + web_id).show();
    if ($("#preview_" + web_id).is(':empty')){
        $('.spinner_'+web_id).show();
        $("#preview_" + web_id).html("<img src='" + iiif_root + "/" + web_id + "/full/full/0/default.jpg" + "' class='preview_body'>");
        $('.spinner_'+web_id).hide();
    }
    $("#preview_img_btn_" + web_id).html('<button type="button" class="btn btn-sm btn-success" onclick="hide_image_preview(&#39;' + iiif_root + '&#39;, &#39;' + web_id + '&#39;)"><span class="glyphicon glyphicon-eye-close"></span> View</button>');
}

function hide_image_preview(iiif_root, web_id){
    $("#preview_img_btn_" + web_id).html('<button type="button" class="btn btn-sm btn-success" onclick="preview_image(&#39;' + iiif_root + '&#39;, &#39;' + web_id + '&#39;)"><span class="glyphicon glyphicon-eye-open"></span> View</button>');
    $("#preview_" + web_id).hide();
}

function remove_deckfile(deckfile_id, deckfile_index){
    $('#dataset_deckfiles_attributes_'+ deckfile_index +'_remove').val("true");
    $('#deckfile_'+ deckfile_id).remove();
}

function restore_deckfile(deckfile_id, deckfile_index){
    $('#dataset_deckfiles_attributes_'+ deckfile_index +'_remove').val("false");
    $('.deckfile_restore_btn').hide();
    $('.deckfile_remove_btn').show();
}

$(document).ready(files_ready);
$(document).on('page:load', files_ready);
