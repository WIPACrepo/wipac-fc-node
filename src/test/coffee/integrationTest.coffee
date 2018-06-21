# integrationTest.coffee
#-----------------------------------------------------------------------

should = require "should"

crypto = require "crypto"
{defaults} = require "underscore"
{inspect} = require "util"
uuidv4 = require "uuid/v4"

MODULE_UNDER_TEST = "../lib/client"

mut = require MODULE_UNDER_TEST

CLIENT_URL = "http://127.0.0.1"
CLIENT_PORT = 8888

DEC2 = (x) -> ("00" + x).substr -2
DEC8 = (x) -> ("00000000" + x).substr -8

randomYear = -> Math.floor 2008 + Math.random()*10

randomMonth = -> DEC2 Math.floor 1 + Math.random()*12

randomDay = (x) ->
  # 30 days has September, April, June, and November...
  max = switch x
    when "01" then 31
    when "02" then 28
    when "03" then 31
    when "04" then 30
    when "05" then 31
    when "06" then 30
    when "07" then 31
    when "08" then 31
    when "09" then 30
    when "10" then 31
    when "11" then 30
    when "12" then 31
    else 30
  DEC2 Math.floor 1 + Math.random() * max

randomRun = -> DEC8 Math.floor Math.random()*1000000

randomPart = -> DEC8 Math.floor Math.random()*1000

randomPath = ->
  year = randomYear()
  month = randomMonth()
  day = randomDay month
  run = randomRun()
  part = randomPart()
  return "/data/exp/IceCube/#{year}/filtered/PFFilt/#{month}#{day}/PFFilt_PhysicsTrig_PhysicsFiltering_Run#{run}_Subrun00000000_#{part}.tar.bz2"

randomUuid = -> uuidv4()

randomSize = -> Math.floor 95000000 + Math.random()*10000000

randomChecksum = -> crypto.randomBytes(64).toString "hex"

randomDocument = ->
  name = randomPath()
  uuid = randomUuid()
  location =
    site: "WIPAC"
    path: name
  size = randomSize()
  checksum = randomChecksum()

  return FILE_META =
    uuid: uuid
    logical_name: name
    locations: [ location ]
    file_size: size
    checksum:
      sha512: checksum

