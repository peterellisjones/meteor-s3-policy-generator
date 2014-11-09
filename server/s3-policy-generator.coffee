moment = Npm.require('moment')
crypto = Npm.require('crypto')

class S3PolicyGenerator
  constructor: (options) ->
    if options.awsSecretAccessKey?
      @_awsSecretAccessKey = options.awsSecretAccessKey
    else
      throw new Error("awsSecretAccessKey not provided")

    if options.awsAccessKeyId?
      @_awsAccessKeyId = options.awsAccessKeyId
    else
      throw new Error("awsAccessKeyId not provided")

    if options.awsBaseUrl?
      @_awsBaseUrl = options.awsBaseUrl
    else
      throw new Error("awsBaseUrl not provided")

    if options.awsBucket?
      @_awsBucket = options.awsBucket
    else
      throw new Error("awsBucket not provided")

    if options.awsRegion?
      @_awsRegion = options.awsRegion
    else
      throw new Error("awsRegion not provided")

    @_clock =
      now: ->
        moment().utc()

  generate: (path, options = {}) ->

    # strip leading slashes from path
    path = path.replace /^\//, ''

    formFields =
      key: path
      acl: options.acl or 'private'
      'x-amz-algorithm': 'AWS4-HMAC-SHA256'
      'x-amz-credential': @_xAmzCredential()
      'x-amz-date': @_xAmzDate()

    if options.contentType?
      formFields['Content-Type'] = options.contentType

    formFields.policy = @_generateB64Policy(formFields, options)
    formFields['x-amz-signature'] = @_generateSignature(formFields.policy)

    resp =
      awsBaseUrl: @_awsBaseUrl
      formFields: formFields

  _sign: (key, data) ->
    hmac = crypto.createHmac "SHA256", key
    hmac.update(data)
    new Buffer(hmac.digest("base64"), "base64")

  _generateSignature: (b64policy) ->
    kDate = @_sign(
      'AWS4' + @_awsSecretAccessKey,
      @_clock.now().format('YYYYMMDD')
    )
    kRegion = @_sign(kDate, @_awsRegion)
    kService = @_sign(kRegion, 's3')
    key = @_sign(kService, 'aws4_request')

    @_sign(key, b64policy).toString('hex')

  _generateB64Policy: (formFields, options) ->
    expirationSeconds = options.expiration or 60
    expiration = @_clock.now().add(expirationSeconds, 'second')

    conditions = [
      { key: formFields.key }
      { bucket: @_awsBucket }
      { acl: formFields.acl }
      { 'x-amz-algorithm': formFields['x-amz-algorithm'] }
      { 'x-amz-credential': formFields['x-amz-credential'] }
      { 'x-amz-date': formFields['x-amz-date'] }
    ]

    if formFields['Content-Type']?
      conditions.push
        'Content-Type': formFields['Content-Type']

    if options.maxBytes
      conditions.push ['content-length-range', 0, options.maxBytes]

    policy =
      expiration: expiration.format("YYYY-MM-DDTHH:mm:ss\\Z")
      conditions: conditions

    new Buffer(JSON.stringify(policy)).toString('base64')

  _xAmzCredential: ->
    date = @_clock.now().format('YYYYMMDD')
    "#{@_awsAccessKeyId}/#{date}/#{@_awsRegion}/s3/aws4_request"

  _xAmzDate: ->
    @_clock.now().format('YYYYMMDDTHHmmss\\Z')
