module.exports = function () {
  /* Styles */
  require('../index.scss');
  /* JS */
  global.$ = global.jQuery = require('jquery');
  global.Raven = require('raven-js');
  require('angular');
  require('angular-animate');
  require('angular-aria');
  require('angular-messages');
  require('angular-material');
  require('angular-route');
  require('angular-sanitize');
  require('lodash');
  require('ngstorage');

  // TODO: take a look at this workaround later
  var adapter = require('../../../bower_components/webrtc-adapter/adapter.js');
  for (var attrname in adapter) {
    global[attrname] = adapter[attrname];
  }

  require('../../vendor/modernizr/modernizr-custom.js');
};
