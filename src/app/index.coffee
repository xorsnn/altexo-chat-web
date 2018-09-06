'use strict'

if (AL_SENTRY_ENDPOINT?)
  (Raven.config AL_SENTRY_ENDPOINT, {
    ignoreUrls: [ /<raven_urls_to_ignore>/ ]
  })
  .addPlugin(require('raven-js/plugins/angular'), angular)
  .install()

apps = [
  'ngMaterial'
  'ngMessages'
  'ngRoute'
  'ngSanitize'
  'ngStorage'
]

if (AL_SENTRY_ENDPOINT?)
  apps += ['ngRaven']

module.exports = angular.module 'AltexoApp', apps
