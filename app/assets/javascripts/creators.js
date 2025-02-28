// work-around turbo links to trigger ready function stuff on every page.

var creators_ready;
creators_ready = function () {
    $('.orcid-search-spinner').hide();
    var cells, desired_width, table_width;
    if ($("#creator_table tr").length > 0) {

        var person_creators_type = 0;
        var org_creators_type = 1;
        var dataset_creator_type = null;

        if ($('#dataset_org_creators').val() == 'true') {
            dataset_creator_type = org_creators_type;
        } else {
            dataset_creator_type = person_creators_type;
        }

        table_width = $('#creator_table').width();
        cells = $('#creator_table').find('tr')[0].cells.length;
        desired_width = table_width / cells + 'px';

        console.log(dataset_creator_type);

        handleCreatorTable(dataset_creator_type);

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
                handleCreatorTable(dataset_creator_type);
                generate_creator_preview();
            }
        });

    }

    //alert("creators.js javascript working");
}

function add_person_creator(){

    $('#update-confirm').prop('disabled', false);

    var maxId = Number($('#creator_index_max').val());
    var newId = 1;

    if (maxId != NaN) {
        newId = maxId + 1;
    }

    $('#creator_index_max').val(newId);

    var creator_row = '<tr class="item row" id="creator_index_' + newId + '">' +
        '<td><span style="display:inline;" class="glyphicon glyphicon-resize-vertical"></span></td>' +
        '<td class="col-md-2">' +
        '<input type="hidden" value="' + $('#creator_table tr').length + '" name="dataset[creators_attributes][' + newId + '][row_position]" id="dataset_creators_attributes_' + newId + '_row_position" />' +
        '<input value="0" type="hidden" name="dataset[creators_attributes][' + newId + '][type_of]" id="dataset_creators_attributes_' + newId + '_type_of" />' +
        '<input onchange="generate_creator_preview()" class="form-control dataset creator" placeholder="[e.g.: Smith]" type="text" name="dataset[creators_attributes][' + newId + '][family_name]" id="dataset_creators_attributes_' + newId + '_family_name" />' +
        '</td>' +

        '<td class="col-md-2">' +
        '<input onchange="generate_creator_preview()" class="form-control dataset creator" placeholder="[e.g.: Jean W.]" type="text" name="dataset[creators_attributes][' + newId + '][given_name]" id="dataset_creators_attributes_' + newId + '_given_name" />' +
        '</td>' +

        '<td class="col-md-2">' +
        '<input value="ORCID" type="hidden" name="dataset[creators_attributes][' + newId + '][identifier_scheme]" id="dataset_creators_attributes_' + newId + '_identifier_scheme" />' +
        '<input class="form-control dataset orcid-mask", data-mask="9999-9999-9999-999*", placeholder="[xxxx-xxxx-xxxx-xxxx]" type="text" name="dataset[creators_attributes][' + newId + '][identifier]" id="dataset_creators_attributes_' + newId + '_identifier" />' +
        '</td>' +

        '<td class="col-md-1">' +
        '<button type="button" class="btn btn-primary btn-block orcid-search-btn" data-id="' + newId + '" onclick="showCreatorOrcidSearchModal(' + newId + ')"><span class="glyphicon glyphicon-search"></span>&nbsp;Look Up&nbsp;<img src="/iD_icon_16x16.png">' +
        '</td>' +
        '<td class="col-md-2">' +
        '<input onchange="handle_creator_email_change(this)" class="form-control dataset creator-email" placeholder="[e.g.: netid@illinois.edu]" type="email" name="dataset[creators_attributes][' + newId + '][email]" id="dataset_creators_attributes_' + newId + '_email" />' +
        '</td>' +
        '<td class="col-md-2" align="center"><input name="dataset[creators_attributes][' + newId + '][is_contact]" type="hidden" value="false" id="dataset_creators_attributes_' + newId + '_is_contact"><input class="dataset contact_radio" name="primary_contact" onchange="handle_contact_change()" type="radio"  value="' + newId + '"></td>' +
        '<td class="col-md-1"></td>' +
        '</tr>';
    $("#creator_table tbody:last-child").append(creator_row);

    handleCreatorTable(0);
}

