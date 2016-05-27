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

//$(document).ready(files_ready);
//$(document).on('page:load', files_ready);