# clientTest.coffee
#-----------------------------------------------------------------------

should = require "should"

MODULE_UNDER_TEST = "../lib/client"

mut = require MODULE_UNDER_TEST

ERROR_CLASSES = [
  "BadRequestError"
  "ConflictError"
  "NotFoundError"
  "ServiceUnavailableError"
  "TooManyRequestsError"
  "UnspecificServerError"
]

ERROR_CODES =
  BadRequestError: 400
  ConflictError: 409
  NotFoundError: 404
  ServiceUnavailableError: 503
  TooManyRequestsError: 429
  UnspecificServerError: 500

describe "client", ->
  describe "Error classes", ->
    it "should provide some decorated Error classes", ->
      mut.should.have.properties ERROR_CLASSES

    it "should allow instantiation of Error classes", ->
      for errorClass in ERROR_CLASSES
        checkError = new (mut[errorClass]) "muh message"
        checkError.should.be.instanceof Error
        checkError.message.should.equal "muh message"
        checkError.code.should.equal ERROR_CODES[errorClass]

  describe "error_factory", ->
    it "should be able to create errors for each code", ->
      for errorClass of ERROR_CODES
        code = ERROR_CODES[errorClass]
        err = mut.error_factory code, "muh message"
        err.constructor.name.should.equal errorClass
        err.code.should.equal code
        err.message.should.equal "muh message"

    it "should use Error for unknown codes", ->
        err = mut.error_factory 101, "derp message"
        err.constructor.name.should.equal "Error"
        err.code.should.equal 101
        err.message.should.equal "derp message"

  describe "WFCClient", ->
    it "should be able to be instantiated", ->
      client = new mut.WFCClient "http://127.0.0.1"
      client.url.should.equal "http://127.0.0.1/api"
      client.client.should.be.ok()

    it "should support custom ports", ->
      client = new mut.WFCClient "http://127.0.0.1", 8080
      client.url.should.equal "http://127.0.0.1:8080/api"
      client.client.should.be.ok()

    it "does not yet support sessions", ->
      should(-> new mut.WFCClient "http://127.0.0.1", 8080, true)
      .throw new Error "(use_session = true) Not Supported"

    describe "get", ->
      it "should return the metadata as a JSON object if available", ->
        UUID = "df25e09b-7361-44d4-a5ae-8d12cf649064"
        DOC_META =
          "alice": 1
          "bob": 2
          "carol": 3
        DOC_JSON = JSON.stringify DOC_META
        client = new mut.WFCClient "http://127.0.0.1"
        client.client.should.be.ok()
        client.client =
          get: (url, cb) ->
            url.should.equal "http://127.0.0.1/api/files/#{UUID}"
            return cb DOC_JSON, "raw response here"
          on: (name, cb) ->
        should(client.get("df25e09b-7361-44d4-a5ae-8d12cf649064")).be.fulfilledWith DOC_META

      it "should throw an error if not available", ->
        UUID = "df25e09b-7361-44d4-a5ae-8d12cf649064"
        DOC_META =
          "alice": 1
          "bob": 2
          "carol": 3
        client = new mut.WFCClient "http://127.0.0.1"
        client.client.should.be.ok()
        client.client =
          get: (url, cb) ->
            url.should.equal "http://127.0.0.1/api/files/#{UUID}"
            return this
          on: (name, cb) ->
            name.should.equal "error"
            cb new Error "nope"
        should(client.get("df25e09b-7361-44d4-a5ae-8d12cf649064")).be.rejectedWith new Error "nope"

    describe "get_list", ->
      it "should return a list of files with matching metadata", ->
        FILES_META =
          _links:
            parent:
              href: "/api"
            self:
              href: "/api/files"
          files: [
            {
              logical_name: "/data/exp/IceCube/2012/filtered/PFFilt/1109/PFFilt_PhysicsTrig_PhysicsFiltering_Run00120918_Subrun00000000_00000089.tar.bz2"
              uuid: "5fb50d75-1c90-4f8a-9d9b-ac4a6ce80744"
            }
          ]
        FILES_JSON = JSON.stringify FILES_META
        QUERY =
          query:
            logical_name: "/data/exp/IceCube/2012/filtered/PFFilt/1109/PFFilt_PhysicsTrig_PhysicsFiltering_Run00120918_Subrun00000000_00000089.tar.bz2"
        client = new mut.WFCClient "http://127.0.0.1"
        client.client.should.be.ok()
        client.client =
          get: (url, args, cb) ->
            url.should.equal "http://127.0.0.1/api/files"
            args.should.eql
              parameters:
                query: '{"logical_name":"/data/exp/IceCube/2012/filtered/PFFilt/1109/PFFilt_PhysicsTrig_PhysicsFiltering_Run00120918_Subrun00000000_00000089.tar.bz2"}'
            return cb FILES_JSON, "raw response here"
          on: (name, cb) ->
        should(client.get_list(QUERY)).be.fulfilledWith FILES_META

      it "should use start and limit if provided", ->
        FILES_META =
          _links:
            parent:
              href: "/api"
            self:
              href: "/api/files"
          files: [
            {
              logical_name: "/data/exp/IceCube/2012/filtered/PFFilt/1109/PFFilt_PhysicsTrig_PhysicsFiltering_Run00120918_Subrun00000000_00000089.tar.bz2"
              uuid: "5fb50d75-1c90-4f8a-9d9b-ac4a6ce80744"
            }
          ]
        FILES_JSON = JSON.stringify FILES_META
        QUERY =
          start: 50
          limit: 50
        client = new mut.WFCClient "http://127.0.0.1"
        client.client.should.be.ok()
        client.client =
          get: (url, args, cb) ->
            url.should.equal "http://127.0.0.1/api/files"
            args.should.eql
              parameters:
                start: 50
                limit: 50
            return cb FILES_JSON, "raw response here"
          on: (name, cb) ->
        should(client.get_list(QUERY)).be.fulfilledWith FILES_META

      it "should throw an error if not available", ->
        QUERY =
          query:
            logical_name: "/data/exp/IceCube/2012/filtered/PFFilt/1109/PFFilt_PhysicsTrig_PhysicsFiltering_Run00120918_Subrun00000000_00000089.tar.bz2"
        client = new mut.WFCClient "http://127.0.0.1"
        client.client.should.be.ok()
        client.client =
          get: (url, args, cb) ->
            url.should.equal "http://127.0.0.1/api/files"
            args.should.eql
              parameters:
                query: '{"logical_name":"/data/exp/IceCube/2012/filtered/PFFilt/1109/PFFilt_PhysicsTrig_PhysicsFiltering_Run00120918_Subrun00000000_00000089.tar.bz2"}'
            return this
          on: (name, cb) ->
            name.should.equal "error"
            cb new Error "nope"
        should(client.get_list(QUERY)).be.rejectedWith new Error "nope"

    describe "get_etag", ->
      it "does not yet support", ->
        client = new mut.WFCClient "http://127.0.0.1"
        client.get_etag("df25e09b-7361-44d4-a5ae-8d12cf649064").should.be.rejected()

    describe "create", ->
      it "should allow a document to be created", ->
        DOC_META =
          uuid: 'df25e09b-7361-44d4-a5ae-8d12cf649064'
          logical_name: '/data/exp/IceCube/2016/filtered/PFFilt/0613/PFFilt_PhysicsTrig_PhysicsFiltering_Run00647875_Subrun00000000_00000423.tar.bz2'
          locations: [
            {
              site: 'WIPAC'
              path: '/data/exp/IceCube/2016/filtered/PFFilt/0613/PFFilt_PhysicsTrig_PhysicsFiltering_Run00647875_Subrun00000000_00000423.tar.bz2'
            }
          ]
          file_size: 96448528
          checksum:
            sha512: 'd5346e94d00fb2e3beb48f3680d0ff43ad9af4f54b8d3aa64a0e3f93be8dde7c09060cbbaef44b418330e59f8327f2188db467fd44800b013c3724775246114e'

        FC_RESPONSE =
          _links:
            parent:
              href: "/api"
            self:
              href: "/api/files"
          file: "/api/files/df25e09b-7361-44d4-a5ae-8d12cf649064"

        client = new mut.WFCClient "http://127.0.0.1"
        client.client.should.be.ok()
        client.client =
          post: (url, args, cb) ->
            url.should.equal "http://127.0.0.1/api/files"
            args.should.eql
              data:
                uuid: 'df25e09b-7361-44d4-a5ae-8d12cf649064'
                logical_name: '/data/exp/IceCube/2016/filtered/PFFilt/0613/PFFilt_PhysicsTrig_PhysicsFiltering_Run00647875_Subrun00000000_00000423.tar.bz2'
                locations: [
                  {
                    site: 'WIPAC'
                    path: '/data/exp/IceCube/2016/filtered/PFFilt/0613/PFFilt_PhysicsTrig_PhysicsFiltering_Run00647875_Subrun00000000_00000423.tar.bz2'
                  }
                ]
                file_size: 96448528
                checksum:
                  sha512: 'd5346e94d00fb2e3beb48f3680d0ff43ad9af4f54b8d3aa64a0e3f93be8dde7c09060cbbaef44b418330e59f8327f2188db467fd44800b013c3724775246114e'
              headers:
                "Content-Type": 'application/json'
            jsonFcResp = JSON.stringify FC_RESPONSE, null, 2
            return cb jsonFcResp, "raw response here"
          on: (name, cb) ->
        should(client.create(DOC_META)).be.fulfilledWith FC_RESPONSE

      it "should throw an error if not available", ->
        DOC_META =
          "dave": 4
          "eve": 5
          "frank": 6
        client = new mut.WFCClient "http://127.0.0.1"
        client.client.should.be.ok()
        client.client =
          post: (url, args, cb) ->
            url.should.equal "http://127.0.0.1/api/files"
            args.should.eql
              data:
                "dave": 4
                "eve": 5
                "frank": 6
              headers:
                "Content-Type": 'application/json'
            return client.client
          on: (name, cb) ->
            name.should.equal "error"
            cb new Error "nope"
        should(client.create(DOC_META)).be.rejectedWith new Error "nope"

    describe "update", ->
      it "should allow a document to be updated", ->
        UUID = "df25e09b-7361-44d4-a5ae-8d12cf649064"
        DOC_PATCH =
          "dave": 4
          "eve": 5
          "frank": 6
        DOC_META =
          "alice": 1
          "bob": 2
          "carol": 3
          "dave": 4
          "eve": 5
          "frank": 6
        client = new mut.WFCClient "http://127.0.0.1"
        client.client.should.be.ok()
        client.client =
          patch: (url, args, cb) ->
            url.should.equal "http://127.0.0.1/api/files/#{UUID}"
            args.should.eql
              data: '{"dave":4,"eve":5,"frank":6}'
              headers:
                "Content-Type": 'application/json'
            return cb DOC_META, "raw response here"
          on: (name, cb) ->
        should(client.update("df25e09b-7361-44d4-a5ae-8d12cf649064", DOC_PATCH)).be.fulfilledWith DOC_META

      it "rejects if not provided with a UID", ->
        client = new mut.WFCClient "http://127.0.0.1"
        client.update().should.be.rejected()

      it "rejects if not provided with patch metadata", ->
        client = new mut.WFCClient "http://127.0.0.1"
        client.update("df25e09b-7361-44d4-a5ae-8d12cf649064").should.be.rejected()

      it "should throw an error if not available", ->
        UUID = "df25e09b-7361-44d4-a5ae-8d12cf649064"
        DOC_PATCH =
          "dave": 4
          "eve": 5
          "frank": 6
        client = new mut.WFCClient "http://127.0.0.1"
        client.client.should.be.ok()
        client.client =
          patch: (url, args, cb) ->
            url.should.equal "http://127.0.0.1/api/files/#{UUID}"
            args.should.eql
              data: '{"dave":4,"eve":5,"frank":6}'
              headers:
                "Content-Type": 'application/json'
            return client.client
          on: (name, cb) ->
            name.should.equal "error"
            cb new Error "nope"
        should(client.update("df25e09b-7361-44d4-a5ae-8d12cf649064", DOC_PATCH)).be.rejectedWith new Error "nope"

    describe "_update_or_replace", ->
      it "is an internal method that should not be called", ->
        client = new mut.WFCClient "http://127.0.0.1"
        client._update_or_replace("df25e09b-7361-44d4-a5ae-8d12cf649064", {}).should.be.rejected()

    describe "replace", ->
      it "should allow a document to be replaced", ->
        UUID = "df25e09b-7361-44d4-a5ae-8d12cf649064"
        DOC_REPLACE =
          "dave": 4
          "eve": 5
          "frank": 6
        client = new mut.WFCClient "http://127.0.0.1"
        client.client.should.be.ok()
        client.client =
          put: (url, args, cb) ->
            url.should.equal "http://127.0.0.1/api/files/#{UUID}"
            args.should.eql
              data: '{"dave":4,"eve":5,"frank":6}'
              headers:
                "Content-Type": 'application/json'
            return cb DOC_REPLACE, "raw response here"
          on: (name, cb) ->
        should(client.replace("df25e09b-7361-44d4-a5ae-8d12cf649064", DOC_REPLACE)).be.fulfilledWith DOC_REPLACE

      it "rejects if not provided with a UID", ->
        client = new mut.WFCClient "http://127.0.0.1"
        client.replace().should.be.rejected()

      it "rejects if not provided with patch metadata", ->
        client = new mut.WFCClient "http://127.0.0.1"
        client.replace("df25e09b-7361-44d4-a5ae-8d12cf649064").should.be.rejected()

    describe "delete", ->
      it "does not yet support", ->
        client = new mut.WFCClient "http://127.0.0.1"
        client.delete().should.be.rejected()

#-----------------------------------------------------------------------
# end of clientTest.coffee
