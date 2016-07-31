{markdownToHTML, getDocURL, convertCodeBlocksToAtomEditors} = require './utils'
AtomJolie = require '../main'
{Emitter, Disposable, CompositeDisposable, File} = require 'atom'
{$, ScrollView} = require 'atom-space-pen-views'

module.exports =
class JolieDocsView extends ScrollView

  color = atom.config.get('atom-jolie.messageColor').toLowerCase()

  @content: ->
    @div class: 'jolie-docs-view native-key-bindings', tabindex: -1, =>
      @div class: 'header', =>
        @div class: 'pull-left badge-docs', 'Docs'
        @a class: 'header-link pull-right', 'Online Docs'
        @hr class: 'header-hr'
      @div class: 'markdownContent docsContent padded'

  constructor: ({@viewId, @source}) ->
    super
    @disposables = new CompositeDisposable

  attached: ->
    return if @isAttached
    @isAttached = true

    resolve = =>
      @handleEvents()
      @renderDocs()

    if atom.workspace?
      resolve()
    else
      @disposables.add atom.packages.onDidActivateInitialPackages(resolve)


  serialize: ->
    deserializer: 'JolieDocsView'
    viewId: @viewId
    source: @source

  destroy: ->
    @disposables.dispose()

  handleEvents: ->
    atom.commands.add @element,
      'core:move-up': =>
        @scrollUp()
      'core:move-down': =>
        @scrollDown()
      'core:copy': (event) =>
        event.stopPropagation() if @copyToClipboard()

    @on 'click', ".header-link", ->
      require('shell').openExternal("http://docs.jolie-lang.org/")

  setSource: (@source) ->

    docsElement = @element.querySelector('.docsContent')

    docsElement.innerHTML = markdownToHTML(@source)

    docsElement.innerHTML = docsElement.innerHTML.replace(/&lt;/g,'<')
      .replace(/&gt;/g,'>')

    convertCodeBlocksToAtomEditors(docsElement)

    # if color?
      # $(".badge-docs").addClass("color-#{color}")
      # $(".header-hr").addClass("color-#{color}")
      # $(".header-link").addClass("color-#{color}")

    $("a").click ->
      if $(this).hasClass("header-link") or $(this).attr('href').startsWith("http")
        return
      AtomJolie.docsProvider.addViewForElement(this.innerHTML, $(this).attr('href'))

    unless @source?
      @renderDocs()

  renderDocs: =>
    $(@element.querySelectorAll('.markdownContent')).css('display', 'none')
    @element.querySelector('.docsContent').style.display = ''

  getTitle: ->
    "Jolie Docs - #{@viewId}"

  getIconName: ->
    "file-text"

  getURI: ->
    "atom-jolie://jolie-docs-views/#{@viewId}"

  copyToClipboard: ->
    selection = window.getSelection()
    selectedText = selection.toString()
    atom.clipboard.write(selectedText)
    true
