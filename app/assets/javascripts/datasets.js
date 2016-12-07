var confirmOnPageExit
confirmOnPageExit = function (e) {
    // If we haven't been passed the event get the window.event
    e = e || window.event;

    var message = 'If you navigate away from this page, unsaved changes may be lost.';

    // For IE6-8 and Firefox prior to version 4
    if (e) {
        e.returnValue = message;
    }

    // For Chrome, Safari, IE8+ and Opera 12+
    return message;
};

// work-around turbo links to trigger ready function stuff on every page.

var ready;
ready = function () {

    $('.bytestream_name').css("visibility", "hidden");
    $('.deposit-agreement-warning').hide();
    $('.deposit-agreement-selection-warning').hide();
    $('#agree-button').prop("disabled", true);

    // handle non-chrome datepicker:
    if (!Modernizr.inputtypes.date) {
        $("#dataset_release_date").prop({type: "text"});
        $("#dataset_release_date").prop({placeholder: "YYYY-MM-DD"});
        $("#dataset_release_date").prop({"data-mask": "9999-99-99"});
        //console.log($("#dataset_release_date").val());

        $("#dataset_release_date").datepicker({
            inline: true,
            showOtherMonths: true,
            minDate: 0,
            maxDate: "+1Y",
            dateFormat: "yy-mm-dd",
            defaultDate: (Date.now())
        });
    }

    $(".upload-consistent").tooltip({
        html: "true",
        title: "<table class='upload-key'><tr class='highlight-background'> <td> <span class='fa upload-guide fa-circle'></span></td> <td> consistent </td><td> Reliable performance for a variety of connection speeds and configurations. </td> </tr> <tr> <td> <span class='fa upload-guide fa-adjust'></span> <td>inconsistent</td> </td> <td> Depends for reliability on connection strength and speed. Works well on campus, but home and coffee-shop environments vary. </td> </tr> <tr> <td> <span class='fa upload-guide fa-circle-o'></span> <td>unavailable</td> </td> <td> Either does not work at all, or is so unreliable as to be inadvisable. </td> </tr> </table> </table>"
    });

    $(".upload-inconsistent").tooltip({
        html: "true",
        title: "<table class='upload-key'><tr> <td> <span class='fa upload-guide fa-circle'></span></td> <td> consistent </td><td> Reliable performance for a variety of connection speeds and configurations. </td> </tr> <tr class='highlight-background'> <td> <span class='fa upload-guide fa-adjust'></span> <td>inconsistent</td> </td> <td> Depends for reliability on connection strength and speed. Works well on campus, but home and coffee-shop environments vary. </td> </tr> <tr> <td> <span class='fa upload-guide fa-circle-o'></span> <td>unavailable</td> </td> <td> Either does not work at all, or is so unreliable as to be inadvisable. </td> </tr> </table> </table>"
    });

    $(".upload-unavailable").tooltip({
        html: "true",
        title: "<table class='upload-key'><tr> <td> <span class='fa upload-guide fa-circle'></span></td> <td> consistent </td><td> Reliable performance for a variety of connection speeds and configurations. </td> </tr> <tr> <td> <span class='fa upload-guide fa-adjust'></span> <td>inconsistent</td> </td> <td> Depends for reliability on connection strength and speed. Works well on campus, but home and coffee-shop environments vary. </td> </tr> <tr class='highlight-background'> <td> <span class='fa upload-guide fa-circle-o'></span> <td>unavailable</td> </td> <td> Either does not work at all, or is so unreliable as to be inadvisable. </td> </tr> </table> </table>"
    });

    $("#checkFileSelectedCount").html('0');

    $("#checkAllFiles").click(function () {
        $(".checkFileGroup").prop('checked', $(this).prop('checked'));
        $("#checkFileSelectedCount").html($('.checkFile:checked').size());
    });

    $('#term-supports').tooltip();

    $('#cancel-button').click(function () {
        // alert("You must agree to the Deposit Agreement before depositing data into Illinois Data Bank.");
        handleNotAgreed();
    });

    $('#dropdown-login').click(function (event) {
        if (event.stopPropagation) {
            event.stopPropagation();
        }
        else if (window.event) {
            window.event.cancelBubble = true;
        }
    });

    $('#new-exit-button').click(function () {
        $('#new_dataset').append("<input type='hidden' name='context' value='exit' />");
        window.onbeforeunload = null;
        $('#new_dataset').submit();
    });

    $('.new-save').hide();

    $('.nav-item').click(function () {

        $('.nav-item').removeClass('current');
        $(this).addClass('current');
    });

    $('#update-save-button').click(function () {

        if ($(".invalid-input").length == 0) {

            if ($(".progress-bar").length == 0) {

                window.onbeforeunload = null;

                $("[id^=edit_dataset]").submit();
            } else {
                alert("UPLOADS IN PROGRESS. Try again once uploads are complete.")
            }

        } else {
            alert("Email address must be in a valid format.");
            $(".invalid-input").first().focus();
        }
    });

    $('#update-confirm').prop('disabled', true);

    $("[id^=edit_dataset] :input").keyup(function () {
        $('#update-confirm').prop('disabled', false);
    });

    $("[id^=edit_dataset] :input").change(function () {
        $('#update-confirm').prop('disabled', false);
    });

    $('#save-exit-button').click(function () {

        if ($(".invalid-input").length == 0) {

            if ($(".progress-bar").length == 0) {

                $("[id^=edit_dataset]").append("<input type='hidden' name='context' value='exit' />");
                window.onbeforeunload = null;
                $("[id^=edit_dataset]").submit();

            } else {
                alert("UPLOADS IN PROGRESS. Try again once uploads are complete.")
            }
        } else {
            alert("Email address must be in a valid format.");
            $(".invalid-input").first().focus();
        }

    });

    $('input.dataset').change(function () {
        if ($(this).val() != "") {
            window.onbeforeunload = confirmOnPageExit;
        }
    });

    //$('.preview').css("visibility", "hidden");

    $('#dataset_title').change(function () {
        if ($("input[name='dataset[publication_state]']").val() == 'draft' || $(this).val() != "") {
            $('#title-preview').html($(this).val() + '.');
            $('#update-save-button').prop('disabled', false);
        } else {
            alert("Published Dataset must have a title.");
            $('#update-save-button').prop('disabled', true);
        }
    });

    $('#dataset_publication_year').change(function () {
        $('#year-preview').html('(' + $(this).val() + '):');
    });

    $('#dataset_identifier').change(function () {
        $('#doi-preview').html("https://doi.org/" + $(this).val());
    });

    $('#show-all-button').click(function () {
        window.location.assign('/datasets');
    });

    $('#show-my-button').click(function () {
        var current_user_email = $('input#current_user_email').val();
        window.location.assign('/datasets?depositor_email=' + current_user_email);
    });

    // console.log("val: " + $('#dataset_embargo').val());

    $("#chunked-upload-btn").click(function () {
        window.location.assign('/datasets/' + dataset_key + '/datafiles/add');
    });

    $("#portable-upload").click(function () {
        window.location.assign('/help?context=pickup&key=' + dataset_key);
    });

    if (!$('#dataset_embargo').val()) {

        $('#release-date-picker').hide();
    }

    $("#dataset_embargo").change(function () {
        $('#update-confirm').prop('disabled', false);
        switch ($(this).val()) {
            case 'file embargo':
                $('#release-date-picker').show();
                break;
            case 'metadata embargo':
                $('#release-date-picker').show();
                break;
            default:
                $('#dataset_release_date').val('');
                $('#release-date-picker').hide();
        }
    });

    $('[data-toggle="tooltip"]').tooltip();

    var clip = new ZeroClipboard($(".copy-btn"));

    $("#login-prompt").modal('show');
    //alert("pre-validity check");
    //alert("dataset key: "+ dataset_key)

    $("#api-modal-btn").click(function () {
        $("#api_modal").modal('show');
    });

    $("#new_datafile").fileupload({

        downloadTemplate: null,
        downloadTemplateId: null,
        uploadTemplate: null,
        uploadTemplateId: null,

        add: function (e, data) {

            $('#collapseFiles').collapse('show');

            var cancelBtn = $('<a/>')
                .attr('href', 'javascript:void(0)')
                .addClass('btn')
                .addClass('btn-danger')
                .addClass('idb')
                .append('<span class="glyphicon glyphicon-remove"/>')
                .append('Cancel Upload')
                .click(function () {
                    data.abort();
                    data.context.remove();
                });


            file = data.files[0];

            var uploadRow = $('<div class="upload"><div class="progress"><div class="bar progress-bar" style="width: 0%;"></div></div></div>');

            num_bytes = file.size || file.fileSize;
            //check filesize and check for duplicate filename
            if (num_bytes < 4194304000) {
                //if (true) {
                if (filename_isdup(file.name)) {
                    alert("Duplicate file error: A file named " + file.name + " detected in this dataset.  For help, please contact the Research Data Service.");
                }
                else {
                    data.context = uploadRow;
                    data.context.prepend('<span class="bytestream_name">' + file.name.toString()) + '</span>';
                    data.context.prepend("  ");
                    data.context.prepend(cancelBtn);
                    $('#datafiles_upload_progress').append(data.context);
                    window.onbeforeunload = confirmOnPageExit;
                    return data.submit();
                }
            } else if (typeof num_bytes === "undefined") {
                alert("No file contents were detected for file named " + file.name + ".  For help, please contact the Research Data Service.");
            }
            else {
                //alert('num_bytes: ' + num_bytes);
                alert("For files larger than 4GB, use an alternative upload method.");
            }
        },
        progress: function (e, data) {
            var progress;
            if (data.context) {
                progress = parseInt(data.loaded / data.total * 100, 10);
                if (progress > 99) {
                    data.context.prepend("processing...");
                }
                return data.context.find('.bar').css('width', progress + '%');
            }
        },

        downloadTemplate: function (o) {

            var maxId = Number($('#datafile_index_max').val());
            var newId = 1;

            if (maxId != NaN) {
                newId = maxId + 1;
            }
            $('#datafile_index_max').val(newId);

            var file = o.files[0];

            //console.log(file);

            var row =
                '<tr id="datafile_index_' + newId + '"><td><div class = "row checkbox">' +
                '<input value="false" type="hidden" name="dataset[datafiles_attributes][' + newId + '][_destroy]" id="dataset_datafiles_attributes_' + newId + '__destroy" />' +
                '<input type="hidden" value="'+ file.webId +'" name="dataset[datafiles_attributes]['+ newId +'][web_id]" id="dataset_datafiles_attributes_'+ newId +'_web_id" />' +
                '<input type="hidden"  value="' + file.datafileId + '" name="dataset[datafiles_attributes][' + newId + '][id]" id="dataset_datafiles_attributes_' + newId + '_id" />' +

                '<span class="col-md-8">' +
                    '<label>' +
                '<input class="checkFile checkFileGroup" name="selected_files[]" type="checkbox" value="' + newId + '" onchange="handleCheckFileGroupChange()">' +
                file.name +
                '</input>' +
                '</label>' +
                '<input class="bytestream_name" value="' + file.name + '" style="visibility: hidden;"/></span><span class="col-md-2">' + file.size + '</span><span class="col-md-2">';
            if (file.error) {
                row = row + '<button type="button" class="btn btn-danger"><span class="glyphicon glyphicon-warning-sign"></span>';
            } else {
                row = row + '<button type="button" class="btn btn-danger btn-sm" onclick="remove_file_row(' + newId + ')"><span class="glyphicon glyphicon-trash"></span></button></span>';
            }

            row = row + '</span></div></td></tr>';
            if (file.error) {
                $("#datafiles > tbody:last-child").append('<tr><td><div class="row"><p>' + file.name + ': ' + file.error + '</p></div></td></tr>');
            } else {
                var old_count = Number($("#datafiles-count").html());
                $("#datafiles-count").html(String(old_count + 1));
                $("#datafiles > tbody:last-child").append(row);
            }
        }
    });

    var boxSelect = new BoxSelect();
    // Register a success callback handler
    boxSelect.success(function (response) {
        console.log(response);

        $.each(response, function (i, boxItem) {

            if (filename_isdup(boxItem.name)) {
                alert("Duplicate file error: A file named " + boxItem.name + " is already in this dataset.  For help, please contact the Research Data Service.");
            }
            else {
                boxItem.dataset_key = dataset_key;
                window.onbeforeunload = confirmOnPageExit;
                $.ajax({
                    type: "POST",
                    url: "/datafiles/create_from_url",
                    data: boxItem,
                    success: function (data) {
                        eval($(data).text());
                    },
                    dataType: 'script'
                });
            }

        });

    });

    // Register a cancel callback handler
    boxSelect.cancel(function () {
        console.log("The user clicked cancel or closed the popup");
    });

    $('#box-upload-in-progress').hide();


    //alert("dataset.js javascript working");

}

