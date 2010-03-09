# USO, meet GFM. One day Userscripts.org used plain HTML for writing comments and guides,
# little did he know about a young lass that called herself Github-Flavoured-Markdown.
# Userscripts.org fell madly in love.

# ==UserScript==  
# @name           USO, meet GFM.  
# @namespace      http://userscripts.org/users/tim  
# @description    GitHub Markdown gets married to Userscript.org  
# @include        http://userscripts.org/topics/*  
# @require        http://github.github.com/github-flavored-markdown/scripts/showdown.js  
# ==/UserScript==

# Anonymous function wrapper, so we don't step on anyones toes
(->

  #### Post class
  # This class represents a post on Userscripts.org, usually found in a topic
  class Post
    constructor: (element) ->

  #### Guide class
  # Represents a guide on Userscripts.org
  class Guide
    constructor: (element) ->

  #### Parsing functions

  # A instance of showdown
  showdown: new Showdown.converter()

  # Takes a string of html, and parses it to markdown using
  # http://github.com/Tim-Smart/usotools-markdownify
  htmlToMarkdown: (html, callback) ->
    GM_xmlhttpRequest {
      method: 'POST'
      url: 'http://www.usotools.co.cc/markdown/'
      data: 'html=' + encodeURIComponent html
      onload: (xhr) ->
        callback xhr.responseText
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

)()
