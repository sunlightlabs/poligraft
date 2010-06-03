$(function() {
  
  if (typeof slug !== "undefined" && slug !== null ) {
    
    $("input#share_url").click(function() {$(this).select()});
    
    if (entityCount == 0) {
      $("div#extracted_entities").hide();
    }

    var intervalId = setInterval(function() { 
      $.getJSON(slug + '.json',
      function(result) {
        
        if (result.status == "Entities Extracted") {
          clearInterval(intervalId);
        }
        
        entitiesExtracted(result);
        
      })
    }, 2000);

  }
  
});

var entitiesExtracted = function(result) {
  if (result.status == "Entities Extracted" && !_(result.entities).isEmpty()) {
    console.log(result);
    $("div#source_content").highlight(_(result.entities).map(
                                        function(e){ return e.name; }));
    

  }
}