var Reflector = function (obj) {
    this.getProperties = function () {
        var properties = [];
        for (var prop in obj) {
            if (typeof obj[prop] != 'function') {
                properties.push(prop);
            }
        }
        return properties;
    };
}

function pad(n) {
    return n < 10 ? '0' + n : n
}

function cancelBoxUpload(datafile, job) {

    $.ajax({
        type: "GET",
        url: '/datasets/' + dataset_key + '/datafiles/' + datafile + '/cancel_box_upload',
        success: function (data) {
            $("#job" + job).remove();
        },
        error: function (data) {
            console.log("error cancelling upload from Box: " + data);
        },
        dataType: 'text'
    });

}

function setDepositor(email, name) {

    $('#depositor_email').val(email);
    $('#depositor_name').val(name);
    $('.save').show();
    $('.new-dataset-progress').show();
    $('.dataset').removeAttr("disabled");
    $('.file-field').removeAttr("disabled");
    $('.add-attachment-subform-button').show();
    $('.deposit-agreement-warning').hide();

    //$('#show-agreement-modal-link').hide();
}

function handleAgreeModal(email, name) {

    if ($('#owner-yes').is(":checked") && $('#agree-yes').is(":checked") && ($('#private-yes').is(":checked") || $('#private-na').is(":checked") )) {
        setDepositor(email, name);
        $('#new_dataset').submit();
    } else {
        // should not get here
        $('#agree-button').prop("disabled", true);
    }
}


