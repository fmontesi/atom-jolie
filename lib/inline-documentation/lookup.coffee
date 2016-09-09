
wordRegExp = /^[	 ]*$|[^\s\/\\\(\)"',\.;@<>~#\$%\^&\*\|\+=\[\]\{\}`\-…]+|[\/\\\(\)"',\.;<>~!#\$%\^&\*\|\+=\[\]\{\}`\?\-…]+/g

getDocumentation = (editor, position) ->
  object = getWord(editor, position)
  subject = null

  if object?
    word = object.word
    range = object.range
  else
    return

  if (editor.getGrammar().scopeName != 'source.jolie')
    return null

  row = editor.getBuffer().lineForRow(range.start.row)

  if row.includes("Protocol:")
    json = require './protocols.json'
    find = (i for i in json.protocols when i.name is word.toLowerCase())[0]
    if find?
      subject =
        word: word
        range: range
        badge: "protocol"
        link: find.link
        text: find.text
  return subject


getWord = (editor, position) ->

  word = ''
  range = new Range(position, position)

  editor.scanInBufferRange wordRegExp, editor.getBuffer().rangeForRow(position.row), (iterator) ->
    if iterator.range.containsPoint(position)
      word = iterator.matchText
      range = iterator.range
      iterator.stop()
    else if iterator.range.end.column > position.column
      iterator.stop()

  return {word: word, range: range}

module.exports = {getWord, getDocumentation}
