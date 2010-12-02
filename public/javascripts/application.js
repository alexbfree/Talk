// 
// Oxford Communication Tool
// 
//
var OCT = window.OCT || {};

OCT.tabs = {
  trends      : '#trends-tabs',
  recents      : '#recents-tabs',
  
  init: function () {
    $('#home-tabs').tabs();
    $('#boards-tabs').tabs({ cache: true });
    $(OCT.tabs.trends).tabs({ cache: true });
    $(OCT.tabs.recents).tabs({ cache: true });
  }
};

OCT.collection_hover = {
  init: function() {
    $('.collection-thumbnail').mouseover(function() {
      $('.collection-large').attr("src", $(this).attr("src"));
    });
  }
};

OCT.paginated_collection = {
  init: function () {
    OCT.paginated_collection.list();
  },
  
  list: function() {
    if($(".collection-info .col").length > 0) {
      var new_width = $('.collection-info .col').length * $('.collection-info .col').width();
      $('.collection-info .container').css("width", new_width + "px");
    }
    
    $('.collection-info .nav').html('');
    if($(".collection-info .col").length > 1) {
      // Create dots
      var page = 0;
      $(".collection-info .col").each(function() {
        $('.collection-info .nav').append('<a href="#" id="p-' + page+ '></a>');
        page++;
      });
      
      $('.collection-info .nav a').first().addClass("current");
      // Dot nav
      
      $(".collection-info .nav a").live("click", function() {
        $(".collection-info .nav a").removeClass("current");
        var dot = $(this);
        var leftPosition = 0-(parseInt($(dot).attr("id").split("-")[1])*$(".collection-info .col").width())+"px";
        
        $(".collection-info .container").animate({
          left: leftPosition
        }, function() {
          $(dot).addClass("current");
        });
        
        return false;
      });
      
      OCT.paginated_collection.keybind();
    }
  },
  
  keybind: function() {
    $('*').keyup(function(e) {
      // Next
      
      if (e.keyCode == 39 || e.which == 39) {
        var current = parseInt($(".collection-info .nav a.current").attr("id").split("-")[1]);
        var next = current + 1;
        OCT.paginated_collection.page(next);
      }
      
      // Prev
      if (e.keyCode == 37 || e.which == 37) {
        var current = parseInt($(".collection-info .nav a.current").attr("id").split("-")[1]);
        var previous = current - 1;
        OCT.paginated_collection.page(previous);
      }
    });
  },
  
  page: function(page) {
    if (page >= 0 && page < $(".collection-info .col").length) {
      $(".collection-info .nav a").removeClass("current");
      var leftPosition = 0 - (page * $(".collection-info .col").width()) + "px";
      
      $(".collection-info .container").animate({
        left: leftPosition
      }, function() {
        $("#p-" + page).addClass("current");
      });
    }
  }
};


OCT.loading = {  
  init: function() {
      var toggleLoading = function() { $(".loading").toggle() };
      $(".show-more")
        .bind("ajax:loading",  toggleLoading)
        .bind("ajax:complete", toggleLoading);
  }
}

OCT.button_press = {
  init: function() {
    $('.button').live('mousedown', function() {
      $(this).addClass('pressed');
      return false;
    });
    
    $('.button').live('mouseup, mouseout', function() {
      $(this).removeClass('pressed');
    });
  }
};

OCT.hover = {
    // container : '.short-comment, .comment, .collection-viewer',
    container : '.short-comment, .comment,',
    targets : '.date, .toggle,',
    
    init: function () {
      $(OCT.hover.container).hover(function() {
        $(OCT.hover.targets, this).css('color', '#000000');
      }, function() {
        $(OCT.hover.targets, this).css('color', '#999999');
      });
      
      $(OCT.hover.container).hover(function() {
        $('.toolbar', this).css('visibility', 'visible');
      }, function() {
        $('.toolbar', this).css('visibility', 'hidden');
      });
      
      $(OCT.hover.container).hover(function() {
        $('.name.toggle a', this).css('color', '#990000');
      }, function() {
        $('.name.toggle a', this).css('color', '#999999');
      });
    }
};


OCT.textcount = {
  short_text : '#short-text',
  short_counter : "#short-counter",
  short_max : 140,
  
  init: function() {
    $(OCT.textcount.short_text).live('keydown keyup focus input paste', function() {
      var remaining = OCT.textcount.short_max - $(OCT.textcount.short_text).val().length;
      $(OCT.textcount.short_counter).html(Math.max(remaining, 0));
      $(OCT.textcount.short_text).val($(OCT.textcount.short_text).val().substr(0, OCT.textcount.short_max));
    });
    
    $(OCT.textcount.short_counter).html(OCT.textcount.short_max);
    $(OCT.textcount.short_text).attr("maxlength", OCT.textcount.short_max);
  }
};


