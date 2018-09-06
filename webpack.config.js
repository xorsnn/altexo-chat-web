const parts = require('./webpack.parts');

const merge = require('webpack-merge');

const path = require('path'),
  _pathResolve = name => path.resolve(__dirname, name);

function selectTarget() {
  return process.env.TARGET || process.env.npm_lifecycle_event || 'build-dev';
}

const common = {
  context: _pathResolve('src/app'),
  entry: {
    bundle: ['./core/bootstrap.js'],
  },
  output: {
    path: _pathResolve('build/'),
    filename: '[name].[hash].js',
    sourceMapFilename: '[name].[hash].js.map',
  },
  node: {
    fs: 'empty',
  },
};

module.exports = (target => {
  console.log('TARGET:', target);

  let config = merge(
    common,
    parts.clean(_pathResolve('build')),
    parts.progressBar(),
    parts.define('AL_EXCLUDED_MODERNIZR_REQUIREMENTS', ''),
    parts.define(
      'AL_WEBSTORE_APP_LINK',
      'https://chrome.google.com/webstore/detail/mdmkpaeaijkojdnbiipnnalonlcbbego',
    ),
    parts.createIndex(),
    parts.copy(_pathResolve('src/img/preview.png'), _pathResolve('build/img')),
    parts.copy(_pathResolve('src/img/favicon.png'), _pathResolve('build/img')),
    // TODO: do this smart way
    parts.copy(
      _pathResolve('node_modules/angular/angular-csp.css'),
      _pathResolve('build/css'),
    ),
    parts.setupCoffee(),
    parts.setupPug(
      [_pathResolve('src/app/features'), _pathResolve('src/app/sections')],
      _pathResolve('src'),
    ),
    parts.setupScss(),
    parts.setupMedia(),
  );

  config = merge(
    config,
    parts.define('AL_API_ENDPOINT', 'https://altexo.com'),
    parts.define('AL_CHAT_ENDPOINT', 'wss://signal.altexo.com'),
    // TODO: take from env
    // parts.define('AL_SENTRY_ENDPOINT', ''),
    parts.define('AL_SERVER_MODE', 'production'),
  );

  if (
    !target ||
    [
      'build-virtual',
      'build-dev',
      'local-dev',
      'build-docker-local',
      'start-docker-dev',
      'start',
    ].indexOf(target) !== -1
  ) {
    // DEVELOPMENT build

    config = merge(
      config,
      parts.define('DEBUG', 'true'),
      parts.enableHotReloading(),
    );
  } else {
    // OPTIMIZED build

    const pkg = require('./package.json');
    const vendorModules = Object.keys(pkg.dependencies).concat([
      '../../bower_components/kurento-utils/lib',
      '../../bower_components/webrtc-adapter/adapter',
      '../vendor/modernizr/modernizr-custom',
    ]);

    config = merge(
      config,
      parts.define('DEBUG', 'false'),
      // parts.extractCss('src/app'),
      parts.minify(),
      parts.extractBundle({
        name: 'vendor',
        entries: vendorModules,
      }),
      {
        devtool: 'source-map',
      },
    );
  }

  return config;
})(selectTarget().toLowerCase());
