module.exports = function () {
  /* Styles */
  require('../index.scss');
  /* JS */
  global.$ = global.jQuery = require('jquery');
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

  global.THREE = require('../../../bower_components/three.js/build/three.js');
  global.kurentoUtils = require('../../../bower_components/kurento-utils/dist/kurento-utils.js');
  require('../../../bower_components/angular-promisify/dist/denodeify.js');

  global.Raven = require('raven-js');

  require('../../vendor/modernizr/modernizr-custom.js');
};
