marked = require('marked');

markdownToHTML = (markdownSource) ->
  marked.setOptions({
    renderer: new marked.Renderer(),
    gfm: true,
    tables: true,
    breaks: false,
    pedantic: false,
    sanitize: true,
    smartLists: true,
    smartypants: false
  });
  marked(markdownSource)

getDocURL = (docsPath) ->
  "http://docs.jolie-lang.org/#!documentation" + docsPath

convertCodeBlocksToAtomEditors = (domFragment, defaultLanguage='text') ->
  if fontFamily = atom.config.get('editor.fontFamily')
    for codeElement in domFragment.querySelectorAll('code')
      codeElement.style.fontFamily = fontFamily

  for preElement in domFragment.querySelectorAll('pre, code')
    if preElement.tagName == 'PRE'
      codeBlock = preElement.firstElementChild ? preElement
      fenceName = codeBlock.getAttribute('class')?.replace(/^lang-/, '') ? defaultLanguage

      editorElement = document.createElement('atom-text-editor')
      editorElement.setAttributeNode(document.createAttribute('gutter-hidden'))
      editorElement.removeAttribute('tabindex') # make read-only

      preElement.parentNode.insertBefore(editorElement, preElement)
      preElement.remove()

      editor = editorElement.getModel()
      editor.setSoftWrapped(true)

      # remove the default selection of a line in each editor
      editor.getDecorations(class: 'cursor-line', type: 'line')[0].destroy()
      editor.setText(codeBlock.textContent.trim())

      if grammar = atom.grammars.grammarForScopeName('source.jolie')
        editor.setGrammar(grammar)

  domFragment

module.exports = {markdownToHTML, convertCodeBlocksToAtomEditors, getDocURL}
