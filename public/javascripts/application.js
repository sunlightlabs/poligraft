(function($, undefined){
  $(function(){
    if (window.slug){

      var doneStatus = "Contributors Identified",
          timeout = null,
          pollWidget = function(){
            if (resultStatus == doneStatus) return;
            if (timeout) clearTimeout(timeout);
            $('#report').load(slug + '/widget', function(html, status) {
              if (resultStatus != doneStatus) {
                if (resultStatus == 'Entities Linked') initializeHighlights();
                timeout = setTimeout(pollWidget, 2000);
              } else {
                $("#processingBar").slideUp();
                initializeHighlights();
                // location.hash = 'done';
              }
            });
          },
          initializeHighlights = function() {
            // only highlight once
            if($("#source_content span.highlight").length) return false;

            var entities = [];
            $('#extracted_entities [data-matches]').each(function(){
              entities.push(JSON.parse($(this).attr('data-matches')));
            });
            $("#source_content").highlight(_.flatten(entities));
            $("#source_content span.highlight").attr("data-entity", function() { return _.slugify($(this).text()); });
          },
          triggerHighlights = function() {
            var mySpan = $(this);
            $("#rtColumn a[data-entity*='" + $(this).attr('data-entity') + "']").each(function() {
              mySpan.effect("transfer", { to: $(this) }, 1000);
            });
          };

      $("input#share_url").click(function() {$(this).select()});

      $("#source_content").delegate("span.highlight", "click", triggerHighlights);

      if (entityCount == 0) {
        $("div#extracted_entities").hide();
      }

      if(window.resultStatus != doneStatus){
        pollWidget();
        $('#processingBar').fadeIn('slow');
      }

    }
  });
})(jQuery);
