# USO, meet Markdown. One day Userscripts.org used plain HTML for writing comments and guides,
# little did he know about a young lass that called herself Markdown.
# Userscripts.org fell madly in love.

# ==UserScript==  
# @name           USO, meet Markdown.  
# @namespace      http://userscripts.org/users/tim  
# @description    Markdown gets married to Userscript.org  
# @include        http://userscripts.org/topics/*  
# @require        http://userscripts.org/scripts/source/70908.user.js  
# ==/UserScript==

# Anonymous function wrapper, so we don't step on anyones toes
(->

  #### Post class
  # This class represents a post on Userscripts.org, usually found in a topic
  class Post
    constructor: (element) ->
      @element: element

    element: null

  #### Guide class
  # Represents a guide on Userscripts.org
  class Guide
    constructor: (element) ->

  #### Editor class
  # Represents the current editor in the page
  class Editor
    constructor: (element) ->
      @element: element

      if 'DIV' is element.nodeName
        @initFromReply()

    element: null

    # Here we modify the reply box, and over-ride a function on the USO
    # page that gets called on a edit operation
    initFromReply: ->
      oldSetReplyId: unsafeWindow.EditForm.setReplyId

      self: @
      # Practically this is the 'onPostEdit' listener
      unsafeWindow.EditForm.setReplyId: ->
        oldSetReplyId.apply unsafeWindow.EditForm, arguments

        element: document.getElementById 'edit'
        self.modifyEntryContainer element

        textarea: document.getElementById 'edit_post_body'
        textarea.disabled: true

        window.setTimeout(((textarea, element) ->
          self.test textarea.value, (markdown) ->
            if textarea and element
              textarea.value: markdown
              textarea.disabled: false
              form: element.getElementsByTagName('form')[0]
              form.elements[3].type: 'button'
              form.elements[3].addEventListener('click', ( ->
                textarea.value: markdownToHtml.call self, textarea.value
                unsafeWindow.document.getElementById('edit').
                                      getElementsByTagName('form')[0].
                                      submit()), false)
          textarea.value: 'Converting to markdown...'
        ), 0, textarea, element)

        self.addShortcuts textarea

      # For the normal reply box
      @modifyEntryContainer @element

      form: @element.getElementsByTagName('form')[0]
      textarea: document.getElementById 'post_body'

      form.elements[2].type: 'button'
      form.elements[2].addEventListener('click', ( ->
        textarea.value: markdownToHtml textarea.value
        unsafeWindow.document.getElementById('reply').
                              getElementsByTagName('form')[0].
                              submit()), false)
      @addShortcuts textarea

    # This function takes a reply 'containter' div, and chops and changes
    # it to our liking
    modifyEntryContainer: (element) ->
      element.getElementsByTagName('h5')[1].
              textContent: 'Use Markdown to format your reply.'

    # This function takes html, converts it to markdown, then inserts the
    # resulting quote into the current textarea
    insertQuote: (html) ->
      html

    # Opens the reply box, simple.
    openReply: ->

    # Adds the follow keyboard shortcuts
    #
    # * Nothing yet!
    addShortcuts: (textarea) ->
      textarea

  #### Page class
  # Represents a page on USO, depending on the URI. It will add all
  # the necessary listeners, insert all the elements, construct all the posts,
  # the guide if necessary, and generally all the other stuff I missed
  class Page
    init: ->
      path: location.pathname

      if 0 is path.indexOf '/topics'
        @initFromTopic()

    comments: []
    editor: null

    # Set-up page from a standard topic.
    initFromTopic: ->
      postElements: document.getElementsByClassName('posts')[0].
                             getElementsByTagName 'tr'

      @editor: new Editor document.getElementById('reply')

      for post in postElements
        @comments.push new Post(post)


  #### Parsing functions

  # A instance of showdown
  showdown: new Showdown.converter()

  # Takes a string of html, and parses it to markdown using
  # http://github.com/Tim-Smart/usotools-markdownify
  htmlToMarkdown: (html, callback) ->
    GM_xmlhttpRequest {
      method: 'POST'
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
      url: 'http://www.usotools.co.cc/markdown/'
      data: 'html=' + encodeURIComponent html
      onload: (xhr) ->
        textarea: document.createElement 'textarea'
        textarea.innerHTML: xhr.responseText
        callback textarea.value
        textarea: null
    }

  # Takes a string of markdown, and parses it to html
  markdownToHtml: (markdown) ->
    showdown.makeHtml markdown

  #### Helper functions
  # A few helper functions that break us away from browser-incompatibility
  # and RSI.

  # GM_addStyle, a drop in replacement for the original GM_addStyle
  # when it doesn't exist
  if 'function' isnt typeof GM_addStyle
    GM_addStyle: (css) ->
      head: document.getElementsByTagName('head')[0]
      style: document.createElement 'style'
      style.textContent: css
      head.appendChild style

  # Make sure unsafeWindow is all g
  `unsafeWindow = 'object' !== typeof unsafeWindow ? window : unsafeWindow`


  # Finally start setting up page
  new Page().init();
)()
