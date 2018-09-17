# code.osteele.com site

The source to [code.osteele.com](https://code.osteele.com).

## Setup

1. [Install Jekyll](https://jekyllrb.com/docs/installation/)
2. `bundle install` to install Ruby gems.
3. `yarn install` to install Yarn packages.

## Develop

1. `bundle exec jekyll serve --watch --livereload`
2. Browse to [localhost:4000](http://localhost:4000)
3. `ruby scripts/collect_repos.rb` to update the cached project info
4. `elm-make src/Main.elm --output static/js/projects.js` to re-build the Elm
   app

## Docker (alternative)

This just updates the Jekyll pages. It doesn't rebuild the project cache or
the Elm app.

1. Setup: Install [Docker Compose](https://docs.docker.com/compose/install/)
2. Develop: `docker-compose up`

## Deploy

```bash
git push
```