function add_institution_creator(){
    $('#update-confirm').prop('disabled', false);

    var maxId = Number($('#creator_index_max').val());
    var newId = 1;

    if (maxId != NaN) {
        newId = maxId + 1;
    }

    $('#creator_index_max').val(newId);

    var creator_row = '<tr class="item row" id="creator_index_' + newId + '">' +
        '<td><span style="display:inline;" class="glyphicon glyphicon-resize-vertical"></span></td>' +
        '<td class="col-md-6">' +
        '<input type="hidden" value="' + $('#creator_table tr').length + '" name="dataset[creators_attributes][' + newId + '][row_position]" id="dataset_creators_attributes_' + newId + '_row_position" />' +
        '<input value="1" type="hidden" name="dataset[creators_attributes][' + newId + '][type_of]" id="dataset_creators_attributes_' + newId + '_type_of" />' +
        '<input onchange="generate_creator_preview()" class="form-control dataset creator" placeholder="[e.g.: Institute of Phenomenon Observation and Measurement]" type="text" name="dataset[creators_attributes][' + newId + '][institution_name]" id="dataset_creators_attributes_' + newId + '_institution_name" />' +
        '</td>' +
        '<td class="col-md-3">' +
        '<input onchange="handle_creator_email_change(this)" class="form-control dataset creator-email" placeholder="[e.g.: netid@illinois.edu]" type="email" name="dataset[creators_attributes][' + newId + '][email]" id="dataset_creators_attributes_' + newId + '_email" />' +
        '</td>' +
        '<td class="col-md-2" align="center"><input name="dataset[creators_attributes][' + newId + '][is_contact]" type="hidden" value="false" id="dataset_creators_attributes_' + newId + '_is_contact"><input class="dataset contact_radio" name="primary_contact" onchange="handle_contact_change()" type="radio"  value="' + newId + '"></td>' +
        '<td class="col-md-1"></td>' +
        '</tr>';
    $("#creator_table tbody:last-child").append(creator_row);

    handleCreatorTable(1);
}

function remove_creator_row(creator_index, creator_type) {

    // do not allow removal of primary contact for published dataset

    var person_creators_type = 0;
    var org_creators_type = 1;
    var dataset_creator_type = null;

    if ($('#dataset_org_creators').val() == 'true') {
        dataset_creator_type = org_creators_type;
    } else {
        dataset_creator_type = person_creators_type;
    }

    if (($("input[name='dataset[publication_state]']").val() != 'draft') && ($("#dataset_creators_attributes_" + creator_index + "_is_contact").val() == 'true')) {
        alert("The primary long term contact for a published dataset may not be removed.  To delete this author listing, first select a different contact.")
    }
    else {
        if ($("#dataset_creators_attributes_" + creator_index + "_id").val() == undefined) {
            $("#creator_index_" + creator_index).remove();
        } else {
            $("#dataset_creators_attributes_" + creator_index + "__destroy").val("true");
            $("#deleted_creator_table > tbody:last-child").append($("#creator_index_" + creator_index));
            $("#creator_index_" + creator_index).hide();
        }

        $('#creator_table').sortable('refresh');

        if ($("#creator_table tr").length < 2) {

            if (creator_type == org_creators_type){
                add_institution_creator();
            } else {
                add_person_creator();
            }
        }
        $('#update-confirm').prop('disabled', false);
        handleCreatorTable(dataset_creator_type);
        generate_creator_preview();
    }
}

function handleCreatorTable(creator_type) {

    console.log("inside handleCreatorTable");

    console.log(creator_type);

    var person_creators_type = 0;
    var org_creators_type = 1;

    $('#creator_table tr').each(function (i) {
        // for all but header row, set the row_position value of the input to match the table row position
        console.log("inside handleCreatorTable each");
        if (i > 0) {
            var split_id = (this.id).split('_');
            var creator_index = split_id[2];

            console.log("creator_index: " + creator_index);

            $("#dataset_creators_attributes_" + creator_index + "_row_position").val(i);

            // set creator row num display
            //$("td:first", this).html("<span style='display:inline;'>  " + i + "     </span><span style='display:inline;' class='glyphicon glyphicon-resize-vertical'></span>" );

            //console.log("i: " + i);
            //console.log("hidden_row_count: " + hidden_row_count);
            //console.log("table row count: " + $("#creator_table tr").length );

            if ((i + 1) == ($("#creator_table tr").length)) {

                if (creator_type == org_creators_type){
                    $("td:last-child", this).html("<button class='btn btn-danger btn-sm' onclick='remove_creator_row(" + creator_index + ", 1 )' type='button'><span class='glyphicon glyphicon-trash'></span></button>&nbsp;&nbsp;<button class='btn btn-success btn-sm' onclick='add_institution_creator()' type='button'><span class='glyphicon glyphicon-plus'></span></button>");
                } else {
                    $("td:last-child", this).html("<button class='btn btn-danger btn-sm' onclick='remove_creator_row(" + creator_index + ", 0  )' type='button'><span class='glyphicon glyphicon-trash'></span></button>&nbsp;&nbsp;<button class='btn btn-success btn-sm' onclick='add_person_creator()' type='button'><span class='glyphicon glyphicon-plus'></span></button>");
                }


            } else {
                if (creator_type == org_creators_type) {
                    $("td:last-child", this).html("<button class='btn btn-danger btn-sm' onclick='remove_creator_row(" + creator_index + ", 1  )' type='button'><span class='glyphicon glyphicon-trash'></span></button>");
                } else {
                    $("td:last-child", this).html("<button class='btn btn-danger btn-sm' onclick='remove_creator_row(" + creator_index + ", 0  )' type='button'><span class='glyphicon glyphicon-trash'></span></button>");
                }

            }
        }
    });
}

