window.POLIGRAFT || (POLIGRAFT = {});
(function($, undefined){
  var app = window.POLIGRAFT;
  app.highlight || (app.highlight = '#source_content');
  $(function(){
    if (app.slug){

      var doneStatus = "Contributors Identified",
          timeout = null,
          tries = 0,
          pollWidget = function(){
            if (app.resultStatus == doneStatus) return;
            if (timeout) clearTimeout(timeout);
            $('#poligraftReport').load(app.slug + '/widget', function(html, status) {
              if (app.resultStatus != doneStatus && tries < 20) {
                if (app.resultStatus == 'Entities Linked') initializeHighlights();
                tries ++;
                timeout = setTimeout(pollWidget, 2000);
              } else {
                $("#poligraftProcessingBar").slideUp();
                initializeHighlights();
                // location.hash = 'done';
              }
            });
          },
          initializeHighlights = function() {
            // only highlight once
            if($("span.highlight").length) return false;

            var entities = [];
            $('#poligraft_extracted_entities [data-matches]').each(function(){
              entities.push(JSON.parse($(this).attr('data-matches')));
            });
            $(app.highlight).highlight(_.flatten(entities));
            $(app.highlight + " span.highlight")
              .attr("data-entity", function() { return _.slugify($(this).text()); });
          },
          triggerHighlights = function() {
            var mySpan = $(this);
            $('#poligraft_contribution_report, #poligraft_extracted_entities')
              .find("a[data-entity*='" + $(this).attr('data-entity') + "']")
              .each(function() {
                mySpan.effect("transfer", { to: $(this) }, 1000);
              });
          };

      $("input#poligraftShareUrl").click(function() {$(this).select()});

      $(app.highlight).delegate("span.highlight", "click", triggerHighlights);

      if (app.entityCount == 0) {
        $("div#poligraftExtractedEntities").hide();
      }

      if(app.resultStatus != doneStatus){
        pollWidget();
        $('#poligraftProcessingBar').fadeIn('slow');
      }

      initializeHighlights();

    }
  });
})(jQuery);
