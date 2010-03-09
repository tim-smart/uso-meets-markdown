// USO, meet GFM. One day Userscripts.org used plain HTML for writing comments and guides,
// little did he know about a young lass that called herself Github-Flavoured-Markdown.
// Userscript.org fell madly in love.
// ==UserScript==
// @name           USO, meet GFM.
// @namespace      http://userscripts.org/users/tim
// @description    GitHub Markdown gets married to Userscript.org
// @include        http://userscripts.org/topics/*
// @require        http://github.github.com/github-flavored-markdown/scripts/showdown.js
// ==/UserScript==
(function() {
  var GM_addStyle, Guide, Post;
  //### Post class
  // This class represents a post on Userscript.org, usually found in a topic
  Post = function Post(element) {
    return this;
  };
  //### Guide class
  // Represents a guide on Userscript.org
  Guide = function Guide(element) {
    return this;
  };
  //### Helper functions
  // A few helper functions that break us away from browser-incompatibility
  // and RSI.
  // GM_addStyle, a drop in replacement for the original GM_addStyle
  // when it doesn't exist
  return 'function' !== typeof GM_addStyle ? (GM_addStyle = function GM_addStyle(css) {
    var head, style;
    head = document.getElementsByTagName('head')[0];
    style = document.createElement('style');
    style.textContent = css;
    return head.appendChild(style);
  }) : null;
})();