exec = require('child_process').exec

task 'build', 'Build to ecmascript source code', ->
  exec 'coffee -bc *.coffee'

task 'docs', 'Build documentations ready for Github Pages', ->
  exec 'docco *.coffee && mv docs/* ./ && mv uso_meet_markdown.user.html index.html && rm -Rf docs/'
