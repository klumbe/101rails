$(document).on('turbolinks:load', function() {
  $('[data-toggle="popover"]').popover();

  // hide metadata
  var metadata = $('[class="mw-headline"][id="Metadata"]');

  // hide list
  metadata.parent().parent().nextAll("ul").hide();
  metadata.parent().parent().nextAll("p").hide();
  metadata.parent().parent().nextAll("pre").hide();
  metadata.parent().parent().hide();
});

function goBack() {
  if(window.history.length <= 2) {
    window.location.href = '/101project'
  }
  else {
    window.history.back();
  }
}
