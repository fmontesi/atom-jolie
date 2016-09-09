{CompositeDisposable} = require 'atom'
{getWord} = require './lookup'
AtomJolie = require '../main'
url = require 'url'
request = require 'request'

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
    docsPath = "https://raw.githubusercontent.com/jolie/docs/master/documentation/" + link.slice(0,-4) + "md"

    request.get (docsPath), (err, r, body) ->
      uri = "atom-jolie://jolie-docs-views/#{word}"
      options = {searchAllPanes: true, split: 'right'}
      atom.workspace.open(uri, options).then (jolieDocsView) =>
        jolieDocsView.setSource(body)
