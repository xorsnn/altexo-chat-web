/*jshint browser:true */
'use strict';

// load Angular
require('./vendor')();

// load the main app file
var appModule = require('../index.coffee');
// replaces ng-app="appName"
angular.element(document).ready(function () {
  angular.bootstrap(document, [appModule.name], {
    strictDi: true
  });
});
