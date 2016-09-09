module.exports =
  config: {}

{CompositeDisposable} = require 'atom'

module.exports = AtomJolie =

  config:
    messageColor:
      type: "string"
      default: "blue"
      description: "Message background color"
      enum: ["green", "blue", "yellow", "red"]
    showBadge:
      type: "boolean"
      default: true
      description: "Show a badge on every message"

  docsProvider: null
  messageProvider: null
  projectPath: null

  activate: (state) ->
    # require( "atom-package-deps" ).install( "atom-jolie" );

    JolieDocsProvider = require('./inline-documentation/jolie-docs-provider')
    MessageProvider = require('./inline-documentation/message-provider')

    @docsProvider = new JolieDocsProvider
    @messageProvider = new MessageProvider

  deactivate: ->
    @docsProvider.dispose()
    @docsProvider = null
    @messageProvider.dispose()
    @messageProvider = null
