meteor-s3-policy-generator
==========================

S3 Policy Generator for Meteor. Designed to work with signed upload forms.

Example:
```coffee-script
# server.coffee
policyGenerator = new S3PolicyGenerator(
  awsAccessKeyId: Meteor.settings.AWS_ACCESS_KEY_ID
  awsSecretAccessKey: Meteor.settings.AWS_SECRET_ACCESS_KEY
  awsBucket: Meteor.settings.AWS_BUCKET_NAME
  awsBaseUrl: Meteor.settings.AWS_S3_BASE_URL
  awsRegion: Meteor.settings.AWS_REGION
)

Meteor.methods ->
  getS3Policy: ->
    options =
      acl: 'public-read'
      maxBytes: 1024 * 1024 * 5
      contentType: 'application/json'
    path = "users/#{Meteor.userId()}.json"
    policyGenerator.generate(path, options)

````
