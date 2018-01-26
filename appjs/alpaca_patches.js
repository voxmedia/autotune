var Alpaca = require('alpaca/dist/alpaca/bootstrap/alpaca');
var $ = require('jquery');

// Cause there doesn't seem to be a better way to set defaults for Alpaca
Alpaca.RuntimeView.prototype.toolbarSticky = true;

// Disable sorting radio and select fields by default
Alpaca.ControlField.prototype.sortSelectableOptions = function(selectableOptions) {
  // Not gonna assume I know better than you
};

//var tmpl = '\
//<script type="text/x-handlebars-template"><div>\
//<input type="{{inputType}}" id="{{id}}" {{#if options.placeholder}}placeholder="{{options.placeholder}}"{{/if}} {{#if options.size}}size="{{options.size}}"{{/if}} {{#if options.readonly}}readonly="readonly"{{/if}} {{#if name}}name="{{name}}"{{/if}} {{#each options.data}}data-{{@key}}="{{this}}"{{/each}} {{#each options.attributes}}{{@key}}="{{this}}"{{/each}}/> \
//</div></script>';
//Alpaca.registerTemplate('control-googledoc', {type: 'handlebars', template: tmpl}, 'web-edit');

// Define a google doc field
Alpaca.Fields.GoogledocField = Alpaca.Fields.TextField.extend({
  docURLRegexp: /^(https:\/\/docs.google.com\/(?:a\/([^\/]+)\/)?([^\/]+)\/d\/([-\w]{25,})).+$/,
  getFieldType: function() { return 'googledoc'; },
  getTitle: function() { return "Google Doc URL Field"; },
  getDescription: function() {
    return "Provides a text control with validation for a Google Doc URL.";
  },
  setup: function() {
    this.inputType = 'url';
    this.base();
    this.schema.pattern = this.docURLRegexp;
    this.schema.format = "uri";

    if ( this.options.doc_template_url ) {
      var parts = this.options.doc_template_url.match(this.docURLRegexp);
      this.options.doc_template_id = parts[4];
      this.options.doc_template_base_url = parts[1];
      this.options.doc_type = parts[3];
    }

    if (typeof(this.options.doc_type) === "undefined") {
      this.options.doc_type = "spreadsheet";
    }
    if (typeof(this.options.create_new_doc_label) === "undefined") {
      this.options.create_new_doc_label = "Create new empty " + this.humanizeDocType();
    }
  },
  humanizeDocType: function() {
    return this.options.doc_type === 'spreadsheets' ? 'spreadsheet' : this.options.doc_type;
  },
  handleValidate: function() {
    var baseStatus = this.base();
    var valInfo = this.validation;

    if (!valInfo["invalidPattern"]["status"]) {
      valInfo["invalidPattern"]["message"] = this.getMessage("invalidGDocURLFormat");
    }

    return baseStatus;
  },
  renderExtras: function() {
    if (typeof(this.options.doc_template_id) === "undefined") { return; }

    var self = this, ele = document.createElement('a');

    $(ele).attr({
      type: 'button',
      class: 'new-google-doc',
      target: '_blank',
      href: this.options.doc_template_base_url + '/copy',
      'data-target': this.id,
      'data-template-id': this.options.doc_template_id
    }).text(this.options.create_new_doc_label);

    if (typeof(this.options.create_new_doc_callback) !== "undefined") {
      $(ele).click(function(eve) {
        eve.preventDefault();
        eve.stopPropagation();
        self.options.create_new_doc_callback(self);
      });
    }

    this.control.after(ele);
  },
  afterRenderControl: function(model, callback) {
    var self = this;
    this.base(model, function() {
      self.renderExtras();
      callback();
    });
  }
});

Alpaca.registerMessages({ "invalidGDocURLFormat": "The URL provided is not a valid Google Doc address." });
Alpaca.registerFieldClass('googledoc', Alpaca.Fields.GoogledocField);

module.exports = Alpaca;