function handle_creator_email_change(input) {

    console.log("creator");
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

function generate_creator_preview() {

    var person_creators_type = 0;
    var org_creators_type = 1;
    var dataset_creator_type = null;

    if ($('#dataset_org_creators').val() == 'true') {
        dataset_creator_type = org_creators_type;
    } else {
        dataset_creator_type = person_creators_type;
    }

    var creator_list_preview = "";

    $('#creator_table tr').each(function (i) {

        var split_id = (this.id).split('_');
        var creator_index = split_id[2];

        if (i > 0)
        {
            if (dataset_creator_type == org_creators_type) {
               if (($("#dataset_creators_attributes_" + creator_index + "_institution_name").val() != "")){
                   $(this).removeClass("invalid-name");
                   if (creator_list_preview.length > 0) {
                       creator_list_preview = creator_list_preview + "; ";
                   }
                   creator_list_preview = creator_list_preview + $("#dataset_creators_attributes_" + creator_index + "_institution_name").val();

               } else {
                   $(this).addClass("invalid-name");
               }
            } else {
               if (($("#dataset_creators_attributes_" + creator_index + "_family_name").val() != "") && ($("#dataset_creators_attributes_" + creator_index + "_given_name").val() != "")){
                   $(this).removeClass("invalid-name");
                   if (creator_list_preview.length > 0) {
                       creator_list_preview = creator_list_preview + "; ";
                   }
                   creator_list_preview = creator_list_preview + $("#dataset_creators_attributes_" + creator_index + "_family_name").val();
                   creator_list_preview = creator_list_preview + ", "
                   creator_list_preview = creator_list_preview + $("#dataset_creators_attributes_" + creator_index + "_given_name").val();
               } else {
                   $(this).addClass("invalid-name");
               }
            }
        }
    });

    $('#creator-preview').html(creator_list_preview);
}

function handle_contact_change() {
    // set is_contact value to match selection staus and highlight required email input field if blank
    var selectedVal = $("input[type='radio'][name='primary_contact']:checked").val();
    console.log("selected value: " + selectedVal);

    $('#creator_table tr').each(function (i) {
        if (i > 0) {
            var creator_index = $(this).find('td').first().next().find('input').first().attr('id').split('_')[3];

            //mark all as not the contact -- then later mark the contact as the contact.
            $("input[name='dataset[creators_attributes][" + creator_index + "][email]']").closest('td').removeClass('input-field-required');
            $("input[name='dataset[creators_attributes][" + creator_index + "][is_contact]']").val('false');
        }
    });

    $("input[name='dataset[creators_attributes][" + selectedVal + "][is_contact]']").val('true');

}

// *** ORCID stuff


function set_creator_orcid_from_search_modal() {
    var creator_index = $("#creator-index").val();
    var selected = $("input[type='radio'][name='orcid-search-select']:checked").val();
    var select_split = selected.split("~");
    var selected_id = select_split[0];
    var selected_family = select_split[1];
    var selected_given = select_split[2];

    $("#dataset_creators_attributes_" + creator_index + "_identifier").val(selected_id);
    $("#dataset_creators_attributes_" + creator_index + "_family_name").val(selected_family);
    $("#dataset_creators_attributes_" + creator_index + "_given_name").val(selected_given);
}

function search_creator_orcid() {

    $("#orcid-search-results").empty();
    $('.orcid-search-spinner').show();

    var endpoint = 'https://pub.orcid.org/v2.0/search?q=';
    if ($("#creator-family").val() != "") {
        var search_query = 'family-name:' + $("#creator-family").val() + "*";
        if ($("#creator-given").val() != "") {
            search_query = search_query + '+AND+given-names:' + $("#creator-given").val() + "*";
        }
    } else if ($("#creator-given").val() != "") {
        var search_query = 'given-names:' + $("#creator-given").val() + "*";
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

function showCreatorOrcidSearchModal(creator_index) {

    $('#orcid-import-btn').prop('disabled', true);

    $("#creator-index").val(creator_index);
    var creatorFamilyName = $("#dataset_creators_attributes_" + creator_index + "_family_name").val();
    var creatorGivenName = $("#dataset_creators_attributes_" + creator_index + "_given_name").val();
    $("#creator-family").val(creatorFamilyName);
    $("#creator-given").val(creatorGivenName);
    $("#orcid-search-results").empty();
    $('#orcid_creator_search').modal('show');
}

$(document).ready(creators_ready);
$(document).on('page:load', creators_ready);
