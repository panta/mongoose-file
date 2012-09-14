## About mongoose-file

[mongoose][] plugin that adds a file field to a mongoose schema.
This is especially suited to handle file uploads with [nodejs][]/[expressjs][].

## Install

npm install mongoose-file

## Usage

The plugin adds a file field to the mongoose schema. Assigning to the **file** property of the field causes (optionally) the file to be moved into place (see `upload_to` below) and the field sub-properties to be assigned.
This field expects to be assigned (to its `file` sub-field, as said) an object with a semantic like that of an [expressjs][] request file object (see [req.files](http://expressjs.com/api.html#req.files)).
Assigning to the field `file` property caused the instance to be marked as modified (but it's not saved automatically).

The field added to the schema is a compound JavaScript object, containing the following fields:

* `name` - original name of the uploaded file, without the directory components
* `path` - the full final path where the uploaded file is stored
* `rel` - path relative to a user specified directory (see the `relative_to` option below)
* `type` - the file type
* `size` - the file size
* `lastModified` - the uploaded file object `lastModifiedDate` value

These values are extracted from the request-like file object received on assignment.

When attaching the plugin, it's possible to specify an options object containing the following parameters:

* `name` - the field name (`name`), which defaults to `file`
* `change_cb` - a callback function called whenever the file path is changed. It's called in the context of the model instance, and receives as parameters the field name, the new path value and the previous one.
* `upload_to` - the directory name where the file will be moved from the temporary upload directory. If this is a function instead of a string, it will be called in the context of the model instance with the file object as a parameter, and it must return a string
* `relative_to` - the base directory name used to construct the relative path stored in the `rel` subfield. If this is a function, it will be called in the context of the model instance with the file object as a parameter. This can be useful to get a path usable from HTML, like in `<img>` `src` attribute.

### JavaScript

```javascript
var mongoose = require('mongoose');
var filePluginLib = require('mongoose-file');
var filePlugin = filePluginLib.filePlugin;
var make_upload_to_model = filePluginLib.make_upload_to_model;

...

var uploads_base = path.join(__dirname, "uploads");
var uploads = path.join(uploads_base, "u");
...

var SampleSchema = new Schema({
  ...
});
SampleSchema.plugin(filePlugin, {
	name: "photo",
	upload_to: make_upload_to_model(uploads, 'photos'),
	relative_to: uploads_base
});
var SampleModel = db.model("SampleModel", SampleSchema);
```

### [CoffeeScript][]

```coffeescript
mongoose = require 'mongoose'
filePluginLib = require 'mongoose-file'
filePlugin = filePluginLib.filePlugin
make_upload_to_model = filePluginLib.make_upload_to_model

...
uploads_base = path.join(__dirname, "uploads")
uploads = path.join(uploads_base, "u")
...

SampleSchema = new Schema
  ...
SampleSchema.plugin filePlugin
	name: "photo"
	upload_to: make_upload_to_model(uploads, 'photos')
	relative_to: uploads_base
SampleModel = db.model("SampleModel", SampleSchema)
```

## Bugs and pull requests

Please use the github [repository][] to notify bugs and make pull requests.

## License

This software is © 2012 Marco Pantaleoni, released under the MIT licence. Use it, fork it.

See the LICENSE file for details.

[mongoose]: http://mongoosejs.com
[CoffeeScript]: http://jashkenas.github.com/coffee-script/
[nodejs]: http://nodejs.org/
[expressjs]: http://expressjs.com
[Mocha]: http://visionmedia.github.com/mocha/
[repository]: http://github.com/panta/mongoose-file
