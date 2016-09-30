/*jshint browser:true */
'use strict';

// load Angular
require('./vendor')();

// load the main app file
var appModule = require('../index.coffee');
if (appModule) {
  // replaces ng-app="appName"
  angular.element(document).ready(function () {
    angular.bootstrap(document, [appModule.name], {
      strictDi: true
    });
  });
} else {
  // var redirectFunc = function () {
  //   window.location = "https://altexo.com/";
  // };
  // NOTE: debouncing to give safari time to send raven report
  _.debounce(function () {
    window.location = "https://altexo.com/";
  }, 1000)();
}
