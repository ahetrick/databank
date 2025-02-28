// work-around turbo links to trigger ready function stuff on every page.

var contributors_ready;
contributors_ready = function () {
    $('.orcid-search-spinner').hide();
    var cells, desired_width, table_width;
    if ($("#contributor_table tr").length > 0) {
        table_width = $('#contributor_table').width();
        cells = $('#contributor_table').find('tr')[0].cells.length;
        desired_width = table_width / cells + 'px';
        handlecontributorTable();

        $('#contributor_table td').css('width', desired_width);

        return $('#contributor_table').sortable({

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
                handlecontributorTable();
                generate_contributor_preview();
            }
        });

    }

    //alert("contributors.js javascript working");
}

function add_contributor_row() {

    $('#update-confirm').prop('disabled', false);

    var maxId = Number($('#contributor_index_max').val());
    var newId = 1;

    if (maxId != NaN) {
        newId = maxId + 1;
    }
    $('#contributor_index_max').val(newId);

    var contributor_row = '<tr class="item row" id="contributor_index_' + newId + '">' +
        '<td><span style="display:inline;" class="glyphicon glyphicon-resize-vertical"></span></td>' +
        '<td class="col-md-2">' +
        '<input type="hidden" value="' + $('#contributor_table tr').length + '" name="dataset[contributors_attributes][' + newId + '][row_position]" id="dataset_contributors_attributes_' + newId + '_row_position" />' +
        '<input value="0" type="hidden" name="dataset[contributors_attributes][' + newId + '][type_of]" id="dataset_contributors_attributes_' + newId + '_type_of" />' +
        '<input onchange="generate_contributor_preview()" class="form-control dataset contributor" placeholder="[e.g.: Smith]" type="text" name="dataset[contributors_attributes][' + newId + '][family_name]" id="dataset_contributors_attributes_' + newId + '_family_name" />' +
        '</td>' +

        '<td class="col-md-2">' +
        '<input onchange="generate_contributor_preview()" class="form-control dataset contributor" placeholder="[e.g.: Jean W.]" type="text" name="dataset[contributors_attributes][' + newId + '][given_name]" id="dataset_contributors_attributes_' + newId + '_given_name" />' +
        '</td>' +

        '<td class="col-md-2">' +
        '<input value="ORCID" type="hidden" name="dataset[contributors_attributes][' + newId + '][identifier_scheme]" id="dataset_contributors_attributes_' + newId + '_identifier_scheme" />' +
        '<input class="form-control dataset orcid-mask", data-mask="9999-9999-9999-999*", placeholder="[xxxx-xxxx-xxxx-xxxx]" type="text" name="dataset[contributors_attributes][' + newId + '][identifier]" id="dataset_contributors_attributes_' + newId + '_identifier" />' +
        '</td>' +

        '<td class="col-md-1">' +
        '<button type="button" class="btn btn-primary btn-block orcid-search-btn" data-id="' + newId + '" onclick="showContributorOrcidSearchModal(' + newId + ')"><span class="glyphicon glyphicon-search"></span>&nbsp;Look Up&nbsp;<img src="/iD_icon_16x16.png">' +
        '</td>' +
        '<td class="col-md-3">' +
        '<input onchange="handle_contributor_email_change(this)" class="form-control dataset contributor-email" placeholder="[e.g.: netid@illinois.edu]" type="email" name="dataset[contributors_attributes][' + newId + '][email]" id="dataset_contributors_attributes_' + newId + '_email" />' +
        '</td>' +
        '<td class="col-md-1"></td>' +
        '</tr>';
    $("#contributor_table tbody:last-child").append(contributor_row);

    handlecontributorTable();

}

function remove_contributor_row(contributor_index) {


    // do not allow removal of primary contact for published dataset

    if (($("input[name='dataset[publication_state]']").val() != 'draft') && ($("#dataset_contributors_attributes_" + contributor_index + "_is_contact").val() == 'true')) {
        alert("The primary long term contact for a published dataset may not be removed.  To delete this author listing, first select a different contact.")
    }
    else {
        if ($("#dataset_contributors_attributes_" + contributor_index + "_id").val() == undefined) {
            $("#contributor_index_" + contributor_index).remove();
        } else {
            $("#dataset_contributors_attributes_" + contributor_index + "__destroy").val("true");
            $("#deleted_contributor_table > tbody:last-child").append($("#contributor_index_" + contributor_index));
            $("#contributor_index_" + contributor_index).hide();
        }

        $('#contributor_table').sortable('refresh');

        if ($("#contributor_table tr").length < 2) {
            add_contributor_row();
        }
        $('#update-confirm').prop('disabled', false);
        handlecontributorTable();
        generate_contributor_preview();
    }
}

