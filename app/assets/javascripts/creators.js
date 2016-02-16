// work-around turbo links to trigger ready function stuff on every page.

var creators_ready;
creators_ready = function() {

    var cells, desired_width, table_width;
    if ($("#creator_table tr").length > 0) {
        table_width = $('#creator_table').width();
        cells = $('#creator_table').find('tr')[0].cells.length;
        desired_width = table_width / cells + 'px';
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

    $('.orcid-search-spinner').hide();
    //alert("creators.js javascript working");
}

function add_creator_row(){

    var maxId = Number($('#creator_index_max').val());
    var newId = 0;

    if (maxId != NaN) {
        newId = maxId + 1;
    }
    $('#creator_index_max').val(newId);

    var creator_row = '<tr class="item row" id="creator_index_' + newId + '">' +
        '<td><span style="display:inline;" class="glyphicon glyphicon-resize-vertical"></span></td>' +
        '<td class="col-md-2">' +
        '<input type="hidden" value="' + $('#creator_table tr').length + '" name="dataset[creators_attributes][' + newId + '][row_position]" id="dataset_creators_attributes_' + newId + '_row_position" />' +
        '<input value="0" type="hidden" name="dataset[creators_attributes][' + newId + '][type_of]" id="dataset_creators_attributes_' + newId + '_type_of" />' +
        '<input onchange="generate_creator_preview()" class="form-control dataset creator" placeholder="[Family Name, e.g.: Smith]" type="text" name="dataset[creators_attributes][' + newId + '][family_name]" id="dataset_creators_attributes_' + newId + '_family_name" />' +
        '</td>' +

        '<td class="col-md-2">' +
        '<input onchange="generate_creator_preview()" class="form-control dataset creator" placeholder="[Given Name, e.g.: John W., Jr. ]" type="text" name="dataset[creators_attributes][' + newId + '][given_name]" id="dataset_creators_attributes_' + newId + '_given_name" />' +
        '</td>' +

        '<td class="col-md-2">' +
        '<input value="ORCID" type="hidden" name="dataset[creators_attributes][' + newId + '][identifier_scheme]" id="dataset_creators_attributes_' + newId + '_identifier_scheme" />' +
        '<input class="form-control dataset orcid-mask", data-mask="9999-9999-9999-999*", placeholder="[xxxx-xxxx-xxxx-xxxx]" type="text" name="dataset[creators_attributes][' + newId + '][identifier]" id="dataset_creators_attributes_' + newId + '_identifier" />' +
        '</td>'+

        '<td class="col-md-1">' +
        '<button type="button" class="btn btn-primary btn-block orcid-search-btn" data-id="' + newId + '" onclick="showOrcidSearchModal('+ newId +')"><span class="glyphicon glyphicon-search"></span>&nbsp;Look Up</a>' +
        '</td>' +
        '<td class="col-md-2">' +
        '<input onchange="handle_creator_email_change(this)" class="form-control dataset creator-email" placeholder="[Email, e.g.: netid@illinois.edu]" type="email" name="dataset[creators_attributes][' + newId + '][email]" id="dataset_creators_attributes_' + newId + '_email" />' +
        '</td>' +
        '<td class="col-md-2" align="center"><input name="dataset[creators_attributes][' +  newId + '][is_contact]" type="hidden" value="false" id="dataset_creators_attributes_' + newId + '_is_contact"><input class="dataset contact_radio" name="primary_contact" onchange="handle_contact_change()" type="radio" value="false"></td>' +
        '<td class="col-md-1"></td>' +
        '</tr>';
    $("#creator_table tbody:last-child").append(creator_row);

    handleCreatorTable();

}

function remove_creator_row(creator_index) {

    // do not allow removal of primary contact for published dataset

    if ( ($("input[name='dataset[publication_state]']").val() != 'draft') && ($("#dataset_creators_attributes_" + creator_index + "_is_contact").val() == 'true'))  {
     alert("The primary long term contact for a published dataset may not be removed.  To delete this author listing, first select a different contact.")
    }
    else {
        if ($("#dataset_creators_attributes_" + creator_index + "_id").val() != undefined) {
            $("#dataset_creators_attributes_" + creator_index + "__destroy").val("true");
        }

        $("#deleted_creator_table > tbody:last-child").append($("#creator_index_" + creator_index));

        $("#creator_index_" + creator_index).hide();
        $('#creator_table').sortable('refresh');

        if ($("#creator_table tr").length < 2) {
            add_creator_row();
        }
        handleCreatorTable();
        generate_creator_preview();
    }
}

function handleCreatorTable(){
    $('#creator_table tr').each(function (i) {
        // for all but header row, set the row_position value of the input to match the table row position
        if (i > 0) {
            var split_id = (this.id).split('_');
            var creator_index = split_id[2];

            $("#dataset_creators_attributes_" + creator_index + "_row_position").val(i);

            // set creator row num display
            //$("td:first", this).html("<span style='display:inline;'>  " + i + "     </span><span style='display:inline;' class='glyphicon glyphicon-resize-vertical'></span>" );

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
    if ( isEmail( $(input).val() ) ) {
        $(input).closest('td').removeClass('input-field-required');
        $("#email_required_span").removeClass('highlight');
        $(input).removeClass("invalid-input");
    } else if ($(input).val() != "") {
        $(input).addClass("invalid-input");
        alert("email address must be in valid format");
        $(input).focus();
    } else {
        $(input).removeClass("invalid-input");
    }
}

function generate_creator_preview(){
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

function handle_contact_change(){
    // set is_contact value to match selection staus and highlight required email input field if blank
    var selectedVal = $("input[type='radio'][name='primary_contact']:checked").val();
    $("#email_required_span").removeClass('highlight');

    $('#creator_table tr').each(function (i) {
        if (i > 0) {
            var creator_index = $(this).find('td').first().next().find('input').first().attr('id').split('_')[3];
            //mark all as not the contact -- then later mark the contact as the contact.
            $("input[name='dataset[creators_attributes][" + creator_index + "][email]']").closest('td').removeClass('input-field-required');
            $("input[name='dataset[creators_attributes][" + creator_index + "][is_contact]']").val('false');
        }
    });

    $("input[name='dataset[creators_attributes][" + selectedVal + "][is_contact]']").val('true');

    if ($("input[name='dataset[creators_attributes][" + selectedVal + "][email]']").val() == ""){
        $("#email_required_span").addClass('highlight');
        $("input[name='dataset[creators_attributes][" + selectedVal + "][email]']").closest('td').addClass('input-field-required');
        $("input[name='dataset[creators_attributes][" + selectedVal + "][email]']").focus();
    }
}

// *** ORCID stuff


function set_orcid_from_search_modal(){
    var creator_index = $("#creator-index").val();
    var selected = $("input[type='radio'][name='orcid-search-select']:checked").val();
    var select_split = selected.split("~");
    var selected_id = select_split[0];
    var selected_family = select_split[1];
    var selected_given = select_split[2];

    $("#dataset_creators_attributes_" + creator_index  + "_identifier").val(selected_id);
    $("#dataset_creators_attributes_" + creator_index + "_family_name").val(selected_family);
    $("#dataset_creators_attributes_" + creator_index + "_given_name").val(selected_given);
}

function search_orcid(){
    $("#orcid-search-results").empty();
    $('.orcid-search-spinner').show();

    var search_url = 'https://pub.orcid.org/';
    var bio_segment = 'v1.2/search/orcid-bio?q='
    if($("#creator-family").val() != "") {
        var search_query = 'family-name:' + $("#creator-family").val();
        if ($("#creator-given").val() != "") {
            search_query = search_query + '+AND+given-names:' + $("#creator-given").val();
        }
    } else if ($("#creator-given").val() != "") {
        var search_query = 'given-names:' + $("#creator-given").val();
    }

    var search_string = search_url + bio_segment + search_query + '&start=0&rows=50&wt=json';

    $.ajax({
        url: search_string,
        dataType: 'jsonp',
        success: function(data){
            $('.orcid-search-spinner').hide();

            var total_found = data["orcid-search-results"]["num-found"];

            if (total_found > 50){
                var orcidSearchString = "";

                if ($("#creator-given").val() != ""){
                    orcidSearchString = $("#creator-given").val();
                }
                if ($("#creator-family").val() != ""){
                    if (orcidSearchString != "") {
                        orcidSearchString = orcidSearchString + "%20"
                    }
                    orcidSearchString = orcidSearchString + $("#creator-family").val();
                }

                console.log("family: " + $("#creator-family").val());
                $("#orcid-search-results").append("<div class='row'>Showing first 50 results of " + total_found + ". For more results, search <a href='https://orcid.org/orcid-search/quick-search?searchQuery=" + orcidSearchString + "' target='_blank'>The ORCID site</a>.</div><hr/>");
            }

            if (total_found > 0) {
                $("#orcid-search-results").append("<table class='table table-striped' id='orcid-search-results-table'><thead><tr class='row'><th><span class='col-md-6'>Identifier (click link for details)</span><span class='col-md-1'>Select</span></th></tr></thead><tbody></tbody></table>")

                var people = data["orcid-search-results"]["orcid-search-result"];
                people_minified = [];
                var given_name = "";
                var family_name = "";
                var orcid = "";
                var orcid_uri = "";
                $.each(people, function (index, person) {
                    try {
                        given_name = person['orcid-profile']['orcid-bio']['personal-details']['given-names']['value'];
                        family_name = person['orcid-profile']['orcid-bio']['personal-details']['family-name']['value'];
                        orcid = person['orcid-profile']['orcid-identifier']['path'];
                        orcid_uri = person['orcid-profile']['orcid-identifier']['uri'];
                        people_minified.push(given_name + ' ' + family_name + ', ' + orcid);
                        $("#orcid-search-results-table > tbody:last-child").append("<tr class='row'><td><span class='col-md-6'><a href='" + orcid_uri + "' target='_blank'>" + family_name + ", " + given_name + ": " + orcid + "</a></span><span class='col-md-1'><input type='radio' name='orcid-search-select' onclick='enableOrcidImport()'  value='" + orcid + "~" + family_name + "~" + given_name + "'/></span></td></tr>");
                    } catch(err){
                        console.log(err);
                    }
                });
            } else {
                $("#orcid-search-results").append("<p>No results found.  Try fewer letters or <a href='http://orcid.org' target='_blank'>The ORCID site</a></p>")
            }
        },
        error: function(xhr){
            console.error(xhr);
        }
    });

}
function enableOrcidImport(){

    $('#orcid-import-btn').prop('disabled', false);
}

function showOrcidSearchModal(creator_index){

    $('#orcid-import-btn').prop('disabled', true);

    $("#creator-index").val(creator_index);
    var creatorFamilyName =  $("#dataset_creators_attributes_" + creator_index + "_family_name").val();
    var creatorGivenName = $("#dataset_creators_attributes_" + creator_index + "_given_name").val();
    $("#creator-family").val(creatorFamilyName);
    $("#creator-given").val(creatorGivenName);
    $("#orcid-search-results").empty();
    $('#orcid_search').modal('show');
}

function isEmail(email) {
    var regex = /^([a-zA-Z0-9_.+-])+\@(([a-zA-Z0-9-])+\.)+([a-zA-Z0-9]{2,4})+$/;
    return regex.test(email);
}

$(document).ready(creators_ready);
$(document).on('page:load', creators_ready);
