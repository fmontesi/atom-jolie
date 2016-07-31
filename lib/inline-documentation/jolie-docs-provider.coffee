{CompositeDisposable} = require 'atom'
{getWord} = require './lookup'
AtomJolie = require '../main'
url = require 'url'
fs = require 'fs'

JolieDocsView = null

createJolieDocsView = (state) ->
  JolieDocsView ?= require './jolie-docs-view'
  new JolieDocsView(state)

atom.deserializers.add
  name: 'JolieDocsView'
  deserialize: (state) ->
    if state.viewId
      createJolieDocsView(state)

module.exports =
class JolieDocsProvider

  constructor: ->
    @subscriptions = new CompositeDisposable

    atom.workspace.addOpener (uriToOpen) ->
      try
        {protocol, host, pathname} = url.parse(uriToOpen)
      catch error
        return
      return unless protocol is 'atom-jolie:'
      try
        pathname = decodeURI(pathname) if pathname
      catch error
        return
      if host is 'jolie-docs-views'
        createJolieDocsView(viewId: pathname.substring(1))

  dispose: ->
    @subscriptions.dispose()

  showJolieDocs: (word, link) ->
    @addViewForElement(word, link)

  addViewForElement: (word, link) ->
    docsPath = AtomJolie.projectPath + "/inline-documentation/documentation/" + link.slice(0,-4) + "md"
    foo = ->
      fs.readFileSync docsPath, 'utf8'
    result = foo()
    uri = "atom-jolie://jolie-docs-views/#{word}"
    options = {searchAllPanes: true, split: 'right'}

    atom.workspace.open(uri, options).then (jolieDocsView) =>
      jolieDocsView.setSource(result)