function handlePrivateYes() {
    if ($('#private-yes').is(':checked')) {
        $('#dataset_removed_private').val('yes');
        $('#review_link').html('<a href="/review_deposit_agreement?removed=yes" target="_blank">Review Deposit Agreement</a>');
        $('#private-na').attr('checked', false);
        $('#private-no').attr('checked', false);
        if (agree_answers_all_yes()) {
            allow_agree_submit();
        }
        if (agree_answers_none_no()) {
            $('.deposit-agreement-selection-warning').hide();
        }
    } else {
        $('#agree-button').prop("disabled", true);
        $('#dataset_removed_private').val('no');
    }
}

function handlePrivateNA() {

    if ($('#private-na').is(':checked')) {
        $('#review_link').html('<a href="/review_deposit_agreement?removed=na" target="_blank">Review Deposit Agreement</a>');
        $('#dataset_removed_private').val('na');
        $('#private-yes').attr('checked', false);
        $('#private-no').attr('checked', false);
        if (agree_answers_all_yes()) {
            allow_agree_submit();
        }
        if (agree_answers_none_no()) {
            $('.deposit-agreement-selection-warning').hide();
        }
    } else {
        $('#agree-button').prop("disabled", true);
        $('#dataset_removed_private').val('no');
    }
}

function handlePrivateNo() {
    if ($('#private-no').is(':checked')) {
        $('#dataset_removed_private').val('no');
        $('#private-na').attr('checked', false);
        $('#private-yes').attr('checked', false);
        $('#agree-button').prop("disabled", true);
        $('.deposit-agreement-selection-warning').show();
    } else {
        if (agree_answers_none_no()) {
            $('.deposit-agreement-selection-warning').hide();
        }
    }
}

