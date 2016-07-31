MessageView = require './message-view'

module.exports =
class Message
  constructor: ({editor, name, color, range, link, text, showBadge, badge}) ->
    @editor = editor
    @name = name
    @color = color
    @text = text
    @badge = badge
    @link = link
    @destroyed = false
    @selected = false
    @offsetFromTop = 0
    @highlight = null
    @messageBubble = null
    @correctIndentation = false
    @indentLevel = 0
    @longestLineLength = 0
    @showBadge = showBadge
    @badge = badge

    if @editor is null or @editor == ''
      return

    mark = @editor.markBufferRange(range, {invalidate: 'inside', inlineMsg: true})
    @offsetFromTop = @longestLineInMarker(mark)

    range = mark.getBufferRange()
    @smallSnippet = range.start.row == range.end.row
    @positioning =  'below'

    if @smallSnippet is true
      @highlight = @editor.decorateMarker(
        mark
        {
          type: 'highlight',
          class: @formatHighlightClass()
        }
      )
    @showBubble()


  requiresIndentCorrection: ->
    range = @getRange()
    @indentLevel = @editor.indentationForBufferRow(range.start.row)
    if range.start.column > 0 and range.start.line == range.end.line
      return false
    lineLength = @editor.lineTextForScreenRow(range.end.row).length
    rowSpan = Math.abs(range.end.row - range.start.row)

    return @indentLevel >= 1 or (rowSpan == 0 and lineLength == 0)

  requiresLastLineCorrection: ->
    range = @getRange()
    lineLength = @editor.lineTextForScreenRow(range.end.row).length
    rowSpan = Math.abs(range.end.row - range.start.row)
    return lineLength == 0 and rowSpan != 0


  showBubble: () ->
    mark = @highlight.getMarker()
    anchorRange = @calculateAnchorRange(mark)
    anchor = @editor.markBufferRange(anchorRange, {invalidate: 'never'})

    @correctIndentation = @requiresIndentCorrection()
    @correctLastLine = @requiresLastLineCorrection()

    shrinkWrap = document.createElement('div')
    shrinkWrap.classList.add('shrink-wrap')
    shrinkWrap.appendChild MessageView.fromMsg(this)

    @messageBubble = @editor.decorateMarker(
      anchor
      {
        type: 'overlay',
        class: 'inline-message'
        item: shrinkWrap
      }
    )
    if @debug is true
      @updateDebugText()

    mark.onDidChange (event) => @updateMarkerPosition(event)

  removeBubble: () ->
    @messageBubble.destroy()

  formatHighlightClass: () ->
    classList = ["inline-message-selection-highlight"]
    classList.push("color-#{@color}")
    if @selected
      classList.push("is-selected")
    if @smallSnippet
      classList.push("is-small-snippet")
    return classList.join ' '


  updateAnchor: () ->
    anchorRange = @calculateAnchorRange(@highlight.getMarker())
    @messageBubble.getMarker().setBufferRange(anchorRange)


  calculateAnchorRange: (marker) ->
    range = marker.getBufferRange()
    start = [range.start.row,range.start.column]
    end = [range.end.row,range.end.column]
    anchorRange = [start, end]
    if @smallSnippet is true
      anchorRange[0][1] = anchorRange[0][1] + 1
    else
      anchorRange[0][0] = anchorRange[1][0]
      anchorRange[0][1] = 1
    anchorRange[1] = anchorRange[0].slice()
    return anchorRange

  longestLineInMarker: (marker) ->
    screenRange = marker.getScreenRange()
    longestLineRowOffset = 0
    longestLineLength = 0
    offset = 0
    for row in [screenRange.start.row..screenRange.end.row]
      currentRowLength = @editor.lineTextForScreenRow(row).length
      if longestLineLength < currentRowLength
        longestLineLength = currentRowLength
        longestLineRowOffset = offset
      offset = offset + 1
    if longestLineLength > 40
      @longestLineLength = longestLineLength
    else
      @longestLineLength = 40
    longestLineRowOffset


  refresh: () ->
    if @selected is true
      @addMessageBubbleClass('is-selected')
    else
      @removeMessageBubbleClass('is-selected')

    if @showBadge is true
      @addMessageBubbleClass('show-badge')
    else
      @removeMessageBubbleClass('show-badge')

    if @smallSnippet is true
      @highlight.setProperties
        type:'highlight'
        class:@formatHighlightClass()

    else
      @highlight.setProperties
        type:'line',
        class:@formatLineClass()

    if @correctIndentation is true
      @addMessageBubbleClass('indentation-correction')
    else
      @removeMessageBubbleClass('indentation-correction')

  updateMarkerPosition: (event) ->

    if event.isValid is false
      @destroy()

    @correctIndentation = @requiresIndentCorrection()
    @correctLastLine = @requiresLastLineCorrection()
    if @correctIndentation is true
      @addMessageBubbleClass 'indentation-correction'
    else
      @removeMessageBubbleClass 'indentation-correction'

    if @correctLastLine is true
      @addMessageBubbleClass 'empty-lastline-correction'
    else
      @removeMessageBubbleClass 'empty-lastline-correction'

    newOffsetFromTop = @longestLineInMarker(@highlight.getMarker())
    mark = @messageBubble.getMarker()
    if newOffsetFromTop != @offsetFromTop
      @removeMessageBubbleClass "up-#{@offsetFromTop}"
      @addMessageBubbleClass "up-#{newOffsetFromTop}"
      @offsetFromTop = newOffsetFromTop

    @updateAnchor()
    if @debug is true
      @updateDebugText()


  addMessageBubbleClass: (cls) ->
    @messageBubble.properties.item.firstChild.classList.add cls

  removeMessageBubbleClass: (cls) ->
    @messageBubble.properties.item.firstChild.classList.remove cls


  update: (newData) ->
    requiresRefresh = false
    if 'selected' of newData
      if @selected != newData.selected
        @selected = newData.selected
        requiresRefresh = true

    if 'showBadge' of newData
      if @showBadge != newData.showBadge
        @showBadge = newData.showBadge
        requiresRefresh = true

    if requiresRefresh is true
      @refresh()

  getRange: () ->
    @highlight.getMarker().getBufferRange()

  destroy: ->
    @destroyed = true
    if @highlight isnt null
      @highlight.getMarker().destroy()
      @highlight.destroy()
    if @messageBubble isnt null
      @messageBubble.getMarker().destroy()
      @messageBubble.destroy()
