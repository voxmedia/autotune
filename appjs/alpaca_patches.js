var Alpaca = require('alpaca/build/alpaca/bootstrap/alpaca');

// Cause there doesn't seem to be a better way to set defaults for Alpaca
Alpaca.RuntimeView.prototype.toolbarSticky = true;

// Disable sorting radio and select fields by default
Alpaca.ControlField.prototype.sortSelectableOptions = function(selectableOptions) {
  // Not gonna assume I know better than you
};

module.exports = Alpaca;
