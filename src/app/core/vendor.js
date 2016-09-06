module.exports = function() {
    /* Styles */
    require('../index.scss');
    /* JS */
    global.$ = global.jQuery = require('jquery');
    require('angular');
    require('angular-material');
    require('angular-route');
    require('lodash');

    // TODO: take a look at this workaround later
    var adapter = require('../../../bower_components/webrtc-adapter/adapter.js')
    for (var attrname in adapter) {
      global[attrname] = adapter[attrname]
    }

    global.kurentoUtils = require('../../../bower_components/kurento-utils/dist/kurento-utils.js')
    require('../../../bower_components/angular-promisify/dist/denodeify.js');
};
