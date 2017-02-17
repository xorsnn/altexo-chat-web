'use strict'

(Raven.config AL_SENTRY_ENDPOINT, {
  ignoreUrls: [ /<raven_urls_to_ignore>/ ]
})
.addPlugin(require('raven-js/plugins/angular'), angular)
.install()


module.exports = angular.module 'AltexoApp', [
  'ngMaterial'
  'ngMessages'
  'ngRoute'
  'ngRaven'
  'ngSanitize'
  'ngStorage'
]
