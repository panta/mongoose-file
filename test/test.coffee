chai = require 'chai'
assert = chai.assert
expect = chai.expect
should = chai.should()
mongoose = require 'mongoose'

fs = require 'fs'
path = require 'path'

index = require '../src/index'

PLUGIN_TIMEOUT = 800

rmDir = (dirPath) ->
  try
    files = fs.readdirSync(dirPath)
  catch e
    return
  if files.length > 0
    i = 0

    while i < files.length
      continue if files[i] in ['.', '..']
      filePath = dirPath + "/" + files[i]
      if fs.statSync(filePath).isFile()
        fs.unlinkSync filePath
      else
        rmDir filePath
      i++
  fs.rmdirSync dirPath

db = mongoose.createConnection('localhost', 'mongoose_file_tests')
db.on('error', console.error.bind(console, 'connection error:'))

uploads_base = __dirname + "/uploads"
uploads = uploads_base + "/u"

tmpFilePath = '/tmp/mongoose-file-test.txt'
uploadedDate = new Date()
uploadedFile =
  size: 12345
  path: tmpFilePath
  name: 'photo.png'
  type: 'image/png',
  hash: false,
  lastModifiedDate: uploadedDate

Schema = mongoose.Schema
ObjectId = Schema.ObjectId

SimpleSchema = new Schema
  name: String
  title: String

describe 'WHEN working with the plugin', ->
  before (done) ->
    done()

  after (done) ->
    SimpleModel = db.model("SimpleModel", SimpleSchema)
    SimpleModel.remove {}, (err) ->
      return done(err)  if err
    rmDir(uploads_base)
    done()

  describe 'library', ->
    it 'should exist', (done) ->
      should.exist index
      done()

  describe 'adding the plugin', ->
    it 'should work', (done) ->

      SimpleSchema.plugin index.filePlugin,
        name: "photo",
        upload_to: index.make_upload_to_model(uploads, 'photos'),
        relative_to: uploads_base
      SimpleModel = db.model("SimpleModel", SimpleSchema)
  
      instance = new SimpleModel({name: 'testName', title: 'testTitle'})
      should.exist instance
      should.equal instance.isModified(), true
      instance.should.have.property 'name', 'testName'
      instance.should.have.property 'title', 'testTitle'
      instance.should.have.property 'photo'
      should.exist instance.photo
      instance.photo.should.have.property 'name'
      instance.photo.should.have.property 'path'
      instance.photo.should.have.property 'rel'
      instance.photo.should.have.property 'type'
      instance.photo.should.have.property 'size'
      instance.photo.should.have.property 'lastModified'
      should.not.exist instance.photo.name
      should.not.exist instance.photo.path
      should.not.exist instance.photo.rel
      should.not.exist instance.photo.type
      should.not.exist instance.photo.size
      should.not.exist instance.photo.lastModified
      done()

  describe 'assigning to the instance field', ->
    it 'should populate subfields', (done) ->

      SimpleSchema.plugin index.filePlugin,
        name: "photo",
        upload_to: index.make_upload_to_model(uploads, 'photos'),
        relative_to: uploads_base
      SimpleModel = db.model("SimpleModel", SimpleSchema)
  
      instance = new SimpleModel({name: 'testName', title: 'testTitle'})
      should.exist instance
      should.exist instance.photo
      should.equal instance.isModified(), true

      fs.writeFile tmpFilePath, "Dummy content here.\n", (err) ->
        return done(err)  if (err)

        instance.set('photo.file', uploadedFile)
        # give the plugin some time to notice the assignment and execute its
        # asynchronous code
        setTimeout ->
          should.equal instance.isModified(), true
          should.exist instance.photo.name
          should.exist instance.photo.path
          should.exist instance.photo.rel
          should.exist instance.photo.type
          should.exist instance.photo.size
          should.exist instance.photo.lastModified

          should.equal instance.photo.name, uploadedFile.name
          should.not.equal instance.photo.path, uploadedFile.path
          should.equal instance.photo.type, uploadedFile.type
          should.equal instance.photo.size, uploadedFile.size
          should.equal instance.photo.lastModified, uploadedFile.lastModifiedDate

          done()
        , PLUGIN_TIMEOUT

  describe 'assigning to the instance field', ->
    it 'should mark as modified', (done) ->

      SimpleSchema.plugin index.filePlugin,
        name: "photo",
        upload_to: index.make_upload_to_model(uploads, 'photos'),
        relative_to: uploads_base
      SimpleModel = db.model("SimpleModel", SimpleSchema)
  
      instance = new SimpleModel({name: 'testName', title: 'testTitle'})
      should.exist instance
      should.equal instance.isModified(), true

      instance.save (err) ->
        return done(err)  if err

        should.equal instance.isModified(), false

        fs.writeFile tmpFilePath, "Dummy content here.\n", (err) ->
          return done(err)  if (err)

          instance.set('photo.file', uploadedFile)
          # give the plugin some time to notice the assignment and execute its
          # asynchronous code
          setTimeout ->
            should.equal instance.isModified(), true

            instance.save (err) ->
              return done(err)  if err

              should.equal instance.isModified(), false

              done()
          , PLUGIN_TIMEOUT