OCT.notice = {
  init: function () {
    $('.notice').bind("click", function() {
      $(this).hide();
    });
    setTimeout("$('.notice').fadeOut(1000);", 3000);
    
    $('.alert').bind("click", function() {
      $(this).hide();
    });
    setTimeout("$('.alert').fadeOut(1000);", 5000);
  }
};


OCT.browse = {
  init:function() {
    $.ajax({
      url: '/objects/browse',
      dataType: 'js',
      success: function(response) {
        $('.col1').html(response);
      },
      error: function() {
        $('.col1').html('<div class="engraved">There was a problem getting objects</div>');
      }
    });
    
    // Click on Col 1 | Load discussion
    $('.col1 .item').live('click', function() {
      var type = 'object';
      
      if($(this).hasClass('board')) {
        type ='board';
      }
      else if($(this).hasClass('collection')) {
        type ='collection';
      }
      
      $('.col2').html('<div class="engraved">Loading discussions..</div>');
      $('.col3').html('<div class="engraved">Select a discussion</div>');
      
      $.ajax({
        url: '/discussions/browse',
        data: { id: $(this).attr('id') },
        dataType: 'js',
        success: function(response) {
          $('.col2').html(response);
        },
        error: function() {
          $('.col2').html('<div class="engraved">There was a problem getting ' + type + '</div>');
        }
      });
    });
    
    // Click on discussion | Show comments
    $('.col2 .item').live('click', function() {
      $('.col3').html('<div class="engraved">Loading comments..</div>');
      
      $.ajax({
        url: '/comments/browse',
        data: { id: $(this).attr('id') },
        dataType: 'js',
        success: function(response) {
          $('.col3').html(response);
        },
        error: function() {
          $('.col3').html('<div class="engraved">There was a problem getting comments</div>');
        }
      });
    });
    
    //  TYPE toolbar
    $('.type_toolbar .type').live('click', function() {
      var type = $(this).attr('id');
      var singularized_type = type.substr(0, type.length - 1);
      var humanized_type = type[0].toUpperCase() + type.slice(1);
      var message = 'Select ' + (type == 'objects' ? 'an ' : 'a ') + singularized_type;
      
      $('.browse .titles .focus').html('<div class="engraved">' + humanized_type + '</div>');
      $('.col1').html('<div class="engraved">Loading ' + type + '..</div>');
      $('.col2').html('<div class="engraved">' + message + '</div>');
      $('.col3').html('<div class="engraved"></div>');
      
      $('.type').removeClass('current');
      $(this).addClass('current');
      
      $.ajax({
        url: '/' + type + '/browse',
        dataType: 'js',
        success: function(response) {
          $('.col1').html(response);
        },
        error: function() {
          $('.col1').html('<div class="engraved">There was a problem getting ' + type + '</div>');
        }
      });
    });
  }
};

OCT.home = {
  mode : 'trending',
  
  init: function() {    
    $('.mode_switch a').bind("click", function() {
      if(!$(this).hasClass('current')) {
        OCT.home.mode = $(this).attr("id");
        
        if(this.id == 'recent') {
          $('#comments-or-keywords').removeClass('keywords');
          $('#comments-or-keywords').addClass('comments');
        }
        else {
          $('#comments-or-keywords').removeClass('comments');
          $('#comments-or-keywords').addClass('keywords');
        }
        
        OCT.home.load();
        $('.mode_switch a').removeClass('current');
        $(this).addClass('current');
      }
      
      return false;
    });
    
    /* This looks like it's supposed to show a larger version of the collection image but it's not selecting any dom elements.
       
    $('.film img').live("mouseover", function() {
      $('.large', $(this).parent().parent()).attr("src", $(this).attr("src"));
    });
    */
    
    OCT.home.load();
   },
   
   load: function() {
     var kinds = ['objects', 'collections', 'discussions', (OCT.home.mode == 'recent') ? 'comments' : 'keywords'];
      
     $(kinds).each(function(i, kind) {
       var elem = $('.' + kind + ' .list')[0];
       
       $.ajax({
         url: '/home/' + OCT.home.mode + '_' + kind,
         datakind: 'js',
         success: function(response) {
           $('.' + kind + ' h2').html(kind.toUpperCase());
           $(elem).html(response);
         },
         error: function(response) {
           $('.' + kind + ' h2').html(kind.toUpperCase());
           $(elem).html('<div>Unable to retrieve ' + kind + '</div>');
         }
       });
     });
   }
};

var t;

OCT.menu = {
  init: function() {
    $('.menu').live("mouseover", function() {
      clearTimeout(t);
      $('.menu ul li').css("visibility", "visible");      
    })

    $('.header').live("mouseout", function() {
      t = setTimeout(function(){ $('.menu ul li:not(.main_link)').css("visibility", "hidden");}, 800);          
    })

  }
};

