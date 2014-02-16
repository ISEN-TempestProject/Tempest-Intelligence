@page generators Generators
@parent index
@description JavaScriptMVC comes with the following generators:


@signature `js jmvc/generate/app path`

@param {String} path The lowercase directory your application
    will be placed within. Keep application names short because they 
    are used as namespaces.  The last part of the path 
    will be taken to be your application's name.

Creates a JavaScriptMVC application structure.


@signature `js jmvc/generate/control app/controls/video`

@param {String} app/controls/video The moduleId name of your control. 

Creates a [can.Control] and test files.


@signature `js jmvc/generate/model app/models/name`

@param {String} `app/models/name`  The name of the model.

Creates a [can.Model] and test files.


@signature `js jmvc/generate/page path/to/app path/to/page.html`

@param {String} path/to/app The path to your apps folder. 
@param {String} path/to/page.html The path to the page you want to create. 

Creates a page that loads steal.js and an application.


@signature `js jmvc/generate/plugin path/to/plugin`

@param path/to/plugin The path to where you want your plugin. 

Create a file and folder structure for a basic jQuery plugin.


@signature `js jmvc/generate/scaffold app/models/modelname`

@param {String} app/models/modelname The moduleId of you want to create CRUD functionality for.

Creates the controls, models, and fixtures used to provide basic CRUD functionality.