function handleOwnerYes() {
    if ($('#owner-yes').is(':checked')) {
        $('#dataset_have_permission').val('yes');
        $('#owner-no').attr('checked', false);
        if (agree_answers_all_yes()) {
            allow_agree_submit();
        }
        if (agree_answers_none_no()) {
            $('.deposit-agreement-selection-warning').hide();
        }
    } else {
        $('#agree-button').prop("disabled", true);
        $('#dataset_have_permission').val('no');
    }
}

function handleOwnerNo() {
    if ($('#owner-no').is(':checked')) {
        $('#dataset_have_permission').val('no');
        $('#owner-yes').attr('checked', false);
        $('#agree-button').prop("disabled", true);
        $('.deposit-agreement-selection-warning').show();
    } else {
        if (agree_answers_none_no()) {
            $('.deposit-agreement-selection-warning').hide();
        }
    }
}

function handleAgreeYes() {
    if ($('#agree-yes').is(':checked')) {
        $('#agree-no').attr('checked', false);
        $('#dataset_agree').val('yes');
        if (agree_answers_all_yes()) {
            allow_agree_submit();
        }
        if (agree_answers_none_no()) {
            $('.deposit-agreement-selection-warning').hide();
        }

    } else {
        $('#agree-button').prop("disabled", true);
        $('#dataset_agree').val('no');
    }
}

