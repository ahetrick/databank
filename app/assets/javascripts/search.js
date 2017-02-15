// work-around turbo links to trigger ready function stuff on every page.

var search_ready;
search_ready = function () {

    handleFilterChange();
    // alert("search.js javascript working");
}

function clearFilters(){
    $(".checkFacetGroup").prop("checked",false);
    $("#searchForm").submit();
}

function handleFilterChange(){

    $('.hit').show();

    // just me
    if ( $('input[name="just_mine"]').is(':checked') ) {
        $('.not_mine').hide();
    }
    
    // depositor
    var depositor_checked = []
    $("input[name='depositors']:checkbox:checked").each(function(){
        depositor_checked.push($(this).val());
    });
    var has_depositor_filter = (depositor_checked && (depositor_checked.length > 0));
    if (has_depositor_filter){
        $("input[name='depositors']:checkbox:not(:checked)").each(function () {
            $('.'+ $(this).val() ).hide();
        });
    }
    
    // visbility
    var visibility_checked = []
    $("input[name='visibility_codes[]']:checkbox:checked").each(function(){
      visibility_checked.push($(this).val());
    });
    var has_visibility_filter = (visibility_checked && (visibility_checked.length > 0));
    if (has_visibility_filter){
        $("input[name='visibility_codes[]']:checkbox:not(:checked)").each(function () {
            $('.'+ $(this).val() ).hide();
        });
    }

    // funder
    var funder_checked = []
    $("input[name='funder_codes[]']:checkbox:checked").each(function(){
        funder_checked.push($(this).val());
    });
    var has_funder_filter = (funder_checked && (funder_checked.length > 0));
    if (has_funder_filter){
    
        $('')
    
        $("input[name='funder_codes[]']:checkbox:not(:checked)").each(function () {
            $('.'+ $(this).val() ).hide();
        });
        //extra step because a dataset may have multiple funders
        $("input[name='funder_codes[]']:checkbox:checked").each(function(){
            $('.'+ $(this).val() ).show();
        });
    }

    // license
    var license_checked = []
    $("input[name='license_codes[]']:checkbox:checked").each(function(){
        license_checked.push($(this).val());
    });
    var has_license_filter = (license_checked && (license_checked.length > 0));
    if (has_license_filter){
        $("input[name='license_codes[]']:checkbox:not(:checked)").each(function () {
            $('.'+ $(this).val() ).hide();
        });
    }

}

function clearSearchTerm(){
    $("input[name='q']").val("");
    $("#searchForm").submit();
}

$(document).ready(search_ready);
$(document).on('page:load', search_ready);