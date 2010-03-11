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
    constructor: (page, element) ->
      @page: page
      @element: element

      if 'TR' is @element.nodeName
        @initFromTopic()
      else if 'DIV' is @element.nodeName
        @initFromGuide()

    element: null

    # We are currently in a guide, attach listeners, grab post info etc
    # and populate the Post instance with data
    initFromTopic: ->
      authorCont: @element.getElementsByClassName('author')[0]
      nameLink: authorCont.getElementsByClassName('fn')[0].
                           getElementsByTagName('a')[0]
      linkCont: authorCont.getElementsByTagName('p')[0]

      if not linkCont
        linkCont: document.createElement 'p'
        authorCont.getElementsByClassName('role')[0].
                   appendChild linkCont

      @id: /\d+$/.exec(@element.id)[0]
      @userId: nameLink.getAttribute 'user_id'
      @userName: nameLink.textContent
      @userHref: nameLink.href
      @body: @element.getElementsByClassName('body')[0].
                  innerHTML

      # Insert the quote link
      span: document.createElement 'span'
      span.style.display: 'block'
      span.className: 'edit'

      quote: document.createElement 'a'
      quote.style.fontSize: '12px'
      quote.textContent: 'Quote'
      quote.href: '#'
      quote.className: 'utility'
      span.appendChild quote

      linkCont.appendChild span

      # Set-up quote listeners
      quote.addEventListener('click', ((event) =>
        event.preventDefault()
        @quote()
      ), false)

    # This post function takes either a selection, or the entire post body,
    # then passes it to the editor 'insertQuote' function
    quote: ->
      selection: window.getSelection()
      html: ''
      if '' is selection.toString()
        html: @body
      else
        range: selection.getRangeAt(0)
        element: range.commonAncestorContainer
        while (element)
          if 'TD' is element.nodeName and 0 is element.id.indexOf 'post-body-'
            if 'post-body-' + @id is element.id
              properSelection: true
            break
          element: element.parentNode
        if properSelection
          range: range.cloneContents()
          holder: document.createElement 'div'
          holder.appendChild range
          html: holder.innerHTML
          holder: range: null
        else html: @body
      page.editor.insertQuote html, @userName, @userId, @id

    # This function will report the post as spam, to the USO spam topic
    report: ->
      true

  #### Guide class
  # Represents a guide on Userscripts.org
  class Guide
    constructor: (page, element) ->
      @page: page

  #### Editor class
  # Represents the current editor in the page
  class Editor
    constructor: (page, element) ->
      @page: page
      @element: element

      if 'DIV' is element.nodeName
        @initFromReply()

    element: null

    # Here we modify the reply box, and over-ride a function on the USO
    # page that gets called on a edit operation
    initFromReply: ->
      oldSetReplyId: unsafeWindow.EditForm.setReplyId

      # Practically this is the 'onPostEdit' listener
      unsafeWindow.EditForm.setReplyId: =>
        oldSetReplyId.apply unsafeWindow.EditForm, arguments

        @element: document.getElementById 'edit'
        @modifyEntryContainer @element

        @textarea: document.getElementById 'edit_post_body'
        @textarea.disabled: true

        # Pop back into the sandbox scope, so the leak check
        # doesn't throw any access violation errors
        window.setTimeout(( =>
          # Convert the HTML to Markdown
          htmlToMarkdown @textarea.value, (markdown) =>
            if @textarea and @element
              @textarea.value: markdown
              @textarea.disabled: false

          # Modify the submit button to convert the textarea
          # content before sending it off to USO
          form: @element.getElementsByTagName('form')[0]
          form.elements[3].type: 'button'
          form.elements[3].addEventListener('click', ( =>
            @textarea.value: markdownToHtml @textarea.value
            unsafeWindow.document.getElementById('edit').
                                  getElementsByTagName('form')[0].
                                  submit()
          ), false)
          @textarea.value: 'Converting to markdown...'
        ), 0)

        @addShortcuts @textarea

      # For the normal reply box
      @modifyEntryContainer @element

      form: @element.getElementsByTagName('form')[0]
      textarea: document.getElementById 'post_body'

      form.elements[2].type: 'button'
      form.elements[2].addEventListener('click', ( ->
        textarea.value: markdownToHtml textarea.value
        unsafeWindow.document.getElementById('reply').
                              getElementsByTagName('form')[0].
                              submit()
      ), false)
      @addShortcuts textarea

      oldReplyInit: unsafeWindow.ReplyForm.init
      unsafeWindow.ReplyForm.init: =>
        oldReplyInit.call unsafeWindow.ReplyForm
        @element: document.getElementById 'reply'
        @textarea: document.getElementById 'post_body'

      @element: null

    # This function takes a reply 'containter' div, and chops and changes
    # it to our liking
    modifyEntryContainer: (element) ->
      element.getElementsByTagName('h5')[1].
              textContent: 'Use Markdown to format your reply.'

    # This function takes html, the User-Name, a User ID and a post ID,
    # converts it to markdown, then inserts the
    # resulting quote into the current textarea
    insertQuote: (html, username, userId, postId) ->
      if @ensureElement()
        previous: markdownToHtml @textarea.value

        modify: (html) ->
          previous + html

      @textarea.disabled: true
      @textarea.value: 'Converting quote to Markdown...'

      html: html.replace(/<!--.+-->/, '').trim()
      html: '<blockquote><strong><a href="/users/' + userId + '">' +
            username + '</a></strong>&nbsp;' +
            '<a href="#' + postId + '">wrote</a>:<br />' +
            html + '</blockquote>'

      html: modify html if modify

      htmlToMarkdown html, (markdown) =>
        @textarea.value: markdown
        @textarea.disabled: false

    # This is used by the insertQuote function to see whether we are currently
    # in a reply or not. If we are not in a reply, it will open a reply box. If
    # we are in a edit or reply, it just returns true
    ensureElement: ->
      if not @element
        @openReply()
        false
      else if 'none' is @element.style.display
        @openReply()
        false
      else
        true

    # Opens the reply box, simple.
    openReply: ->
      unsafeWindow.ReplyForm.init()

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
      postElements: document.getElementsByClassName 'post'

      @editor: new Editor @, document.getElementById 'reply'

      for post in postElements
        @comments.push new Post @, post


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
  page: new Page()
  page.init()
)()