function handleAgreeNo() {
    if ($('#agree-no').is(':checked')) {
        $('#dataset_agree').val('no');
        $('#agree-yes').attr('checked', false);
        $('#agree-button').prop("disabled", true);
        $('.deposit-agreement-selection-warning').show();
    } else {
        if (agree_answers_none_no()) {
            $('.deposit-agreement-selection-warning').hide();
        }
    }
}

function agree_answers_all_yes() {
    return (($('#owner-yes').is(':checked')) && ( ($('#private-yes').is(':checked')) || ($('#private-na').is(':checked')) ) && ($('#agree-yes').is(':checked')))
}

function agree_answers_none_no() {
    return !(($('#owner-no').is(':checked')) || ($('#private-no').is(':checked')) || ($('#agree-no').is(':checked')))
}

function allow_agree_submit() {
    $('#agree-button').prop("disabled", false);
    $('.deposit-agreement-selection-warning').hide();
}

function clear_help_form() {
    $('input .help').val('');
}

function validateReleaseDate() {
    var yearFromNow = new Date(new Date().setFullYear(new Date().getFullYear() + 1));
    var releaseDate = new Date($('#dataset_release_date').val());

    if (releaseDate > yearFromNow) {
        alert('The maximum amount of time that data can be delayed for publication is is 1 year.');
        $('#dataset_release_date').val(yearFromNow.getFullYear() + '-' + pad((yearFromNow.getMonth() + 1)) + '-' + pad(yearFromNow.getDate()));
    }
}

function filename_isdup(proposed_name) {
    var returnVal = false;

    $.each($('.bytestream_name'), function (index, value) {

        if (proposed_name == $(value).val()) {
            returnVal = true;
        }
        if ($(value).text().indexOf(proposed_name) >= 0) {
            returnVal = true;
        }
    });


    return returnVal;
}

function offerDownloadLink() {
    var selected_files = $('input[name="selected_files[]"]:checked');
    var web_id_string = "";
    var zip64_threshold = 4000000000;

    $.each(selected_files, function (index, value) {
        if (web_id_string != "") {
            web_id_string = web_id_string + "~";
        }
        web_id_string = web_id_string + $(value).val();
    });
    if (web_id_string != "") {
        console.log(web_id_string)
        $.ajax({
            url: "/datasets/" + dataset_key + "/download_link?",
            data: {"web_ids": web_id_string},
            dataType: 'json',
            success: function (result) {
                if (result.status == 'ok') {
                    $('.download-link').html("<h2><a href='" + result.url + "' target='_blank'>Download</a></h2>");
                    if (Number(result.total_size) > zip64_threshold) {
                        $('.download-help').html("<p>For selections of files larger than 4GB, the zip file will be in zip64 format. To open a zip64 formatted file on OS X (Mac) requires additional software not build into the operating system since version 10.11. Options include 7zX and The Unarchiver. If a Windows system has trouble opening the zip file, 7-Zip can be used.</p>")
                    }

                    $('#downloadLinkModal').modal('show');
                } else {
                    console.log(result);
                    $('.download-link').html("An unexpected error occurred.<br/>Details have been logged for review.<br/><a href='/help' target='_blank'>Contact the Research Data Service Team</a> with any questions.");
                    $('#downloadLinkModal').modal('show');
                }


            }
            //context: document.body
        }).done(function () {
            console.log("done");

        });
    }
}

function openRemoteFileModal() {
    $("#remote-file-modal").modal();
}

function license_change_warning() {
    $("#licenseChangeModal").modal();
}

function suppressChangelog() {
    if (window.confirm("Are you sure?")) {
        $('#suppression_action').val("suppress_changelog");
        $('#suppression_form').submit();
    }
}

function unsuppressChangelog() {
    if (window.confirm("Are you sure?")) {
        $('#suppression_action').val("unsuppress_changelog");
        $('#suppression_form').submit();
    }
}

function tmpSuppressFiles() {

    if (window.confirm("Are you sure?")) {
        $('#suppression_action').val("temporarily_suppress_files");
        $('#suppression_form').submit();
    }
}

function tmpSuppressMetadata() {
    if (window.confirm("Are you sure?")) {
        $('#suppression_action').val("temporarily_suppress_metadata");
        $('#suppression_form').submit();
    }
}

function unsuppress() {
    if (window.confirm("Are you sure?")) {
        $('#suppression_action').val("unsuppress");
        $('#suppression_form').submit();
    }
}

