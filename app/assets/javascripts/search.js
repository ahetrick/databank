// work-around turbo links to trigger ready function stuff on every page.

var search_ready;
search_ready = function () {

    handleFilterChange();
    // alert("search.js javascript working");
}

function clearFilters(){
    $(".checkFacetGroup").prop("checked",false);
    $("#searchForm").submit();
    //$(".hit").show();
}

function handleFilterChange(){
    
    $('.hit').show();

    //TODO: hide things that should be hidden


}

function clearSearchTerm(){
    $("input[name='q']").val("");
    $("#searchForm").submit();
}

$(document).ready(search_ready);
$(document).on('page:load', search_ready);