# code.osteele.com site

The source to [code.osteele.com](https://code.osteele.com).

## Setup

1. [Install Jekyll](https://jekyllrb.com/docs/installation/)
2. `bundle install` to install Ruby gems.
3. `elm install` to install Elm packages.
4. Install [foreman](https://github.com/ddollar/foreman) or one of its
   [ports](https://github.com/ddollar/foreman#ports). On macOS: `brew install
   forego`
5. Install [entr](http://www.entrproject.org). On macOS: `brew install entr`.

## Develop

1. Run foreman or a port. E.g. `foreman start` or `forego start`.
2. Browse to [localhost:4000](http://localhost:4000)

Update project info:

```shell
./scripts/get_github_metadata
```

## Deploy

```shell
bundle exec jekyll build
netlify deploy
```