describe "integration", ->
  client = new mut.WFCClient CLIENT_URL, CLIENT_PORT

  describe "WFCClient", ->
    it "should be able to be instantiated", ->
      client.url.should.equal "#{CLIENT_URL}:#{CLIENT_PORT}/api"
      client.client.should.be.ok()

    xit "should be able to check for service availability", ->
      false.should.equal true

  describe "Documents", ->
    it "should be able to create and retrieve a document", ->
      DOC = randomDocument()
      result = await client.create DOC
      result.should.have.properties [ "_links", "file" ]
      result.file.should.equal "/api/files/#{DOC.uuid}"

      CHECK_DOC = defaults {}, DOC,
        _links:
          parent:
            href: "/api/files"
          self:
            href: "/api/files/#{DOC.uuid}"
      getDoc = await client.get DOC.uuid
      CHECK_DOC.meta_modify_date = getDoc.meta_modify_date
      getDoc.should.eql CHECK_DOC

    it "should be able to create and retrieve several documents", ->
      NUM_DOCS = 3
      # create a tag to group the documents
      tag = randomUuid()
      # create some random documents and put them in the catalog
      docs = (randomDocument() for x in [1..NUM_DOCS])
      expecting = []
      for doc in docs
        expecting.push doc.uuid
        doc.special_tag = tag
        result = await client.create doc
        result.should.have.properties [ "_links", "file" ]
        result.file.should.equal "/api/files/#{doc.uuid}"
      expecting.should.have.length NUM_DOCS
      # use a query to recall those documents
      result = await client.get_list
        query:
          special_tag: tag
      result.should.have.properties [ "_links", "files" ]
      result.files.should.have.length NUM_DOCS
      for file in result.files
        expecting.includes(file.uuid).should.equal true

  describe "Collections", ->
    it "should be able to retrieve a list of collections", ->
      result = await client.get_collections()
      result.should.have.properties [ "_links", "collections" ]
      result._links.self.href.should.equal "/api/collections"

    it "should be able to create a collection from several documents", ->
      NUM_DOCS = 3
      # create a tag to group the documents
      tag = randomUuid()
      # create some random documents and put them in the catalog
      docs = (randomDocument() for x in [1..NUM_DOCS])
      expecting = []
      for doc in docs
        expecting.push doc.uuid
        doc.special_tag = tag
        result = await client.create doc
        result.should.have.properties [ "_links", "file" ]
        result.file.should.equal "/api/files/#{doc.uuid}"
      expecting.should.have.length NUM_DOCS
      # use a query to recall those documents
      result = await client.get_list
        query:
          special_tag: tag
      result.should.have.properties [ "_links", "files" ]
      result.files.should.have.length NUM_DOCS
      for file in result.files
        expecting.includes(file.uuid).should.equal true
      # create a collection out of the query
      result2 = await client.create_collection
        collection_name: "special_tag_#{tag}"
        query:
          special_tag: tag
        owner: "fbloggs"
      result2.should.have.properties [ "_links", "collection" ]
      result2.collection.should.match /\/api\/collections\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
      # recall the collection by its UUID
      uuid = result2.collection.substr 17
      result3 = await client.get_collection uuid
      result3.should.have.properties [ "_links", "collection_name", "creation_date", "meta_modify_date", "owner", "query", "uuid" ]
      # use the collection query to recall those documents
      queryObj = JSON.parse result3.query
      result4 = await client.get_list
        query: queryObj
      result4.should.have.properties [ "_links", "files" ]
      result4.files.should.have.length NUM_DOCS
      for file in result4.files
        expecting.includes(file.uuid).should.equal true

  describe "Snapshots", ->
    it "should be able to create a snapshot from a collection by UUID", ->
      NUM_DOCS = 3
      # create a tag to group the documents
      tag = randomUuid()
      # create some random documents and put them in the catalog
      docs = (randomDocument() for x in [1..NUM_DOCS])
      expecting = []
      for doc in docs
        expecting.push doc.uuid
        doc.special_tag = tag
        result = await client.create doc
        result.should.have.properties [ "_links", "file" ]
        result.file.should.equal "/api/files/#{doc.uuid}"
      expecting.should.have.length NUM_DOCS
      # use a query to recall those documents
      result = await client.get_list
        query:
          special_tag: tag
      result.should.have.properties [ "_links", "files" ]
      result.files.should.have.length NUM_DOCS
      for file in result.files
        expecting.includes(file.uuid).should.equal true
      # create a collection out of the query
      result2 = await client.create_collection
        collection_name: "special_tag_#{tag}"
        query:
          special_tag: tag
        owner: "fbloggs"
      result2.should.have.properties [ "_links", "collection" ]
      result2.collection.should.match /\/api\/collections\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
      # recall the collection by its UUID
      uuid = result2.collection.substr 17
      result3 = await client.get_collection uuid
      result3.should.have.properties [ "_links", "collection_name", "creation_date", "meta_modify_date", "owner", "query", "uuid" ]
      # use the collection query to recall those documents
      queryObj = JSON.parse result3.query
      result4 = await client.get_list
        query: queryObj
      result4.should.have.properties [ "_links", "files" ]
      result4.files.should.have.length NUM_DOCS
      for file in result4.files
        expecting.includes(file.uuid).should.equal true
      # create a snapshot from the collection
      result5 = await client.create_snapshot result3, {}
      result5.should.have.properties [ "_links", "snapshot" ]
      # recall the snapshot by its UUID
      snapUuid = result5.snapshot.substr 15
      result6 = await client.get_snapshot snapUuid
      result6.should.have.properties [ "_links", "collection_id", "creation_date", "files", "owner", "uuid" ]
      result6.collection_id.should.equal result3.uuid
      result6.owner.should.equal result3.owner
      result6.uuid.should.equal snapUuid
      for fileUuid in result6.files
        expecting.includes(fileUuid).should.equal true

    it "should be able to obtain the files in a snapshot", ->
      NUM_DOCS = 3
      # create a tag to group the documents
      tag = randomUuid()
      # create some random documents and put them in the catalog
      docs = (randomDocument() for x in [1..NUM_DOCS])
      expecting = []
      for doc in docs
        expecting.push doc.uuid
        doc.special_tag = tag
        result = await client.create doc
        result.should.have.properties [ "_links", "file" ]
        result.file.should.equal "/api/files/#{doc.uuid}"
      expecting.should.have.length NUM_DOCS
      # use a query to recall those documents
      result = await client.get_list
        query:
          special_tag: tag
      result.should.have.properties [ "_links", "files" ]
      result.files.should.have.length NUM_DOCS
      for file in result.files
        expecting.includes(file.uuid).should.equal true
      # create a collection out of the query
      result2 = await client.create_collection
        collection_name: "special_tag_#{tag}"
        query:
          special_tag: tag
        owner: "fbloggs"
      result2.should.have.properties [ "_links", "collection" ]
      result2.collection.should.match /\/api\/collections\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
      # recall the collection by its UUID
      uuid = result2.collection.substr 17
      result3 = await client.get_collection uuid
      result3.should.have.properties [ "_links", "collection_name", "creation_date", "meta_modify_date", "owner", "query", "uuid" ]
      # use the collection query to recall those documents
      queryObj = JSON.parse result3.query
      result4 = await client.get_list
        query: queryObj
      result4.should.have.properties [ "_links", "files" ]
      result4.files.should.have.length NUM_DOCS
      for file in result4.files
        expecting.includes(file.uuid).should.equal true
      # create a snapshot from the collection
      result5 = await client.create_snapshot result3, {}
      result5.should.have.properties [ "_links", "snapshot" ]
      # recall the snapshot by its UUID
      snapUuid = result5.snapshot.substr 15
      result6 = await client.get_snapshot snapUuid
      result6.should.have.properties [ "_links", "collection_id", "creation_date", "files", "owner", "uuid" ]
      result6.collection_id.should.equal result3.uuid
      result6.owner.should.equal result3.owner
      result6.uuid.should.equal snapUuid
      result6.files.should.have.length NUM_DOCS
      for fileUuid in result6.files
        expecting.includes(fileUuid).should.equal true
      # obtain the files in the snapshot by its UUID
      result7 = await client.get_snapshot_files snapUuid
      result7.should.have.properties [ "_links", "files" ]
      result7.files.should.have.length NUM_DOCS
      for file in result7.files
        file.should.have.properties [ "logical_name", "uuid" ]
        expecting.includes(file.uuid).should.equal true

#-----------------------------------------------------------------------
# end of integrationTest.coffee
