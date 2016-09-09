{CompositeDisposable} = require 'atom'
Message = require './message-model'
{getWord, getDocumentation} = require './lookup'
AtomJolie = require '../main'

module.exports =
class MessageProvider

  subscriptions: null
  messages:[]
  focus: null
  activeEditor: null
  fontSizePx: null
  lineHeightEm: null

  constructor: (state) ->

    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-text-editor',
      'atom-jolie:show-jolie-inline-docs': (event) =>
        @showJolieInlineDocs()

    @activeEditor = atom.workspace.getActiveTextEditor()

    @subscriptions.add @cursorMovementSubscription()
    @updateStyle()

    @subscriptions.add atom.workspace.onDidChangeActivePaneItem (item) =>
      @activeEditor = atom.workspace.getActiveTextEditor()
      @subscriptions.add @cursorMovementSubscription()

    @subscriptions.add atom.config.observe 'editor.lineHeight', (newValue) =>
      if @lineHeightEm != newValue
        @updateStyle()

    @subscriptions.add atom.config.observe 'editor.fontSize', (newValue) =>
      if @fontSizePx != newValue
        @updateStyle()

    @subscriptions.add atom.config.observe 'atom-jolie.showBadge', (newValue) =>
      @messages.map (msg) -> msg.update({showBadge:newValue})

  deactivate: ->
    @subscriptions.dispose()
    @clear()

  cursorMovementSubscription: () ->
    if @activeEditor
      @activeEditor.onDidChangeCursorPosition (cursor) => @selectUnderCursor()

  selectUnderCursor: (cursor) ->
    if @messages.length == 0
      return

    if not @activeEditor
      return

    cursor = @activeEditor.getLastCursor()
    cursorRange = cursor.getMarker().getBufferRange()
    closest = null
    closestRange = null
    for msg in @messages
      msgRange = msg.getRange()
      if msgRange.containsPoint(cursorRange.start) and msgRange.containsPoint(cursorRange.end)
        if closest is null
          closest = msg
          closestRange = msgRange
        else
          if closestRange.compare(msgRange) == 1 # this range starts after the argument or is contained by it.
            closest = msg
            closestRange = msgRange
      else if closest isnt null
        # Then we've passed the messages that are relevant
        break
    if closest isnt null
      @select(closest)
    else
      @clearSelection()
      @clear()

  clear: ->
    @messages.map (msg) -> msg.destroy()

  removeDestroyed: (messages) ->
    return (msg for msg in messages when msg.destroyed isnt true)

  clearSelection: () ->
    @messages.map (msg) -> msg.update({'selected':false})
    @focus = null

  select: (msg) ->
    @messages = @removeDestroyed(@messages)

    @messages.map (msg) -> msg.update({'selected':false})
    @focus = msg
    msg.update({'selected':true})

  updateStyle: () ->
    @lineHeightEm = atom.config.get("editor.lineHeight")
    @fontSizePx = atom.config.get("editor.fontSize")
    lineHeight = @lineHeightEm * @fontSizePx

  addMessage: ({name, range, text, badge, link}) ->
    color = atom.config.get('atom-jolie.messageColor').toLowerCase()
    showBadge = atom.config.get 'atom-jolie.showBadge'
    unless badge?
      badge = '•'
    msg = new Message
      name: name
      editor: @activeEditor
      color: color
      range: range
      text: text
      showBadge: showBadge
      badge: badge
      link: link
    @messages.push msg
    @selectUnderCursor()
    return msg

  showJolieInlineDocs: ->
    editor = atom.workspace.getActiveTextEditor()
    position = editor.getCursorBufferPosition()
    object = getDocumentation(editor, position)
    if object?
      @addMessage
        name: object.word
        range: object.range
        text: object.text
        badge: object.badge
        link: object.link
