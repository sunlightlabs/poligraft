$(function() {
  
  if (typeof slug !== "undefined" && slug !== null ) {
    
    $("input#share_url").click(function() {$(this).select()});
    
    if (entityCount == 0) {
      $("div#extracted_entities").hide();
    }
    
    var doneStatus = "Finished Processing";
    var ranEntitiesExtracted = false;
    var ranEntitiesLinked = false;
    
    if (resultStatus != doneStatus) {
      var intervalId = setInterval(function() { 
        $.getJSON(slug + '.json', function(result) {
          
          $("div#status p em").text(result.status);
          
          // break the loop if done
          if (result.status == doneStatus) {
            clearInterval(intervalId);
          }
          
          if (ranEntitiesExtracted == false) {
            ranEntitiesExtracted = entitiesExtracted(result);
          }
          
          if (ranEntitiesLinked == false) {
            ranEntitiesLinked = entitiesLinked(result);
          }
        })
      }, 2000);
    }
  }
  
});

var entitiesExtracted = function(result, processedStatus) {
  if (result.status == "Entities Extracted" && !_(result.entities).isEmpty()) {
    
    // highlight the source text
    $("div#source_content").highlight(_(result.entities).map(
                                        function(e){ return e.name; }));
    
    // populate the entities table
    _(result.entities).each(function(e) {
      $("div#extracted_entities table").append('<tr><td>' + e.name  + '</td><td>'
                                            + e.entity_type + '</td></tr>');
    });
    $("div#extracted_entities").show();
    return true;
  } else {
    return false;
  }
}

var entitiesLinked = function(result, processedStatus) {
  if (result.status == "Entities Linked" && !_(result.entities).isEmpty()) {
    
    // link to Influence Explorer
    _(result.entities).each(function(e) {
      
      if (e.tdata_id) {
        $("td:contains('" + e.name  + "')").replaceWith('<td><a href="' +
        'http://brisket.transparencydata.com/' + e.tdata_type + '/' + e.tdata_slug +
        '/' + e.tdata_id + '">' + e.name +'</a></td>');
      }
    });
    return true;
  } else {
    return false;
  }
}