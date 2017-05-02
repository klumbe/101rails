$(document).on('turbolinks:load', function() {
  $('[data-toggle="popover"]').popover();

  // hide metadata
  var metadata = $('[class="mw-headline"][id="Metadata"]');

  // hide list
  metadata.parent().nextAll("ul").hide();
  metadata.parent().nextAll("p").hide();
  metadata.parent().nextAll("pre").hide();
  metadata.parent().hide();

  $('#pageDeleteButton').click(function() {
    $('#confirm-delete').modal({
      backdrop: 'static',
      keyboard: false
    })
    .one('click', '#delete', function(e) {
      $.ajax({
        url: window.pagePath,
        type: 'DELETE'
      }).done(function(data) {
        if(data.success) {
          window.location.href = '/101project';
        }
        else {
          alert(data.success);
        }
      });
    });
  });

  $('#renamePageButton').click(function() {
    var url = $('#rename-path').data('value');
    $.ajax({
      url: url,
      type: 'PUT',
      data: {
        newTitle: $('#newTitle').val()
      }
    }).done(function(data) {
      window.location.pathname = '/' + data.newTitle;
    })
  });
});
