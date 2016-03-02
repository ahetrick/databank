// work-around turbo links to trigger ready function stuff on every page.

var related_materials_ready;
related_materials_ready = function () {
    $('.material-text').css("visibility", "hidden");
    handleMaterialTable();
    // console.log ("user role: " + user_role);
    // alert("related_materials.js javascript working");
}

function handleMaterialChange(materialIndex) {
    materialSelectVal = $("#dataset_related_materials_attributes_" + materialIndex + "_selected_type").val();
    console.log(materialSelectVal);

    switch (materialSelectVal) {
        case 'Article' || 'Code' || 'Presentation':
            $('#dataset_related_materials_attributes_' + materialIndex + '_material_type').val(materialSelectVal);
            $('#dataset_related_materials_attributes_' + materialIndex + '_material_type').css("visibility", "hidden");
            break;
        case 'Other':
            $('#dataset_related_materials_attributes_' + materialIndex + '_material_type').val('');
            $('.material-text').css("visibility", "visible");
            $('.material-text').focus();
            break;
        // should not get to default
        default:
            $('#dataset_related_materials_attributes_' + materialIndex + '_material_type').val('');
            console.log("material: " + materialSelectVal)
            console.log("material_index: " + materialIndex)
    }

}

function handleMaterialTable() {
    $('#material_table tr').each(function (i) {
        if (i > 0) {
            var split_id = (this.id).split('_');
            var material_index = split_id[2];

            if ((i + 1 ) == ($("#material_table tr").length)) {
                $("td:last-child", this).html("<button class='btn btn-danger btn-sm' onclick='remove_material_row(\x22" + material_index + "\x22 )' type='button'><span class='glyphicon glyphicon-trash'></span></button>&nbsp;&nbsp;<button class='btn btn-success btn-sm' onclick='add_material_row()' type='button'><span class='glyphicon glyphicon-plus'></span></button>");
            } else {
                $("td:last-child", this).html("<button class='btn btn-danger btn-sm' onclick='remove_material_row(\x22" + material_index + "\x22 )' type='button'><span class='glyphicon glyphicon-trash'></span></button>");
            }
        }
    });
}

