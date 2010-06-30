$(function() {
  
  if (typeof slug !== "undefined" && slug !== null ) {
    
    $("input#share_url").click(function() {$(this).select()});
    
    if (entityCount == 0) {
      $("div#extracted_entities").hide();
    }
    
    var doneStatus = "Contributors Identified";
    var ranEntitiesExtracted = false;
    var ranEntitiesLinked = false;
    var ranContributorsIdentified = false;
    
    if (resultStatus != doneStatus) {
      $("img#spinner").show();
      var intervalId = setInterval(function() { 
        $.getJSON(slug + '.json', function(result) {
                    
          // break the loop if done
          if (result.status == doneStatus) {
            $("img#spinner").hide();
            clearInterval(intervalId);
          }
          
          if (ranEntitiesExtracted == false) {
            ranEntitiesExtracted = entitiesExtracted(result);
          }
          
          if (ranEntitiesExtracted == true && ranEntitiesLinked == false) {
            ranEntitiesLinked = entitiesLinked(result);
          }

          if (ranEntitiesLinked == true && ranContributorsIdentified == false) {
            ranContributorsIdentified = contributorsIdentified(result);
          }
        })
      }, 2000);
    }
  }
  
});

var entitiesExtracted = function(result, processedStatus) {
  var showTable = false
  if (result.status == "Entities Extracted" && !_(result.entities).isEmpty()) {
    
    // populate the entities table
    _(result.entities).each(function(e) {
      $("div#extracted_entities ul").append('<li>' + e.name  + '</li>');
      showTable = true;
    });
    if (showTable) {
      $("div#extracted_entities").show();
    }
    return true;
  } else {
    return false;
  }
}

var entitiesLinked = function(result, processedStatus) {
  if ((result.status == "Entities Linked" || result.status == "Contributors Identified") && !_(result.entities).isEmpty()) {

    // highlight the source text
    $("div#source_content").highlight(_(result.entities).map(
                                        function(e) { 
                                          if (e.tdata_id) {
                                            return e.name;
                                          } else {
                                            return "";
                                          }
                                         }));
    
    // link to Influence Explorer
    _(result.entities).each(function(e) {

      if (e.tdata_id) {
        $("div#extracted_entities ul li:contains('" + e.name  + "')").replaceWith("<li>" + influence_explorer_url(e) + "</li>");
      } else {
        $("div#extracted_entities ul li:contains('" + e.name  + "')").remove();
      }
      
    });
    return true;
  } else {
    return false;
  }
}

var contributorsIdentified = function(result, processedStatus) {
  var showReport = false;
  if (result.status == "Contributors Identified" && !_(result.entities).isEmpty()) {
    
    // list all contributor/recipient relationships
    _(result.entities).each(function(e) {
      if (e.contributors) {
        _(e.contributors).each(function(contributor) {
          $("div#contribution_report ul").append('<li>' + influence_explorer_url(contributor) + 
                                                 ' has donated $' +  commafy(contributor.amount) +
                                                 ' to ' + influence_explorer_url(e) + '</li>');
          showReport = true;
        });
      }
    });
    if (showReport) {
      $("div#contribution_report").show();
    }
    return true;
  } else {
    return false;
  }
}

var influence_explorer_url = function(entity) {
  return '<a href="http://brisket.transparencydata.com/' + entity.tdata_type + 
         '/' + entity.tdata_slug + '/' + entity.tdata_id + '">' + entity.name +'</a>'
}

var commafy = function(amount) {
  amount += '';
  arr = amount.split('.');
  dollars = arr[0];
  cents = arr.length > 1 ? '.' + arr[1] : '';
  var rgx = /(\d+)(\d{3})/;
  while (rgx.test(dollars)) {
    dollars = dollars.replace(rgx, '$1' + ',' + '$2');
  }
  return dollars + cents;
}