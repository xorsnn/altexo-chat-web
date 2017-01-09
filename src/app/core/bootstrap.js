/*jshint browser:true */
'use strict';

// load Angular
require('./vendor')();

var customRequire = require.context('..', true, /\.coffee$/);
// load the main app file
// var appModule = require('../index.coffee');
var appModule = customRequire('./index.coffee');

// require all other modules except index to wire angular app's stuff
customRequire.keys().forEach(function(key) {
  if (key !== './index.coffee') {
    customRequire(key);
  }
});

// load resources
var resourceRequire = require.context('..', true, /\.(pug|scss)$/);
resourceRequire.keys().forEach(function(key) {
  resourceRequire(key);
});

// replaces ng-app="appName"
angular.element(document).ready(function () {
  angular.bootstrap(document, [appModule.name], {
    strictDi: true
  });
});
