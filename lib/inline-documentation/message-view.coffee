{$} = require 'atom-space-pen-views'
AtomJolie = require '../main'
{getDocURL} = require './utils'

class MessageView extends HTMLElement

  initialize: (msg) ->
    @classList.add("color-#{msg.color}")

    if msg.correctIndentation is true
      @classList.add('indentation-correction')

    if msg.correctLastLine is true
      @classList.add('empty-lastline-correction')

    if msg.positioning == "below"
      @classList.add("is-below")

    if msg.selected is true
      @classList.add("is-selected")

    header = document.createElement('div')
    header.classList.add('header')
    @appendChild(header)

    badge = document.createElement('div')
    badge.classList.add('badge')
    badge.textContent = msg.badge
    header.appendChild(badge)

    if msg.showBadge is true
      badge.classList.add 'show-badge'

    if msg.name?
      name = document.createElement('span')
      name.classList.add('name')
      name.innerHTML = msg.name
      header.appendChild(name)

    message = document.createElement('div')
    message.classList.add('message')

    @renderContent message, msg
    @appendChild(message)

    footer = document.createElement('div')
    footer.classList.add('footer')
    @appendChild(footer)

    docs = document.createElement('button')
    footer.appendChild(docs)
    docs.innerHTML = "docs"
    docs.classList.add('btn', 'btn-footer')
    $(docs).click ->
      file = AtomJolie.messageProvider.messages[0].link
      word = AtomJolie.messageProvider.messages[0].name
      AtomJolie.docsProvider.showJolieDocs(word, file)

    online = document.createElement('button')
    footer.appendChild(online)
    online.innerHTML = "online"
    online.classList.add('btn', 'btn-footer')
    $(online).click ->
      require('shell').openExternal(getDocURL(AtomJolie.messageProvider.messages[0].link))

  renderContent: (message, msg) ->
    message.textContent = msg.text

  destroy: ->
    @element.remove()

  getElement: ->
    @element

fromMsg = (msg) ->
  MessageLine = new MessageElement()
  MessageLine.initialize(msg)
  MessageLine

module.exports = MessageElement = document.registerElement('inline-message', prototype: MessageView.prototype)
module.exports.fromMsg = fromMsg
