"use strict";

var $ = require('jquery'),
    _ = require('underscore'),
    Backbone = require('backbone'),
    models = require('../models'),
    FormView = require('./FormView'),
    Alpaca = require('../vendor/alpaca'),
    ace = require('brace');

require('brace/mode/javascript');
require('brace/theme/textmate');

require('jquery-ui/draggable');
require('jquery-ui/droppable');

var setup = function(formData) {
  //Alpaca.logLevel = Alpaca.DEBUG;

  var MODAL_VIEW = "bootstrap-edit-horizontal";
  //var MODAL_VIEW = "bootstrap-edit";

  var MODAL_TEMPLATE = require('../templates/modal.ejs')();

  var data = formData.data,
      schema = formData.schema,
      options = formData.options;

  var prettyJSON = function(obj) {
    return JSON.stringify(obj , null, "  ");
  };

  var sourceRefresh = function(form) {
    console.log('form change');

    var config,
        cursor = editor1.getCursorPosition();
    try {
      config = JSON.parse(editor1.getValue());
    } catch (ex) {
      rtProcessing = false;
      return;
    }
    config.data = form.getValue();
    editor1.setValue(prettyJSON(config), -1);

    setTimeout(function() {
      console.log('cleanup');
      rtProcessing = rtChange = false;
      editor1.gotoLine(cursor.row, cursor.column);
    }, 50);
  };

  var setupEditor = function(id, json) {
    var text = "";
    if (json) { text = prettyJSON(json); }

    var editor = ace.edit(id);
    editor.setTheme("ace/theme/textmate");
    editor.getSession().setMode("ace/mode/javascript");
    editor.renderer.setHScrollBarAlwaysVisible(false);
    editor.setShowPrintMargin(false);
    editor.setValue(text, -1);

    return editor;
  };

  var setSourceHeight = function() {
    $('#source').height(
      $(window).height() - $('#source').parent().offset().top
    );
  };

  setSourceHeight();
  var editor1 = setupEditor("schema", formData);
  $(window).resize(setSourceHeight);

  var mainViewField = null;
  var mainPreviewField = null;
  var mainDesignerField = null;

  var doRefresh = function(el, buildInteractionLayers, disableErrorHandling, cb) {
    try {
      formData = JSON.parse(editor1.getValue());
      schema = formData.schema;
      options = formData.options;
      data = formData.data;
    }
    catch (e) { }

    if (schema) {
      var config = { "schema": schema };
      if (options) { config.options = options; }
      if (data) { config.data = data; }
      if (!config.options) { config.options = {}; }

      config.options.focus = false;
      config.postRender = function(form) {
        if (buildInteractionLayers) {
          var iCount = 0;

          // cover every control with an interaction layer
          form.getFieldEl().find(".alpaca-container-item").each(function() {

            var alpacaFieldId = $(this).children().first().attr("data-alpaca-field-id");

            //iCount++;
            $(this).attr("icount", iCount);

            var width = $(this).outerWidth() - 2;
            var height = $(this).outerHeight() + 25;

            // cover div
            var cover = $("<div></div>");
            $(cover).addClass("cover");
            $(cover).attr("alpaca-ref-id", alpacaFieldId);
            $(cover).css({
              "position": "absolute",
              "margin-top": "-" + height + "px",
              "margin-left": "-10px",
              "width": width,
              "height": height + 10,
              "opacity": 0,
              "background-color": "white",
              "z-index": 900
            });
            $(cover).attr("icount-ref", iCount);
            $(this).append(cover);

            // interaction div
            var interaction = $("<div class='interaction'></div>");
            var buttonGroup = $("<div class='btn-group pull-right'></div>");
            var schemaButton = $('<button class="btn btn-default btn-xs button-schema" alpaca-ref-id="' + alpacaFieldId + '"><i class="glyphicon glyphicon-list"></i></button>');
            var optionsButton = $('<button class="btn btn-default btn-xs button-options" alpaca-ref-id="' + alpacaFieldId + '"><i class="glyphicon glyphicon-wrench"></i></button>');
            var removeButton = $('<button class="btn btn-danger btn-xs button-remove" alpaca-ref-id="' + alpacaFieldId + '"><i class="glyphicon glyphicon-remove"></i></button>');

            buttonGroup
              .append(schemaButton)
              .append(optionsButton)
              .append(removeButton)
              .css({ "margin": "5px" });

            interaction
              .append(buttonGroup)
              .append("<div style='clear:both'></div>")
              .addClass("interaction")
              .attr("alpaca-ref-id", alpacaFieldId)
              .css({
                "position": "absolute",
                "margin-top": "-" + height + "px",
                "margin-left": "-10px",
                "width": width,
                "height": height + 10,
                "opacity": 1,
                "z-index": 901,
                "cursor": "move"
              })
              .attr("icount-ref", iCount);

            $(this).append(interaction);
            schemaButton.off().click(function(e) {
              e.preventDefault();
              e.stopPropagation();

              var alpacaId = $(this).attr("alpaca-ref-id");
              editSchema(alpacaId);
            });
            optionsButton.off().click(function(e) {
              e.preventDefault();
              e.stopPropagation();

              var alpacaId = $(this).attr("alpaca-ref-id");
              editOptions(alpacaId);
            });
            removeButton.off().click(function(e) {
              e.preventDefault();
              e.stopPropagation();

              var alpacaId = $(this).attr("alpaca-ref-id");
              removeField(alpacaId);
            });

            // when hover, highlight
            interaction.hover(function(e) {
              var iCount = $(interaction).attr("icount-ref");
              $(".cover[icount-ref='" + iCount + "']").addClass("ui-hover-state");
            }, function(e) {
              var iCount = $(interaction).attr("icount-ref");
              $(".cover[icount-ref='" + iCount + "']").removeClass("ui-hover-state");
            });

            iCount++;
          });

          // add dashed
          form.getFieldEl().find(".alpaca-container .alpaca-container").addClass("dashed");
          form.getFieldEl().find(".alpaca-container .alpaca-container-item").addClass("dashed");

          // for every container, add a "first" drop zone element
          // this covers empty containers as well as 0th index insertions
          form.getFieldEl().find(".alpaca-container").each(function() {
            var containerEl = this;

            // first insertion point
            $(containerEl).children(".alpaca-container-item").first().each(function() {
              $(this).before("<div class='dropzone'></div>");
            });

            // all others
            $(containerEl).children(".alpaca-container-item").each(function() {
              $(this).after("<div class='dropzone'></div>");
            });

          });

          form.getFieldEl().find(".dropzone").droppable({
            "tolerance": "touch",
            "drop": function( event, ui ) {

              var draggable = $(ui.draggable),
                  nextItemContainer, nextField;
              if (draggable.hasClass("form-element")) {
                var dataType = draggable.attr("data-type");
                var fieldType = draggable.attr("data-field-type");

                // based on where the drop occurred, figure out the previous and next Alpaca fields surrounding
                // the drop target

                // previous
                var previousField = null;
                var previousFieldKey = null;
                var previousItemContainer = $(event.target).prev();
                if (previousItemContainer) {
                  var previousAlpacaId = $(previousItemContainer).children().first().attr("data-alpaca-field-id");
                  previousField = Alpaca.fieldInstances[previousAlpacaId];

                  previousFieldKey = $(previousItemContainer).attr("data-alpaca-container-item-name");
                }

                // next
                nextField = null;
                var nextFieldKey = null;
                nextItemContainer = $(event.target).next();
                if (nextItemContainer) {
                  var nextAlpacaId = $(nextItemContainer).children().first().attr("data-alpaca-field-id");
                  nextField = Alpaca.fieldInstances[nextAlpacaId];

                  nextFieldKey = $(nextItemContainer).attr("data-alpaca-container-item-name");
                }

                // parent field
                var parentFieldAlpacaId = $(event.target).parent().parent().attr("data-alpaca-field-id");
                var parentField = Alpaca.fieldInstances[parentFieldAlpacaId];

                // now do the insertion
                insertField(schema, options, data, dataType, fieldType, parentField, previousField, previousFieldKey, nextField, nextFieldKey);
              } else {
                var draggedIndex = $(draggable).find('.interaction').attr("icount-ref");

                // next
                nextItemContainer = $(event.target).next();
                var nextItemContainerIndex = $(nextItemContainer).attr("data-alpaca-container-item-index");
                var nextItemAlpacaId = $(nextItemContainer).children().first().attr("data-alpaca-field-id");
                nextField = Alpaca.fieldInstances[nextItemAlpacaId];

                form.moveItem(draggedIndex, nextItemContainerIndex, false, function() {
                  regenerate(findTop(nextField));
                });
              }

            },
            "over": function (event, ui ) {
              $(event.target).addClass("dropzone-hover");
            },
            "out": function (event, ui) {
              $(event.target).removeClass("dropzone-hover");
            }
          });

          // init any in-place draggables
          form.getFieldEl().find(".interaction").each(function() {
            $(this).parent().draggable({
              "handle": ".interaction",
              "appendTo": "body",
              "helper": draggableClone,
              "scroll": true,
              "zIndex": 1000,
              "refreshPositions": true,
              "start": draggableStart,
              "stop": draggableStop
            });
          });
        }

        cb(null, form);
      };
      config.error = function(err)
      {
        Alpaca.defaultErrorCallback(err);

        cb(err);
      };

      if (disableErrorHandling) {
        Alpaca.defaultErrorCallback = function(error) {
          console.log(error);
          $('.message')
            .html('<div class="alert alert-danger" role="alert">' + error.message + '</div>');
          console.log("Alpaca encountered an error while previewing form -> " + error.message);
        };
      } else {
        Alpaca.defaultErrorCallback = Alpaca.DEFAULT_ERROR_CALLBACK;
      }
      $('.message').empty();
      $(el).alpaca(config);
    }
  };

  var editSchema = function(alpacaFieldId, callback) {
    var field = Alpaca.fieldInstances[alpacaFieldId];

    var fieldSchema = field.getSchemaOfSchema();
    var fieldSchemaOptions = field.getOptionsForSchema();
    var fieldData = field.schema;

    delete fieldSchema.title;
    delete fieldSchema.description;
    if (fieldSchema.properties) {
      delete fieldSchema.properties.title;
      delete fieldSchema.properties.description;
      delete fieldSchema.properties.dependencies;
    }
    var fieldConfig = { schema: fieldSchema };
    if (fieldSchemaOptions) { fieldConfig.options = fieldSchemaOptions; }
    if (fieldData) { fieldConfig.data = fieldData; }
    fieldConfig.view = {
      "parent": MODAL_VIEW,
      "displayReadonly": false
    };
    fieldConfig.postRender = function(control) {
      var modal = $(MODAL_TEMPLATE.trim());
      modal.find(".modal-title").append(field.getTitle());
      modal.find(".modal-body").append(control.getFieldEl());

      modal.find('.modal-footer').append("<button class='btn btn-primary pull-right okay' data-dismiss='modal' aria-hidden='true'>Okay</button>");
      modal.find('.modal-footer').append("<button class='btn btn-default pull-left' data-dismiss='modal' aria-hidden='true'>Cancel</button>");

      $(modal).modal({
        "keyboard": true
      });

      $(modal).find(".okay").click(function() {

        field.schema = control.getValue();

        var top = findTop(field);
        regenerate(top);

        if (callback) { callback(); }
      });

      control.getFieldEl().find("p.help-block").css({
        "display": "none"
      });
    };

    var x = $("<div><div class='fieldForm'></div></div>");
    $(x).find(".fieldForm").alpaca(fieldConfig);
  };

  var editOptions = function(alpacaFieldId, callback) {
    var field = Alpaca.fieldInstances[alpacaFieldId];

    var fieldOptionsSchema = field.getSchemaOfOptions();
    var fieldOptionsOptions = field.getOptionsForOptions();
    var fieldOptionsData = field.options;

    delete fieldOptionsSchema.title;
    delete fieldOptionsSchema.description;
    if (fieldOptionsSchema.properties) {
      delete fieldOptionsSchema.properties.title;
      delete fieldOptionsSchema.properties.description;
      delete fieldOptionsSchema.properties.dependencies;
      delete fieldOptionsSchema.properties.readonly;
    }
    if (fieldOptionsOptions.fields) {
      delete fieldOptionsOptions.fields.title;
      delete fieldOptionsOptions.fields.description;
      delete fieldOptionsOptions.fields.dependencies;
      delete fieldOptionsOptions.fields.readonly;
    }

    var fieldConfig = { schema: fieldOptionsSchema };
    if (fieldOptionsOptions) { fieldConfig.options = fieldOptionsOptions; }
    if (fieldOptionsData) { fieldConfig.data = fieldOptionsData; }
    fieldConfig.view = {
      "parent": MODAL_VIEW,
      "displayReadonly": false
    };
    fieldConfig.postRender = function(control) {
      var modal = $(MODAL_TEMPLATE.trim());
      modal.find(".modal-title").append(field.getTitle());
      modal.find(".modal-body").append(control.getFieldEl());

      modal.find('.modal-footer').append("<button class='btn btn-primary pull-right okay' data-dismiss='modal' aria-hidden='true'>Okay</button>");
      modal.find('.modal-footer').append("<button class='btn btn-default pull-left' data-dismiss='modal' aria-hidden='true'>Cancel</button>");

      $(modal).modal({
        "keyboard": true
      });

      $(modal).find(".okay").click(function() {

        field.options = control.getValue();

        var top = findTop(field);
        regenerate(top);

        if (callback) { callback(); }
      });

      control.getFieldEl().find("p.help-block").css({
        "display": "none"
      });
    };

    var x = $("<div><div class='fieldForm'></div></div>");
    $(x).find(".fieldForm").alpaca(fieldConfig);
  };

  var refreshView = function(callback) {
    if (mainViewField) {
      mainViewField.getFieldEl().replaceWith("<div id='viewDiv'></div>");
      mainViewField.destroy();
      mainViewField = null;
    }

    doRefresh($("#viewDiv"), false, false, function(err, form) {

      if (!err) { mainViewField = form; }

      if (callback) { callback(); }

    });
  };

  var refreshPreview = function(callback) {
    if (mainPreviewField) {
      mainPreviewField.destroy();
      mainPreviewField = null;
    }

    doRefresh($("#previewDiv"), false, false, function(err, form) {
      if (!err) {
        mainPreviewField = form;

        $("#previewDiv :input[name]").change(function() {
          sourceRefresh(form);
        });
      }

      if (callback) { callback(); }
    });
  };

  var refreshDesigner = function(callback) {
    $(".dropzone").remove();
    $(".interaction").remove();
    $(".cover").remove();

    if (mainDesignerField) {
      mainDesignerField.getFieldEl().replaceWith("<div id='designerDiv'></div>");
      mainDesignerField.destroy();
      mainDesignerField = null;
    }

    doRefresh($("#designerDiv"), true, false, function(err, form) {
      if (!err) { mainDesignerField = form; }

      if (callback) { callback(); }

    });
  };

  var refreshCode = function(callback) {
    var json = { "schema": schema };
    if (options) { json.options = options; }
    if (data) { json.data = data; }

    if (callback) { callback(); }
  };

  var refresh = function(callback) {
    $("UL.nav.nav-tabs LI.active A.tab-item").click();
  };

  var rtChange = false;
  editor1.on("change", function() {
    console.log('change');
    rtChange = true;
  });

  // background "thread" to detect changes and update the preview div
  var rtProcessing = false;
  var rtFunction = function() {
    if (rtChange && rtProcessing) {
      console.log('change blocked');
    } else if (rtProcessing) {
      console.log('process running');
    }
    if (rtChange && !rtProcessing) {
      console.log('rtProcessing');
      rtProcessing = true;

      try {
        JSON.parse(editor1.getValue());
      } catch (ex) {
        console.log('bad json');
        // editor content is bad. bail
        rtProcessing = rtChange = false;
        setTimeout(rtFunction, 1000);
        return;
      }

      if (mainPreviewField) {
        data = mainPreviewField.getValue();
        mainPreviewField.destroy();
        mainPreviewField = null;
      }
      doRefresh($("#previewDiv"), false, true, function(err, form) {

        if (!err) {
          mainPreviewField = form;

          $("#previewDiv :input[name]").change(function() {
            rtProcessing = true;
            sourceRefresh(form);
          });

        }

        rtChange = false;
        rtProcessing = false;
      });
    }

    setTimeout(rtFunction, 1000);

  };
  rtFunction();

  var isCoreField = function(type) {
    var cores = ["any", "array", "checkbox", "file", "hidden", "number", "object", "radio", "select", "text", "textarea"];

    var isCore = false;
    for (var i = 0; i < cores.length; i++) {
      if (cores[i] === type) { isCore = true; }
    }

    return isCore;
  };

  // types
  var types = [{
    "type": "string",
    "title": "String",
    "description": "A textual property"
  }, {
    "type": "number",
    "title": "Number",
    "description": "A numerical property"
  }, {
    "type": "boolean",
    "title": "Boolean",
    "description": "A true/false property"
  }, {
    "type": "object",
    "title": "Object",
    "description": "A collection of keyed sub-properties"
  }, {
    "type": "array",
    "title": "Array",
    "description": "An array of sub-properties"
  }];
  for (var i = 0; i < types.length; i++) {
    var title = types[i].title;
    var type = types[i].type;
    var description = types[i].description;

    var div = $("<div class='form-element draggable ui-widget-content' data-type='" + type + "'></div>");
    $(div).append("<div><span class='form-element-title'>" + title + "</span> (<span class='form-element-type'>" + type + "</span>)</div>");
    $(div).append("<div class='form-element-field-description'>" + description + "</div>");

    $("#types").append(div);
  }

  var draggableStart = function(event, ui) {
    $(".dropzone").addClass("dropzone-highlight");
  };
  var draggableStop  = function(event, ui) {
    $(".dropzone").removeClass("dropzone-highlight dropzone-hover");
  };
  var draggableClone = function() {
    var $orig = $(this);
    var $clone = $orig.clone();
    $clone.css({
      'height': $orig.outerHeight() + 'px',
      'width': $orig.outerWidth() + 'px',
      'opacity': '0.6'
    });
    return $clone;
  };

  var afterAlpacaInit = function() {
    // show all fields
    for (var type in Alpaca.fieldClassRegistry) {
      var instance = new Alpaca.fieldClassRegistry[type]();

      var schemaSchema = instance.getSchemaOfSchema();
      var schemaOptions = instance.getOptionsForSchema();
      var optionsSchema = instance.getSchemaOfOptions();
      var optionsOptions = instance.getOptionsForOptions();
      var title = instance.getTitle();
      var description = instance.getDescription();
      type = instance.getType();
      var fieldType = instance.getFieldType();

      var div = $("<div class='form-element draggable ui-widget-content' data-type='" + type + "' data-field-type='" + fieldType + "'></div>");
      $(div).append("<div><span class='form-element-title'>" + title + "</span> (<span class='form-element-type'>" + fieldType + "</span>)</div>");
      $(div).append("<div class='form-element-field-description'>" + description + "</div>");

      var isCore = isCoreField(fieldType);
      if (isCore) {
        $("#basic").append(div);
      } else {
        $("#advanced").append(div);
      }

      // init all of the draggable form elements
      $(".form-element").draggable({
        "appendTo": "body",
        "helper": draggableClone,
        "zIndex": 1000,
        "refreshPositions": true,
        "start": draggableStart,
        "stop": draggableStop
      });
    }
  };

  // lil hack to force compile
  $("<div></div>").alpaca({
    "data": "test",
    "postRender": function(control) { afterAlpacaInit(); }
  });


  $(".tab-item-source").click(function() {

    // we have to monkey around a bit with ACE Editor to get it to refresh
    editor1.setValue(editor1.getValue(), -1);

    setTimeout(function() {
      refreshPreview();
    }, 50);
  });
  $(".tab-item-designer").click(function() {
    setTimeout(function() {
      refreshDesigner();
    }, 50);
  });
  $(".tab-item-code").click(function() {
    setTimeout(function() {
      refreshCode();
    }, 50);
  });

  var insertField = function(schema, options, data, dataType, fieldType, parentField, previousField, previousFieldKey, nextField, nextFieldKey) {
    var itemSchema = { "type": dataType };
    var itemOptions = {};
    if (fieldType) { itemOptions.type = fieldType; }
    itemOptions.label = "New ";
    if (fieldType) {
      itemOptions.label += fieldType;
    } else if (dataType) {
      itemOptions.label += dataType;
    }
    var itemData = null;

    var itemKey = null;
    if (parentField.getType() === "array") {
      itemKey = 0;
      if (previousFieldKey) {
        itemKey = previousFieldKey + 1;
      }
    } else if (parentField.getType() === "object") {
      itemKey = "new" + new Date().getTime();
    }

    var insertAfterId = null;
    if (previousField) {
      insertAfterId = previousField.id;
    }

    parentField.addItem(itemKey, itemSchema, itemOptions, itemData, insertAfterId, function() {

      var top = findTop(parentField);

      regenerate(top);
    });

  };

  var assembleSchema = function(field, schema) {
    // copy any properties from this field's schema into our schema object
    for (var k in field.schema) {
      if (field.schema.hasOwnProperty(k) && typeof(field.schema[k]) !== "function") {
        schema[k] = field.schema[k];
      }
    }
    // a few that we handle by hand
    schema.type = field.getType();
    // reset properties, we handle that one at a time
    delete schema.properties;
    schema.properties = {};
    if (field.children) {
      for (var i = 0; i < field.children.length; i++) {
        var childField = field.children[i];
        var propertyId = childField.propertyId;

        schema.properties[propertyId] = {};
        assembleSchema(childField, schema.properties[propertyId]);
      }
    }
  };

  var assembleOptions = function(field, options) {
    // copy any properties from this field's options into our options object
    for (var k in field.options) {
      if (field.options.hasOwnProperty(k) && typeof(field.options[k]) !== "function") {
        options[k] = field.options[k];
      }
    }
    // a few that we handle by hand
    options.type = field.getFieldType();
    // reset fields, we handle that one at a time
    delete options.fields;
    options.fields = {};
    if (field.children) {
      for (var i = 0; i < field.children.length; i++) {
        var childField = field.children[i];
        var propertyId = childField.propertyId;

        options.fields[propertyId] = {};
        assembleOptions(childField, options.fields[propertyId]);
      }
    }
  };

  var findTop = function(field) {
    // now get the top control
    var top = field;
    while (top.parent) { top = top.parent; }

    return top;
  };

  var regenerate = function(top) {
    // walk the control tree and re-assemble the schema, options + data
    var _schema = {};
    assembleSchema(top, _schema);
    var _options = {};
    assembleOptions(top, _options);
    // data is easy
    var _data = top.getValue();
    if (!_data) {
      _data = {};
    }

    editor1.setValue(prettyJSON({
      "schema": _schema,
      "options": _options,
      "data": _data
    }), -1);

    setTimeout(function() {
      refresh();
    }, 100);
  };

  var removeField = function(alpacaId) {
    var field = Alpaca.fieldInstances[alpacaId];

    field
      .parent
      .removeItem(alpacaId, function() {
        regenerate(findTop(field));
      });
  };

  $(".tab-item-source").click();
};

module.exports = FormView.extend({
  template: require('../templates/blueprint_builder.ejs'),
  afterRender: function() {
    setup(this.model.get('config').form);

    console.log(Alpaca.getFieldClass('string'));
  }
});