function handlecontributorTable() {
    $('#contributor_table tr').each(function (i) {
        // for all but header row, set the row_position value of the input to match the table row position
        if (i > 0) {
            var split_id = (this.id).split('_');
            var contributor_index = split_id[2];

            $("#dataset_contributors_attributes_" + contributor_index + "_row_position").val(i);

            // set contributor row num display
            //$("td:first", this).html("<span style='display:inline;'>  " + i + "     </span><span style='display:inline;' class='glyphicon glyphicon-resize-vertical'></span>" );

            //console.log("i: " + i);
            //console.log("hidden_row_count: " + hidden_row_count);
            //console.log("table row count: " + $("#contributor_table tr").length );

            if ((i + 1) == ($("#contributor_table tr").length)) {
                $("td:last-child", this).html("<button class='btn btn-danger btn-sm' onclick='remove_contributor_row(\x22" + contributor_index + "\x22 )' type='button'><span class='glyphicon glyphicon-trash'></span></button>&nbsp;&nbsp;<button class='btn btn-success btn-sm' onclick='add_contributor_row()' type='button'><span class='glyphicon glyphicon-plus'></span></button>");
            } else {
                $("td:last-child", this).html("<button class='btn btn-danger btn-sm' onclick='remove_contributor_row(\x22" + contributor_index + "\x22 )' type='button'><span class='glyphicon glyphicon-trash'></span></button>");
            }
        }
    });
}

function handle_contributor_email_change(input) {

    console.log("contributor");
    console.log($(input).val());
    console.log(isEmail($(input).val()));

    if (isEmail($(input).val())) {
        $(input).closest('td').removeClass('input-field-required');
        $(input).removeClass("invalid-email");
    } else if ($(input).val() != "") {
        $(input).addClass("invalid-email");
        alert("email address must be in valid format");
        $(input).focus();
    } else {
        $(input).removeClass("invalid-email");
    }
}

function generate_contributor_preview() {
    var contributor_list_preview = "";

    $('#contributor_table tr').each(function (i) {

        var split_id = (this.id).split('_');
        var contributor_index = split_id[2];

        //console.log("inside tr each for contributor index " + contributor_index);

        //console.log($("#dataset_contributors_attributes_" + contributor_index + "__destroy").val());
        ;
        if ((i > 0) && (($("#dataset_contributors_attributes_" + contributor_index + "_family_name").val() != "") || ($("#dataset_contributors_attributes_" + contributor_index + "_given_name").val() != ""))) {

            //console.log("inside generate contributor 2");
            //console.log($("#dataset_contributors_attributes_" + contributor_index + "_family_name").val());

            if (contributor_list_preview.length > 0) {

                contributor_list_preview = contributor_list_preview + "; ";
            }

            contributor_list_preview = contributor_list_preview + $("#dataset_contributors_attributes_" + contributor_index + "_family_name").val();
            contributor_list_preview = contributor_list_preview + ", "
            contributor_list_preview = contributor_list_preview + $("#dataset_contributors_attributes_" + contributor_index + "_given_name").val();
        }
    });

    $('#contributor-preview').html(contributor_list_preview);
}

function handle_contact_change() {
    // set is_contact value to match selection staus and highlight required email input field if blank
    var selectedVal = $("input[type='radio'][name='primary_contact']:checked").val();
    console.log("selected value: " + selectedVal);

    $('#contributor_table tr').each(function (i) {
        if (i > 0) {
            var contributor_index = $(this).find('td').first().next().find('input').first().attr('id').split('_')[3];

            //mark all as not the contact -- then later mark the contact as the contact.
            $("input[name='dataset[contributors_attributes][" + contributor_index + "][email]']").closest('td').removeClass('input-field-required');
            $("input[name='dataset[contributors_attributes][" + contributor_index + "][is_contact]']").val('false');
        }
    });

    $("input[name='dataset[contributors_attributes][" + selectedVal + "][is_contact]']").val('true');

}

// *** ORCID stuff


function set_contributor_orcid_from_search_modal() {
    var contributor_index = $("#contributor-index").val();
    var selected = $("input[type='radio'][name='orcid-search-select']:checked").val();
    var select_split = selected.split("~");
    var selected_id = select_split[0];
    var selected_family = select_split[1];
    var selected_given = select_split[2];

    $("#dataset_contributors_attributes_" + contributor_index + "_identifier").val(selected_id);
    $("#dataset_contributors_attributes_" + contributor_index + "_family_name").val(selected_family);
    $("#dataset_contributors_attributes_" + contributor_index + "_given_name").val(selected_given);
}

