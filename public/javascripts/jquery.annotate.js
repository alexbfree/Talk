(function($) {
  $.fn.annotateImage = function(options) {
    // Creates annotations on the given image.
    // Images are loaded from the "getUrl" propety passed into the options.
    var opts = $.extend({}, $.fn.annotateImage.defaults, options);
    var image = this;
    
    this.image = this;
    this.mode = 'view';
    
    // Assign defaults
    this.getUrl = opts.getUrl;
    this.saveUrl = opts.saveUrl;
    this.deleteUrl = opts.deleteUrl;
    this.editable = opts.editable;
    this.useAjax = opts.useAjax;
    this.notes = opts.notes;
    this.markupField = opts.markupField;
    
    // Add the canvas
    this.canvas = $('<div class="image-annotate-canvas"><div class="image-annotate-view"></div><div class="image-annotate-edit"><div class="image-annotate-edit-area"></div></div></div>');
    this.canvas.children('.image-annotate-edit').hide();
    // this.canvas.children('.image-annotate-view').hide();
    this.image.after(this.canvas);
    
    // Give the canvas and the container their size and background
    this.canvas.height(this.height());
    this.canvas.width(this.width());
    this.canvas.css('background-image', 'url("' + this.attr('src') + '")');
    this.canvas.children('.image-annotate-view, .image-annotate-edit').height(this.height());
    this.canvas.children('.image-annotate-view, .image-annotate-edit').width(this.width());
    
    // load the notes
    if (this.useAjax) {
      $.fn.annotateImage.ajaxLoad(this);
    } else {
      $.fn.annotateImage.load(this);
    }
      // Add the "Add a note" button
      if (this.editable) {
        this.button = $('<div><a class="image-annotate-add" id="image-annotate-add" href="#">Add Annotation</a></div>');
        this.button.click(function() {
          $.fn.annotateImage.add(image);
          return false;
        });
        
        this.canvas.after(this.button);
        $('.image-annotate-add').parent().css('width', '120px');
        $('.image-annotate-add').parent().css('margin', '2px auto');
      }
      
      // Hide the original
      this.hide();
      
      return this;
    };
    
    /**
    * Plugin Defaults
    **/
    $.fn.annotateImage.defaults = {
      getUrl:       'your-get.rails',
      saveUrl:      'your-save.rails',
      deleteUrl:    'your-delete.rails',
      editable:     true,
      useAjax:      true,
      notes:        new Array(),
      markupField:  null
    };
    
    $.fn.annotateImage.clear = function(image) {
      // Clears all existing annotations from the image.
      for (var i = 0; i < image.notes.length; i++) {
        if(image.notes[image.notes[i]]) {
          image.notes[image.notes[i]].destroy();
        }
      }
      
      $('.image-annotate-area').remove();
      $('.image-annotate-note').remove();
      
      image.notes = new Array();
    };
    
    $.fn.annotateImage.ajaxLoad = function(image) {
      // Loads the annotations from the "getUrl" property passed in on the options object.
      $.getJSON(image.getUrl + '?ticks=' + $.fn.annotateImage.getTicks(), function(data) {
        image.notes = data;
        $.fn.annotateImage.load(image);
      });
    };
    
    $.fn.annotateImage.load = function(image) {
      // Loads the annotations from the notes property passed in on the options object.
      for (var i = 0; i < image.notes.length; i++) {
        image.notes[image.notes[i]] = new $.fn.annotateView(image, image.notes[i]);
      }
    };
    
    $.fn.annotateImage.getTicks = function() {
      // Gets a count of the ticks for the current date.
      // This is used to ensure that URLs are always unique and not cached by the browser.
      var now = new Date();
      return now.getTime();
    };
    
    $.fn.annotateImage.add = function(image) {
      // Adds a note to the image.
      if (image.mode == 'view') {
        image.mode = 'edit';
        
        // Create/prepare the editable note elements
        var editable = new $.fn.annotateEdit(image);
        
        $.fn.annotateImage.createSaveButton(editable, image);
        $.fn.annotateImage.createCancelButton(editable, image);
        $('#image-annotate-text').focus();
      }
    };
    
    $.fn.annotateImage.createSaveButton = function(editable, image, note) {
      // Creates a Save button on the editable note.
      var ok = $('<a class="image-annotate-edit-ok">OK</a>');
      
      ok.click(function() {
        var form = $('#image-annotate-edit-form form');
        var text = $('#image-annotate-text').val();
        
        if(text.length == 0) {
          return false;
        }
        
        $.fn.annotateImage.appendPosition(form, editable);
        image.mode = 'view';
        
        if(image.markupField) {
          var field = $(image.markupField);
          var params = {};
          
          $.each(form.serialize().split('&'), function(index, param) {
            var split = param.split('=');
            params[split[0]] = split[1];
          });
          params.text = text;
          
          if(note) {
            // update
            $.fn.annotateView.selectNoteMarkup(field, editable.note);
            $.fn.annotateView.insertNoteMarkup(field, params);
          }
          else {
            // new note
            $.fn.annotateView.insertNoteMarkup(field, params);
          }
        }
        
        // Save via AJAX
        if (image.useAjax) {
          $.ajax({
            url:      image.saveUrl,
            data:     form.serialize(),
            error:    function(e) {
              alert("An error occured saving that note.")
            },
            success:  function(data) {
              if (data.annotation_id != undefined) {
                editable.note.id = data.annotation_id;
              }
            },
            dataType: "json"
          });
        }
        
        // Add to canvas
        if (note) {
          note.resetPosition(editable, text);
        } else {
          editable.note.editable = true;
          note = new $.fn.annotateView(image, editable.note)
          note.resetPosition(editable, text);
          image.notes.push(editable.note);
        }
        
        editable.destroy();
        $('.image-annotate-view').show();
      });
        
      editable.form.append(ok);
    };
    
    $.fn.annotateImage.createCancelButton = function(editable, image) {
      // Creates a Cancel button on the editable note.
      var cancel = $('<a class="image-annotate-edit-close">Cancel</a>');
      cancel.click(function() {
        editable.destroy();
        image.mode = 'view';
      });
      
      editable.form.append(cancel);
    };
    
    $.fn.annotateImage.saveAsHtml = function(image, target) {
      var element = $(target);
      var html = "";
      for (var i = 0; i < image.notes.length; i++) {
        html += $.fn.annotateImage.createHiddenField("text_" + i, image.notes[i].text);
        html += $.fn.annotateImage.createHiddenField("top_" + i, image.notes[i].top);
        html += $.fn.annotateImage.createHiddenField("left_" + i, image.notes[i].left);
        html += $.fn.annotateImage.createHiddenField("height_" + i, image.notes[i].height);
        html += $.fn.annotateImage.createHiddenField("width_" + i, image.notes[i].width);
      }
      
      element.html(html);
    };
    
    $.fn.annotateImage.createHiddenField = function(name, value) {
      return '&lt;input type="hidden" name="' + name + '" value="' + value + '" /&gt;<br />';
    };
    
    $.fn.annotateEdit = function(image, note) {
      // Defines an editable annotation area.
      this.image = image;
      
      if (note) {
        this.note = note;
      } else {
        var newNote = new Object();
        newNote.id = "new";
        newNote.top = 30;
        newNote.left = 30;
        newNote.width = 30;
        newNote.height = 30;
        newNote.text = "";
        this.note = newNote;
      }
      
      // Set area
      var area = image.canvas.children('.image-annotate-edit').children('.image-annotate-edit-area');
      this.area = area;
      this.area.css('height', this.note.height + 'px');
      this.area.css('width', this.note.width + 'px');
      this.area.css('left', this.note.left + 'px');
      this.area.css('top', this.note.top + 'px');
      
      // Show the edition canvas and hide the view canvas
      image.canvas.children('.image-annotate-view').hide();
      image.canvas.children('.image-annotate-edit').show();
      
      // Add the note (which we'll load with the form afterwards)
      var form = $('<div id="image-annotate-edit-form"><form><textarea id="image-annotate-text" name="text" rows="3" cols="30">' + this.note.text + '</textarea></form></div>');
      this.form = form;
      
      $('body').append(this.form);
      this.form.css('left', this.area.offset().left + 'px');
      this.form.css('top', (parseInt(this.area.offset().top) + parseInt(this.area.height()) + 7) + 'px');
      this.form.css('z-index', 9999);
      
      area.resizable({
        handles: 'all',
        containment: image,
        resize: function(e, ui) {
          form.css('left', area.offset().left + 'px');
          form.css('top', (parseInt(area.offset().top) + parseInt(area.height()) + 8) + 'px');
        },
        stop: function(e, ui) {
          form.css('left', area.offset().left + 'px');
          form.css('top', (parseInt(area.offset().top) + parseInt(area.height()) + 8) + 'px');
        }
      }).draggable({
        containment: image.canvas,
        drag: function(e, ui) {
          form.css('left', area.offset().left + 'px');
          form.css('top', (parseInt(area.offset().top) + parseInt(area.height()) + 8) + 'px');
        },
        stop: function(e, ui) {
          form.css('left', area.offset().left + 'px');
          form.css('top', (parseInt(area.offset().top) + parseInt(area.height()) + 8) + 'px');
        }
      });
      
      return this;
    };
    
    $.fn.annotateEdit.prototype.destroy = function() {
      // Destroys an editable annotation area.
      this.image.canvas.children('.image-annotate-edit').hide();
      this.area.resizable('destroy');
      this.area.draggable('destroy');
      this.area.css('height', '');
      this.area.css('width', '');
      this.area.css('left', '');
      this.area.css('top', '');
      this.form.remove();
    }
    
    $.fn.annotateView = function(image, note) {
      // Defines a annotation area.
      this.image = image;
      this.note = note;
      this.editable = (note.editable && image.editable);
      
      // Add the area
      this.area = $('<div class="image-annotate-area' + (this.editable ? ' image-annotate-area-editable' : '') + '"><div></div></div>');
      image.canvas.children('.image-annotate-view').prepend(this.area);
      
      // Add the note
      this.form = $('<div class="image-annotate-note">' + note.text + '</div>');
      this.form.hide();
      image.canvas.children('.image-annotate-view').append(this.form);
      this.form.children('span.actions').hide();
      
      // Set the position and size of the note
      this.setPosition();
      
      // Add the behavior: hide/display the note when hovering the area
      var annotation = this;
      this.area.hover(function() {
        annotation.show();
      }, function() {
        annotation.hide();
      });
      
      // Edit a note feature
      if (this.editable) {
        var form = this;
        this.area.click(function() {
          form.edit();
        });
      }
    };
    
    $.fn.annotateView.prototype.setPosition = function() {
      // Sets the position of an annotation.
      this.area.children('div').height((parseInt(this.note.height) - 2) + 'px');
      this.area.children('div').width((parseInt(this.note.width) - 2) + 'px');
      this.area.css('left', (this.note.left) + 'px');
      this.area.css('top', (this.note.top) + 'px');
      this.form.css('left', (this.note.left) + 'px');
      this.form.css('top', (parseInt(this.note.top) + parseInt(this.note.height) + 7) + 'px');
    };
    
    $.fn.annotateView.prototype.show = function() {
      // Highlights the annotation
      this.form.fadeIn(250);
      if (!this.editable) {
        this.area.addClass('image-annotate-area-hover');
      } else {
        this.area.addClass('image-annotate-area-editable-hover');
      }
    };
    
    $.fn.annotateView.prototype.hide = function() {
      // Removes the highlight from the annotation.
      this.form.fadeOut(250);
      this.area.removeClass('image-annotate-area-hover');
      this.area.removeClass('image-annotate-area-editable-hover');
    };
    
    $.fn.annotateView.prototype.destroy = function() {
      // Destroys the annotation.
      this.area.remove();
      this.form.remove();
    }
    
    $.fn.annotateView.prototype.edit = function() {
      // Edits the annotation.
      if (this.image.mode == 'view') {
        this.image.mode = 'edit';
        var annotation = this;
        
        // Create/prepare the editable note elements
        var editable = new $.fn.annotateEdit(this.image, this.note);
        
        $.fn.annotateImage.createSaveButton(editable, this.image, annotation);
        
        // Add the delete button
        var del = $('<a class="image-annotate-edit-delete">Delete</a>');
        del.click(function() {
          var form = $('#image-annotate-edit-form form');
          $.fn.annotateImage.appendPosition(form, editable)
          
          if(annotation.image.markupField) {
            field = $(annotation.image.markupField);
            $.fn.annotateView.removeNoteMarkup(field, editable.note);
          }
          
          if (annotation.image.useAjax) {
            $.ajax({
              url: annotation.image.deleteUrl,
              data: form.serialize(),
              error: function(e) { alert("An error occured deleting that note.") }
            });
          }
          
          annotation.image.mode = 'view';
          editable.destroy();
          annotation.destroy();
          $('.image-annotate-view').show();
        });
        
        editable.form.append(del);
        $.fn.annotateImage.createCancelButton(editable, this.image);
      }
    };
    
    $.fn.annotateView.noteToMarkup = function(note) {
      note.text = note.text.replace(/\#/g, '&#35;');
      note.text = note.text.replace(/\"/g, '\'');
      note.text = note.text.replace(/\(/g, '&#40;');
      note.text = note.text.replace(/\)/g, '&#41;');
      note.text = note.text.replace(/\:/g, '&#58;');
      return '"' + note.text + 
        '":(' + Math.round(parseInt(note.width)) + 'x' + Math.round(parseInt(note.height)) +
        '@' + Math.round(parseInt(note.top)) + ',' + Math.round(parseInt(note.left)) + ')';
    };
    
    $.fn.annotateView.selectNoteMarkup = function(field, note) {
      markup = $.fn.annotateView.noteToMarkup(note);
      start = field.val().indexOf(markup);
      end = start + markup.length;
      field.setSelection(start, end);
    };
    
    $.fn.annotateView.removeNoteMarkup = function(field, note) {
      $.fn.annotateView.selectNoteMarkup(field, note);
      field.replaceSelection('');
    };
    
    $.fn.annotateView.insertNoteMarkup = function(field, note) {
      markup = $.fn.annotateView.noteToMarkup(note);
      
      if(field.getSelection().length == 0) {
        field.insertAtCaretPos(markup);
      }
      else {
        field.replaceSelection(markup);
      }
    };
    
    $.fn.annotateImage.appendPosition = function(form, editable) {
      // Appends the annotations coordinates to the given form that is posted to the server.
      var areaFields = $('<input type="hidden" value="' + editable.area.height() + '" name="height"/>' +
                         '<input type="hidden" value="' + editable.area.width() + '" name="width"/>' +
                         '<input type="hidden" value="' + editable.area.position().top + '" name="top"/>' +
                         '<input type="hidden" value="' + editable.area.position().left + '" name="left"/>' +
                         '<input type="hidden" value="' + editable.note.id + '" name="id"/>');
      form.append(areaFields);
    };
    
    $.fn.annotateView.prototype.resetPosition = function(editable, text) {
      // Sets the position of an annotation.
      this.form.html(text);
      this.form.hide();
      
      // Resize
      this.area.children('div').height(editable.area.height() + 'px');
      this.area.children('div').width((editable.area.width() - 2) + 'px');
      this.area.css('left', (editable.area.position().left) + 'px');
      this.area.css('top', (editable.area.position().top) + 'px');
      this.form.css('left', (editable.area.position().left) + 'px');
      this.form.css('top', (parseInt(editable.area.position().top) + parseInt(editable.area.height()) + 7) + 'px');
      
      // Save new position to note
      this.note.top = editable.area.position().top;
      this.note.left = editable.area.position().left;
      this.note.height = editable.area.height();
      this.note.width = editable.area.width();
      this.note.text = text;
      this.note.id = editable.note.id;
      this.editable = true;
    };
})
(jQuery);
