// work-around turbo links to trigger ready function stuff on every page.

// var files_ready;
// files_ready = function () {
//
//
//
//
//         // alert("files.js javascript working");
// }
// work-around turbo links to trigger ready function stuff on every page.


function remove_file_row(datafile_index) {

    if (window.confirm("Are you sure?")) {

        //console.log("datafile_index: " + datafile_index);
        //console.log($("#dataset_datafiles_attributes_" + datafile_index + "_id").val() );
        //console.log($("#dataset_datafiles_attributes_" + datafile_index + "__destroy").val());

        if ($("#dataset_datafiles_attributes_" + datafile_index + "_id").val() != undefined) {
            $("#dataset_datafiles_attributes_" + datafile_index + "__destroy").val("true");
            //console.log($("#dataset_datafiles_attributes_" + datafile_index + "__destroy").val());
            $("table#datafiles > tbody:last-child").append($("#datafile_index_" + datafile_index));
            $("#datafile_index_" + datafile_index).css("visibility", "hidden");
        }

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

    console.log($('#form_for_deckfile_' + deckfile_id).attr('action'));
    console.log($('#form_for_deckfile_' + deckfile_id).serialize());

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
        }
    });
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

//$(document).ready(files_ready);
//$(document).on('page:load', files_ready);