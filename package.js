Package.describe({
  name: 'peterellisjones:s3-policy-generator',
  summary: 'Generates S3 signed upload policies in a format designed to be used for upload forms',
  version: '1.0.0',
  git: 'https://github.com/peterellisjones/meteor-s3-policy-generator.git'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');
  Npm.depends({moment: '2.8.3'});

  api.use('coffeescript');
  api.addFiles('server/s3-policy-generator.coffee', 'server');
  api.export('S3PolicyGenerator');
});

Package.onTest(function(api) {
api.use('coffeescript');
  Npm.depends({moment: '2.8.3'});

  api.use('peterellisjones:describe');
  api.use('peterellisjones:s3-policy-generator');
  api.addFiles('server/s3-policy-generator-tests.coffee', 'server');
});
