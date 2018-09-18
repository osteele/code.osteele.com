# Use this with foreman or one of its ports.
#
# This is used only for development. Production should use a static server.
# In order to simplify development usage, this file is named Procfile instead of e.g.
# Procfile.dev.
web: bundle exec jekyll serve --watch --livereload
elm: echo src/Main.elm | entr -s 'npx elm make src/Main.elm --output static/js/projects.js'