function add_material_row() {

    var maxId = Number($('#material_index_max').val());
    var newId = 0;

    if (maxId != NaN) {
        newId = maxId + 1;
    }
    $('#material_index_max').val(newId);

    if (role = 'admin') {

        var material_row = '<tr class="item row" id="material_index_' + newId + '">' +
            '<td>' +
            '<select class="form-control dataset" onchange="handleMaterialChange(' + newId + ')" name="dataset[related_materials_attributes][' + newId + '][selected_type]" id="dataset_related_materials_attributes_' + newId + '_selected_type">' +
            '<option value="">Please select</option>' +
            '<option value="Article">Article</option>' +
            '<option value="Code">Code</option>' +
            '<option value="Dataset">Dataset</option>' +
            '<option value="Presentation">Presentation</option>' +
            '<option value="Other">Other:</option></select>' +
            '</td>' +
            '<td>' +
            '<input class="form-control dataset material-text" type="text" name="dataset[related_materials_attributes][' + newId + '][material_type]" id="dataset_related_materials_attributes_' + newId + '_material_type" style="visibility: hidden;" />' +
            '</td>' +
            '<td>' +
            '<select class="form-control dataset" name="dataset[related_materials_attributes][' + newId + '][availability]" id="dataset_related_materials_attributes_' + newId + '_availability">' +
            '<option value="">Please select</option>' +
            '<option value="Forthcoming">Forthcoming</option>' +
            '<option value="Available">Available</option></select>' +
            '</td>' +
            '<td>' +
            '<input class="form-control dataset" type="text" name="dataset[related_materials_attributes][' + newId + '][link]" id="dataset_related_materials_attributes_' + newId + '_link" />' +
            '</td>' +
            '<td>' +
            '<textarea rows="2" class="form-control dataset" name="dataset[related_materials_attributes][' + newId + '][citation]" id="dataset_related_materials_attributes_' + newId + '_citation">' +
            '</textarea>' +
            '</td>' +

            '<td>' +
            '<div class="form-group curator-only">' +
            '<input placeholder="[URI]" class="form-control dataset" type="text" name="dataset[related_materials_attributes][' + newId + '][uri]" id="dataset_related_materials_attributes_' + newId + '_uri" />' +
            '</div>' +
            '<div class="form-group curator-only">' +
            '<select class="form-control dataset" name="dataset[related_materials_attributes][' + newId + '][uri_type]" id="dataset_related_materials_attributes_' + newId + '_uri_type">' +
            '<option value="">Select Type</option>' +
            '<option value="ARK">ARK</option>' +
            '<option value="arXiv">arXiv</option>' +
            '<option value="bibcode">bibcode</option>' +
            '<option value="DOI">DOI</option>' +
            '<option value="EAN13">EAN13</option>' +
            '<option value="EISSN">EISSN</option>' +
            '<option value="Handle">Handle</option>' +
            '<option value="ISBN">ISBN</option>' +
            '<option value="ISSN">ISSN</option>' +
            '<option value="ISTC">ISTC</option>' +
            '<option value="LISSN">LISSN</option>' +
            '<option value="LSID">LSID</option>' +
            '<option value="PMID">PMID</option>' +
            '<option value="PURL">PURL</option>' +
            '<option value="UPC">UPC</option>' +
            '<option value="URL">URL</option>' +
            '<option value="URN">URN</option>' +
            '</select>' +
            '</div>' +
            '</td>' +
            '<td>' +
            '<div class="form-group curator-only">' +
            '<input type="hidden" name="dataset[related_materials_attributes][' + newId + '][datacite_list]" id="dataset_related_materials_attributes_' + newId + '_datacite_list" />' +
            '<input name="datacite_relation" type="checkbox" value="IsSupplementTo"> IsSupplementTo </input>' +
            '<br>' +
            '<input name="datacite_relation" type="checkbox" value="IsCitedBy"> IsCitedBy </input>' +
            '<br>' +
            '<input name="datacite_relation" type="checkbox" value="IsPreviousVersionOf"> IsPreviousVersionOf </input>' +
            '<br>' +
            '<input name="datacite_relation" type="checkbox" value="IsNewVersionOf"> IsNewVersionOf </input>' +
            '</div>' +
            '</td>' +

            '<td></td>' +
            '</tr>'

    } else {
        var material_row = '<tr class="item row" id="material_index_' + newId + '">' +
            '<td>' +
            '<select class="form-control dataset" onchange="handleMaterialChange(' + newId + ')" name="dataset[related_materials_attributes][' + newId + '][selected_type]" id="dataset_related_materials_attributes_' + newId + '_selected_type">' +
            '<option value="">Please select</option>' +
            '<option value="Article">Article</option>' +
            '<option value="Code">Code</option>' +
            '<option value="Dataset">Dataset</option>' +
            '<option value="Presentation">Presentation</option>' +
            '<option value="Other">Other:</option></select>' +
            '</td>' +
            '<td>' +
            '<input class="form-control dataset material-text" type="text" name="dataset[related_materials_attributes][' + newId + '][material_type]" id="dataset_related_materials_attributes_' + newId + '_material_type style="visibility: hidden;" />' +
            '</td>' +
            '<td>' +
            '<select class="form-control dataset" name="dataset[related_materials_attributes][' + newId + '][availability]" id="dataset_related_materials_attributes_' + newId + '_availability">' +
            '<option value="">Please select</option>' +
            '<option value="Forthcoming">Forthcoming</option>' +
            '<option value="Available">Available</option></select>' +
            '</td>' +
            '<td>' +
            '<input class="form-control dataset" type="text" name="dataset[related_materials_attributes][' + newId + '][link]" id="dataset_related_materials_attributes_' + newId + '_link" />' +
            '</td>' +
            '<td>' +
            '<textarea rows="2" class="form-control dataset" name="dataset[related_materials_attributes][' + newId + '][citation]" id="dataset_related_materials_attributes_' + newId + '_citation">' +
            '</textarea>' +
            '</td>' +
            '<td></td>' +
            '</tr>'
    }

    $("#material_table tbody:last-child").append(material_row);
    handleMaterialTable();
}

function remove_material_row(material_index) {
    if ($("#dataset_related_materials_attributes_" + material_index + "_id").val() != undefined) {
        $("#dataset_related_materials_attributes_" + material_index + "__destroy").val("true");
        $("#deleted_material_table > tbody:last-child").append($("#material_index_" + material_index));
    }

    $("#material_index_" + material_index).hide();

    if ($("#material_table tr").length < 2) {
        add_material_row();
    }
    handleFunderTable();
}


$(document).ready(related_materials_ready);
$(document).on('page:load', related_materials_ready);
