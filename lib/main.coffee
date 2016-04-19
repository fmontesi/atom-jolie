helpers = require 'atom-linter'
{ BufferedProcess } = require 'atom'

module.exports =
  config: {}

  activate: ->
    require( "atom-package-deps" ).install( "atom-jolie" );