$(document).ready(function(){
    // OCT.tabs.init();
    // OCT.paginated_collection.init();
    OCT.hover.init();
    OCT.loading.init();
    // OCT.textcount.init();
    OCT.notice.init();    
    // OCT.home.init();
    OCT.menu.init();
    OCT.button_press.init();
    $('.highlight_annotations').highlightAnnotations();
    $(".highlight_keywords .body").keywordHighlight();
});

function markitup_preview() {
  $.ajax({
    url: '/comments/markitup_parser',
    data: { data: $('#comment_body').val() || $('#discussion_comments_body').val() },
    type: 'post'
  });
}


// Utility
function clear_input(a){
  myfield = document.getElementById(arguments[0]);
  myfield.value = "";
}

function replace_input(a,b){
  myfield = document.getElementById(arguments[0]);
  if (myfield.value == "") {
   myfield.value = arguments[1];
  }
}

function clear_this(element){
  element.value = "";
}

function replace_this(element){
  if (element.value == ""){
    element.value = "Add a keyword";
  } 
}

/* 
 * @Reply to link helpers
 */

function reply_to(comment_id, author){
  $('.comment-form h2').html('Response to '+ author + '<ul id="cancel-response"><li></li></ul>');
  $('#comment_response_to_id').val(comment_id);
  $('html,body').animate({ scrollTop: $('#new_comment').offset().top }, { duration: 'medium', easing: 'swing'});
  
  $('#cancel-response').click(function() {
    $('.comment-form h2').html('Comment');
    $('#comment_response_to_id').val('');
  });
}

// Collection/live collection form JS
function update_keyword_ands() {
  $('.keyword-filter').each(function(i, elem) {
    if(i < 1) {
      $(elem).children('.keyword-and').remove();
    }
    else if(!$(elem).children('.keyword-and')[0]) {
      $(elem).children('p').before('<span class="keyword-and">AND</span>');
    }
  });
}

function check_collection_type(){
  var prefix = $('.new_collection')[0] == undefined ? 'Edit' : 'New';
  var kind = $('#collection_kind_id').val();
  
  $('.collection-title').html(prefix + ' ' + kind);
  $('#name-label').html('Name of ' + kind.toLowerCase());
  $('#description-label').html('Description of ' + kind.toLowerCase());
  
  if(kind == "Keyword Set") {
    $('#live_collection_form').show();
    update_live_collection_results();
  }
  else {
    $('#live_collection_form').hide();
  }
  
  update_keyword_ands()
}

function remove_keyword_field(field_id) {
  if(keyword_count() > 1) {
    $('#' + field_id).remove();
    update_live_collection_results();
  }
  
  $('.keyword-filter').each(function(i, elem) {
    var counter = i + 1;
    $(elem).children('input').attr({ id: 'keyword_' + counter, name: 'keyword[' + counter + ']' });
    $(elem).attr('id', 'keyword_' + counter + '_wrapper');
    
    var remove_link = $(elem).children('a:last');
    remove_link.unbind();
    remove_link.bind('click', function() {
      remove_keyword_field('keyword_' + counter + '_wrapper');
      return false;
    });
  });
  
  update_keyword_ands()
}

function add_keyword_field(){
  var last = keyword_count();
  count = last + 1;
  var keyword_field = '<div id="keyword_' + count + '_wrapper" class="keyword-filter">' +
                        '<p id="keyword-label" class="label">Include objects with keyword</p>' +
                        '<input class="keyword" id="keyword_' + count + '" name="keyword[' + count + ']" size="30" type="text" />' +
                        '&nbsp;<a href="#" onclick="add_keyword_field(); return false;" title="Add another keyword">' +
                          '<img width="13" height="13" src="/images/icons/add.png" alt="Add" />' +
                        '</a>' +
                        '&nbsp;<a href="#" title="Remove this keyword">' +
                          '<img width="13" height="13" src="/images/icons/cancel.png" alt="Cancel" />' +
                        '</a>' +
                      '</div>';
                      
  $('#keyword_' + last + '_wrapper').after(keyword_field);
  $('#keyword_' + last + '_wrapper').children('a:last').bind('click', function() {
    remove_keyword_field('keyword_' + count + '_wrapper');
    return false;
  });
  
  update_keyword_ands()
}

function keyword_count() {
  return $('.keyword').length;
}

function update_live_collection_results() {
  var keywords = new Array();
  $('.keyword').each(function() {
    keywords.push($(this).val());
  });
  
  $.ajax({
     type: "POST",
     url: "/search/live_collection_results",
     data: "keywords=" + keywords.join(',')
   });
}