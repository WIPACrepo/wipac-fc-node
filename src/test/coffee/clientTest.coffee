# clientTest.coffee

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
        client = new mut.WFCClient "http://127.0.0.1"
        client.client.should.be.ok()
        client.client =
          get: (url, cb) ->
            url.should.equal "http://127.0.0.1/api/files/#{UUID}"
            return cb DOC_META, "raw response here"
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

    describe "update", ->
      it "does not yet support", ->
        client = new mut.WFCClient "http://127.0.0.1"
        client.update().should.be.rejected()

    describe "replace", ->
      it "does not yet support", ->
        client = new mut.WFCClient "http://127.0.0.1"
        client.replace().should.be.rejected()

    describe "delete", ->
      it "does not yet support", ->
        client = new mut.WFCClient "http://127.0.0.1"
        client.delete().should.be.rejected()