function permSuppressFiles() {
    if (window.confirm("Are you sure?")) {
        $('#suppression_action').val("permanently_suppress_files");
        $('#suppression_form').submit();
    }
}

function permSuppressMetadata() {
    if (window.confirm("Are you sure?")) {
        $('#suppression_action').val("permanently_suppress_metadata");
        $('#suppression_form').submit();
    }
}

function update_and_publish() {
    $("[id^=edit_dataset]").append("<input type='hidden' name='context' value='publish' />");
    window.onbeforeunload = null;
    $("[id^=edit_dataset]").submit();
}

function confirm_update() {

    // console.log ("inside confirm_update");
    // Use Ajax to submit form data

    // console.log($("[id^=edit_dataset]").serialize());

    // using patch because that method designation is in the form already
    if ($(".invalid-input").length == 0) {

        // console.log("inside valid input ok");

        $('#validation-warning').empty();
        $.ajax({
            url: '/datasets/' + dataset_key + '/validate_change2published',
            type: 'patch',
            data: $("[id^=edit_dataset]").serialize(),
            datatype: 'json',
            success: function (data) {
                //console.log(data);

                if (data.message == "ok") {
                    reset_confirm_msg();
                    $('#deposit').modal('show');
                } else {
                    $('#validation-warning').html('<div class="alert alert-alert">' + data.message + '</div>');
                    $('#update-confirm').prop('disabled', true);
                }

            }
        });
    } else {
        alert("Email address must be in a valid format.");
        $(".invalid-input").first().focus();
    }
}

/*function confirm_update(){
 if ($(".invalid-input").length == 0) {
 reset_confirm_msg();
 $('#deposit').modal('show');
 } else {
 alert("Email address must be in a valid format.");
 $(".invalid-input").first().focus();
 }
 }*/

function show_release_date() {
    $('#release-date-picker').show();
}

function reset_confirm_msg() {

    //console.log("inside reset confirm msg");

    if ($('.publish-msg').html() != undefined && $('.publish-msg').html().length > 0) {
        var new_embargo = $('#dataset_embargo').val();
        var release_date = $('#dataset_release_date').val();

        //console.log(new_embargo);

        $.getJSON("/datasets/" + dataset_key + "/confirmation_message?new_embargo_state=" + new_embargo + "&release_date=" + release_date, function (data) {
            //console.log(data);
            $('.publish-msg').html('<p class="ds-paragraph">' + data.message + '</p>');
        })
            .fail(function (xhr, textStatus, errorThrown) {
                console.log("error" + textStatus);
                console.log(xhr.responseText);
            });
    } else {
        console.log("publish-msg element not found");
    }

}

function clear_alert_message() {

    $('#read-only-alert-text').val("");
    //$('.edit_admin').submit();
}

function getToken() {
    $.getJSON("/datasets/" + dataset_key + "/get_new_token", function (data) {
        //console.log(data);
        $('.current-token').html("<p><strong>Current Token:</strong> " + data.token + "<br/><strong>Expires:</strong> " + (new Date(data.expires)).toISOString() + "</p>");
        $('.token-btn').html("Get New Token");

        if(window.location.href.indexOf("dev") > -1) {
            $('#command-to-copy').html("Example command template:<br/><div class='indent'>python illinois_data_bank_datafile.py "+ dataset_key +" "+ data.token +" myfile.csv development</div>")
        }else {
            $('#command-to-copy').html("Example command template:<br/><div class='indent'>python illinois_data_bank_datafile.py "+ dataset_key +" "+ data.token +" myfile.csv</div>")
        }
    });
}

function cancelUpload() {

    if (!event) {
        event = window.event; // Older versions of IE use
                              // a global reference
                              // and not an argument.
    }
    ;

    var el = (event.target || event.srcElement); // DOM uses 'target';
    // older versions of
    // IE use 'srcElement'
    $(el).parent().remove();
}

function deleteSelected() {
    
    if (window.confirm("Are you sure?")) {

        console.log($('#checkFileSelectedCount').html());
        $('#checkFileSelectedCount').html('0');
        $('#checkAllFiles').prop('checked', false);

        $.each($("input[name='selected_files[]']:checked"), function () {
            remove_file_row_pre_confirm($(this).val());
        });
    }
}

function handleCheckFileGroupChange(){
    $("#checkFileSelectedCount").html($('.checkFile:checked').size());
    $('#checkAllFiles').prop('checked', false);
}

$(document).ready(ready);
$(document).on('page:load', ready);

