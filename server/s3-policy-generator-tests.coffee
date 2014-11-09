decodeB64 = (str) ->
  json = new Buffer(str, 'base64').toString('binary')
  JSON.parse(json)

moment = Npm.require('moment')

describe 'S3PolicyGenerator', ->
  describe 'constructor', ->
    it 'throws an error without an aws access key id', (test) ->
      test.throws ->
        new S3PolicyGenerator
          awsSecretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
          awsBaseUrl: 'https://test.s3-us-west-2.amazonaws.com'
          awsRegion: 'us-west-2'
          awsBucket: 'acl6'

    it 'throws an error without an aws secret access key', (test) ->
      test.throws ->
        new S3PolicyGenerator
          awsAccessKeyId: 'AKIAIOSFODNN7EXAMPLE'
          awsBaseUrl: 'https://test.s3-us-west-2.amazonaws.com'
          awsRegion: 'us-east-1'
          awsBucket: 'exampleBucket'

    it 'throws an error without an aws url', (test) ->
      test.throws ->
        new S3PolicyGenerator
          awsAccessKeyId: 'AKIAIOSFODNN7EXAMPLE'
          awsSecretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
          awsRegion: 'us-east-1'
          awsBucket: 'exampleBucket'

    it 'throws an error without an aws region', (test) ->
      test.throws ->
        new S3PolicyGenerator
          awsAccessKeyId: 'AKIAIOSFODNN7EXAMPLE'
          awsSecretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
          awsBaseUrl: 'https://test.s3-us-west-2.amazonaws.com'
          awsBucket: 'exampleBucket'

    it 'throws an error without an aws bucket', (test) ->
      test.throws ->
        new S3PolicyGenerator
          awsAccessKeyId: 'AKIAIOSFODNN7EXAMPLE'
          awsSecretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
          awsBaseUrl: 'https://test.s3-us-west-2.amazonaws.com'
          awsRegion: 'us-east-1'

    it 'does not return an error when given correct AWS credentials', (test) ->
      generator = new S3PolicyGenerator
        awsAccessKeyId: 'AKIAIOSFODNN7EXAMPLE'
        awsSecretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
        awsBaseUrl: 'https://test.s3-us-west-2.amazonaws.com'
        awsRegion: 'us-east-1'
        awsBucket: 'exampleBucket'

      test.instanceOf generator, S3PolicyGenerator

  describe 'generate', ->
    generator = new S3PolicyGenerator
      awsAccessKeyId: 'AKIAIOSFODNN7EXAMPLE'
      awsSecretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
      awsBaseUrl: 'https://acl16.s3-us-east-1.amazonaws.com'
      awsRegion: 'us-east-1'
      awsBucket: 'exampleBucket'

    generator._clock =
      now: ->
        moment(1375747200000 - 3600000)

    policy = generator.generate('path/to/object')

    it 'has the correct base url', (test) ->
      expectedUrl = 'https://acl16.s3-us-east-1.amazonaws.com'
      test.equal expectedUrl, policy.awsBaseUrl

    describe 'the form fields', ->
      describe 'key', ->
        context 'with a leading slash', ->
          it 'is correct', (test) ->
            test.equal(
              generator.generate('/path/to/object').formFields.key,
              'path/to/object'
            )

        context 'without a leading slash', ->
          it 'is correct', (test) ->
            test.equal(
              generator.generate('path/to/object').formFields.key,
              'path/to/object'
            )

      describe 'x-amz-algorithm', ->
        it 'is correct', (test) ->
          test.equal policy.formFields['x-amz-algorithm'], 'AWS4-HMAC-SHA256'

      describe 'x-amz-credential', ->
        it 'is correct', (test) ->
          expected = 'AKIAIOSFODNN7EXAMPLE/20130806/us-east-1/s3/aws4_request'
          test.equal policy.formFields['x-amz-credential'], expected

      describe 'x-amz-date', ->
        it 'is correct', (test) ->
          test.equal policy.formFields['x-amz-date'], '20130806T000000Z'

      describe 'acl', ->
        context 'when acl is not passed as an option', ->
          it 'is private', (test) ->
            test.equal policy.formFields.acl, 'private'

        context 'when the acl is passed as an option', ->
          it 'is correct', (test) ->
            options = acl: 'public-read'
            test.equal(
              generator.generate('path/to/object', options).formFields.acl,
              'public-read'
            )

      describe 'Content-Type', ->
        context 'when the content type is not provided', ->
          it 'is not set', (test) ->
            test.isUndefined policy.formFields['Content-Type']

        context 'when the content type is provided', ->
          it 'is correct', (test) ->
            options = contentType: 'application/json'
            fields = generator.generate('path/to/object', options).formFields
            test.equal(
              fields['Content-Type'],
              'application/json'
            )

    describe 'signature', ->
      it 'is correct', (test) ->
        test.equal policy.formFields['x-amz-signature'].length, 64

    describe '_generateSignature', ->
      it 'returns the correct signature', (test) ->

        encodedPolicy = 'eyAiZXhwaXJhdGlvbiI6ICIyMDEzLTA4LTA3VDEyOjAwOjAwLjAwM\
          FoiLA0KICAiY29uZGl0aW9ucyI6IFsNCiAgICB7ImJ1Y2tldCI6ICJleGFtcGxlYnVja2\
          V0In0sDQogICAgWyJzdGFydHMtd2l0aCIsICIka2V5IiwgInVzZXIvdXNlcjEvIl0sDQo\
          gICAgeyJhY2wiOiAicHVibGljLXJlYWQifSwNCiAgICB7InN1Y2Nlc3NfYWN0aW9uX3Jl\
          ZGlyZWN0IjogImh0dHA6Ly9leGFtcGxlYnVja2V0LnMzLmFtYXpvbmF3cy5jb20vc3VjY\
          2Vzc2Z1bF91cGxvYWQuaHRtbCJ9LA0KICAgIFsic3RhcnRzLXdpdGgiLCAiJENvbnRlbn\
          QtVHlwZSIsICJpbWFnZS8iXSwNCiAgICB7IngtYW16LW1ldGEtdXVpZCI6ICIxNDM2NTE\
          yMzY1MTI3NCJ9LA0KICAgIFsic3RhcnRzLXdpdGgiLCAiJHgtYW16LW1ldGEtdGFnIiwg\
          IiJdLA0KDQogICAgeyJ4LWFtei1jcmVkZW50aWFsIjogIkFLSUFJT1NGT0ROTjdFWEFNU\
          ExFLzIwMTMwODA2L3VzLWVhc3QtMS9zMy9hd3M0X3JlcXVlc3QifSwNCiAgICB7IngtYW\
          16LWFsZ29yaXRobSI6ICJBV1M0LUhNQUMtU0hBMjU2In0sDQogICAgeyJ4LWFtei1kYXR\
          lIjogIjIwMTMwODA2VDAwMDAwMFoiIH0NCiAgXQ0KfQ=='

        signature = generator._generateSignature(encodedPolicy)
        expected = '21496b44de44ccb73d545f1a995c\
          68214c9cb0d41c45a17a5daeec0b1a6db047'

        test.equal signature, expected

    describe 'policy', ->
      decodedPolicy = decodeB64(policy.formFields.policy)
      describe 'expiration', ->
        context 'when it is not provided', ->
          it 'defaults to one minute', (test) ->
            test.equal decodedPolicy.expiration, '2013-08-06T00:01:00Z'

        context 'when is is provided', ->
          it 'is correct', (test) ->
            options =
              expiration: 3 * 60
            pol = generator.generate('path/to/object', options)
            decodedPol = decodeB64(pol.formFields.policy)
            test.equal decodedPol.expiration, '2013-08-06T00:03:00Z'

      describe 'conditions', ->
        it 'has the correct key', (test) ->
          test.equal decodedPolicy.conditions[0].key, 'path/to/object'

        it 'has the correct bucket', (test) ->
          test.equal decodedPolicy.conditions[1].bucket, 'exampleBucket'

        it 'has the correct acl', (test) ->
          test.equal decodedPolicy.conditions[2].acl, 'private'

        it 'has the correct x-amz-algorithm', (test) ->
          actual = decodedPolicy.conditions[3]['x-amz-algorithm']
          test.equal actual, 'AWS4-HMAC-SHA256'

        it 'is has the correct x-amz-credential', (test) ->
          expected = 'AKIAIOSFODNN7EXAMPLE/20130806/us-east-1/s3/aws4_request'
          actual = decodedPolicy.conditions[4]['x-amz-credential']
          test.equal actual, expected

        it 'has the correct x-amz-date', (test) ->
          actual = decodedPolicy.conditions[5]['x-amz-date']
          test.equal actual, '20130806T000000Z'

        context 'when contentType is passed', ->
          it 'has the correct content type', (test) ->
            options =
              contentType: 'application/json'
            pol = generator.generate('path/to/object', options)
            decodedPol = decodeB64(pol.formFields.policy)
            actual = decodedPol.conditions[6]['Content-Type']
            test.equal actual, 'application/json'

          context 'when maxBytes is passed', ->
            it 'has the correct content-length-range', (test) ->
              options =
                maxBytes: 1024
              pol = generator.generate('path/to/object', options)
              decodedPol = decodeB64(pol.formFields.policy)
              actual = decodedPol.conditions[6]
              expected = ['content-length-range', 0, 1024]
              test.equal actual, expected