function search_contributor_orcid() {

    $("#orcid-search-results").empty();
    $('.orcid-search-spinner').show();

    var endpoint = 'https://pub.orcid.org/v2.0/search?q=';
    if ($("#contributor-family").val() != "") {
        var search_query = 'family-name:' + $("#contributor-family").val() + "*";
        if ($("#contributor-given").val() != "") {
            search_query = search_query + '+AND+given-names:' + $("#contributor-given").val() + "*";
        }
    } else if ($("#contributor-given").val() != "") {
        var search_query = 'given-names:' + $("#contributor-given").val() + "*";
    }

    var search_string = endpoint + search_query;

    $.ajax({
        url: search_string,
        dataType: 'jsonp',
        success: function (data) {
            $('.orcid-search-spinner').hide();

              try {

                  var responseJson = data;

                  total_found = responseJson["num-found"];

                  resultJson = responseJson["result"];

                  var identifiers = [];

                  for (var i = 0; i < total_found; i++) {

                      if (typeof resultJson[i] != "undefined") {

                          entry = resultJson[i]["orcid-identifier"];

                          identifiers.push(entry);
                      }
                  }

                  var choices = [];

                  var max_records = total_found;

                  if (total_found > 50) {



                      $("#orcid-search-results").append("<div class='row'>Showing first 50 results of " + total_found + ". For more results, search <a href='http://orcid.org' target='_blank'>The ORCID site</a>.</div><hr/>");
                      max_records = 50;
                  }
                  if (total_found > 0) {

                      $("#orcid-search-results").append("<table class='table table-striped' id='orcid-search-results-table'><thead><tr class='row'><th class='col-md-5'>Identifier (click link for details)</th><th class='col-md-5'>Affiliation</span></th><th class='col-md-1'>Select</th></tr></thead><tbody></tbody></table>")

                      for (i = 0; i < max_records; i++) {
                          var orcidIdRecord = identifiers[i];

                          var orcid = orcidIdRecord["path"];

                          var orcid_uri = orcidIdRecord["uri"];

                          var orcidPerson = getOrcidPerson(orcid);

                          var given_name = orcidPerson["given-names"]["value"];
                          var family_name = orcidPerson["family-name"]["value"];


                          var affiliation = getOrcidAffiliation(orcid);


                          $("#orcid-search-results-table > tbody:last-child").append("<tr class='row'><td><a href='" + orcid_uri + "' target='_blank'>" + family_name + ", " + given_name + ": " + orcid + "</a></td><td>" + affiliation + "</td><td><input type='radio' name='orcid-search-select' onclick='enableOrcidImport()'  value='" + orcid + "~" + family_name + "~" + given_name + "'/></td></tr>");

                      }

                  } else {
                      $("#orcid-search-results").append("<p>No results found.  Try fewer letters or <a href='http://orcid.org' target='_blank'>The ORCID site</a></p>")
                  }
              } catch(err){
                  console.trace();
                  alert("Error searching: " + err.message);
              }

        },
        error: function (xhr) {
            alert("Error in search.");
            console.error(xhr);
        }
    });

}



function getOrcidPerson(orcid) {

    var endoint = 'https://pub.orcid.org/v2.0/';

    var personUrl = endoint + orcid + "/person";

    var xmlHttp = new XMLHttpRequest();

    xmlHttp.open("GET", personUrl, false); // false for synchronous request
    xmlHttp.setRequestHeader("Accept", "application/json");
    xmlHttp.send(null);
    response = xmlHttp.responseText;

    var responseJson = JSON.parse(response);

    return responseJson["name"];

}

function getOrcidAffiliation(orcid){
    var endoint = 'https://pub.orcid.org/v2.0/';

    var employmentsUrl = endoint + orcid + "/employments";

    var xmlHttp = new XMLHttpRequest();

    xmlHttp.open("GET", employmentsUrl, false); // false for synchronous request
    xmlHttp.setRequestHeader("Accept", "application/json");
    xmlHttp.send(null);
    response = xmlHttp.responseText;

    var responseJson = JSON.parse(response);

    var affiliaiton = 'unknown';

    if(responseJson["employment-summary"] != null && responseJson["employment-summary"][0] !=null && responseJson["employment-summary"][0]["organization"] != null) {

        var affiliaiton = responseJson["employment-summary"][0]["organization"]["name"] || "unknown";
    }

    return affiliaiton;

}


function enableOrcidImport() {

    $('#orcid-import-btn').prop('disabled', false);
}

function showContributorOrcidSearchModal(contributor_index) {

    $('#orcid-import-btn').prop('disabled', true);

    $("#contributor-index").val(contributor_index);
    var contributorFamilyName = $("#dataset_contributors_attributes_" + contributor_index + "_family_name").val();
    var contributorGivenName = $("#dataset_contributors_attributes_" + contributor_index + "_given_name").val();
    $("#contributor-family").val(contributorFamilyName);
    $("#contributor-given").val(contributorGivenName);
    $("#orcid-search-results").empty();
    $('#orcid_contributor_search').modal('show');
}

$(document).ready(contributors_ready);
$(document).on('page:load', contributors_ready);
