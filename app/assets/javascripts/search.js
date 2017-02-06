// work-around turbo links to trigger ready function stuff on every page.

var search_ready;
search_ready = function () {

    var hasQueryString = window.location.href.includes("?");

    var selectedPublicationStates = [];
    var selectedLicenses = [];
    var selectedMineOrNot = [];
    var filterCount = 0;
    
    if (hasQueryString) {
        var queryElements = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
        $.each(queryElements, function( index, queryElement) {
            queryElementSplit = queryElement.split('=');
            if (queryElementSplit.length > 1){
                
                filterCount += 1;
                
                switch(queryElement[0]){
                    case 'publication_state':
                        selectedPublicationStates.push(queryElement[1]);
                    case 'license':
                        selectedLicenses.push(queryElement[1]);
                    case 'mine_or_not':
                        selectedMineOrNot.push(queryElement[1]);

                }
            } else {
                console.log(queryElementSplit[0]);
            }
        });
    }
    
    if (filterCount > 0) {

        //console.log("Filter Count: " +_filterCount);

        $(".checkFacetGroup").prop("checked",false);

        selectedPublicationStates.each(function () {
            $(".pubstate_" + $(this).val()).prop("checked", true);
        });

        selectedLicenses.each(function () {
            $(".license_" + $(this).val()).prop("checked", true);
        });

        selectedMineOrNot.each(function () {
            $(".mine_or_not_" + $(this).val()).prop("checked", true);
        });

        handleFilterChange();
        
    } else {
        showAllSearchResults();
    }


    // alert("search.js javascript working");
}

// function getUrlVars()
// {
//     var vars = [], hash;
//     var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
//     for(var i = 0; i < hashes.length; i++)
//     {
//         hash = hashes[i].split('=');
//         vars.push(hash[0]);
//         vars[hash[0]] = hash[1];
//     }
//     return vars;
// }

function showAllSearchResults(){
    $(".checkFacetGroup").prop("checked",true);
    $(".hit").show();
}

function handleFilterChange(){
    
    $('.hit').show();
    
   $(".checkFacetGroup:not(:checked)").each(function() {
       $( "."+$(this).val() ).hide();
   });

    $(".license_facet:not(:checked)").each(function() {
        $( ".unselected" ).hide();
    });

}

function clearSearchTerm(){
    $("input[name='q']").val("");
    $("#searchForm").submit();
}

$(document).ready(search_ready);
$(document).on('page:load', search_ready);