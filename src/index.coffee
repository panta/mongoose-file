mongoose = require('mongoose')

path = require('path')
fs = require('fs')
mkdirp = require('mkdirp')

Schema = mongoose.Schema
ObjectId = Schema.ObjectId

# ---------------------------------------------------------------------
#   helper functions
# ---------------------------------------------------------------------

# Extend a source object with the properties of another object (shallow copy).
extend = (dst, src) ->
  for key, val of src
    dst[key] = val
  dst

# Add missing properties from a `src` object.
defaults = (dst, src) ->
  for key, val of src
    if not (key of dst)
      dst[key] = val
  dst

# Add a new field by name to a mongoose schema
addSchemaField = (schema, pathname, fieldSpec) ->
  fieldSchema = {}
  fieldSchema[pathname] = fieldSpec
  schema.add fieldSchema

addSchemaSubField = (schema, masterPathname, subName, fieldSpec) ->
  addSchemaField schema, "#{masterPathname}.#{subName}", fieldSpec

is_callable = (f) ->
  (typeof f is 'function')

# ---------------------------------------------------------------------
#   M O N G O O S E   P L U G I N S
# ---------------------------------------------------------------------
# http://mongoosejs.com/docs/plugins.html

filePlugin = (schema, options={}) ->
  pathname = options.name or 'file'
  onChangeCb = options.change_cb or null
  upload_to = options.upload_to or null     # if null, uploaded file is left in the temp upload dir
  relative_to = options.relative_to or null # if null, .rel field is equal to .path

  # fieldSchema = {}
  # fieldSchema[pathname] = {} # mixed: { type: Schema.Types.Mixed }
  # schema.add fieldSchema
  # fieldSchema = {}
  # fieldSchema["#{pathname}.name"] = String
  # schema.add fieldSchema
  # fieldSchema = {}
  # fieldSchema["#{pathname}.path"] = String
  # schema.add fieldSchema
  # fieldSchema = {}
  # fieldSchema["#{pathname}.type"] = {type: String}
  # schema.add fieldSchema
  # fieldSchema = {}
  # fieldSchema["#{pathname}.size"] = Number
  # schema.add fieldSchema
  # fieldSchema = {}
  # fieldSchema["#{pathname}.lastModified"] = Date
  # schema.add fieldSchema

  # fieldSchema = {}
  # fieldSchema[pathname] =
  #   name: String
  #   path: String
  #   rel: String
  #   type: String
  #   size: Number
  #   lastModified: Date
  # schema.add fieldSchema
  # fieldSchema = {}
  # fieldSchema[pathname] = {} # mixed: { type: Schema.Types.Mixed }
  # schema.add fieldSchema

  addSchemaField schema, pathname, {} # mixed: { type: Schema.Types.Mixed }
  addSchemaSubField schema, pathname, 'name', { type: String, default: () -> null }
  addSchemaSubField schema, pathname, 'path', { type: String, default: () -> null }
  addSchemaSubField schema, pathname, 'rel', { type: String, default: () -> null }
  addSchemaSubField schema, pathname, 'type', { type: String, default: () -> null }
  addSchemaSubField schema, pathname, 'size', { type: Number, default: () -> null }
  addSchemaSubField schema, pathname, 'lastModified', { type: Date, default: () -> null }

  schema.virtual("#{pathname}.file").set (fileObj) ->
    u_path = fileObj.path
    if upload_to
      # move from temp. upload directory to final destination
      if is_callable(upload_to)
        dst = upload_to.call(@, fileObj)
      else
        dst = path.join(upload_to, fileObj.name)
      dst_dirname = path.dirname(dst)
      mkdirp dst_dirname, (err) =>
        throw err  if err
        fs.rename u_path, dst, (err) =>
          if (err)
            # delete the temporary file, so that the explicitly set temporary upload dir does not get filled with unwanted files
            fs.unlink u_path, (err) =>
              throw err  if err
            throw err
          console.log("moved from #{u_path} to #{dst}")
          rel = dst
          if relative_to
            if is_callable(relative_to)
              rel = relative_to.call(@, fileObj)
            else
              rel = path.relative(relative_to, dst)
          @set("#{pathname}.name", fileObj.name)
          @set("#{pathname}.path", dst)
          @set("#{pathname}.rel", rel)
          @set("#{pathname}.type", fileObj.type)
          @set("#{pathname}.size", fileObj.size)
          @set("#{pathname}.lastModified", fileObj.lastModifiedDate)
          @markModified(pathname)
    else
      dst = u_path
      rel = dst
      if relative_to
        if is_callable(relative_to)
          rel = relative_to.call(@, fileObj)
        else
          rel = path.relative(relative_to, dst)
      @set("#{pathname}.name", fileObj.name)
      @set("#{pathname}.path", dst)
      @set("#{pathname}.rel", rel)
      @set("#{pathname}.type", fileObj.type)
      @set("#{pathname}.size", fileObj.size)
      @set("#{pathname}.lastModified", fileObj.lastModifiedDate)
      @markModified(pathname)
  schema.pre 'set', (next, path, val, typel) ->
    if path is "#{pathname}.path"
      if onChangeCb
        oldValue = @get("#{pathname}.path")
        console.log("old: #{oldValue} new: #{val}")
        onChangeCb.call(@, pathname, val, oldValue)
    next()

make_upload_to_model = (basedir, subdir) ->
  b_dir = basedir
  s_dir = subdir
  upload_to_model = (fileObj) ->
    dstdir = b_dir
    if s_dir
      dstdir = path.join(dstdir, s_dir)
    id = @get('id')
    if id
      dstdir = path.join(dstdir, "#{id}")
    path.join(dstdir, fileObj.name)
  upload_to_model

# -- exports ----------------------------------------------------------

module.exports =
  filePlugin: filePlugin
  make_upload_to_model: make_upload_to_model
