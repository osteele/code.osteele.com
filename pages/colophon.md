---
layout: default
title: Colophon
permalink: /colophon
---

The [repos page](/) aspires to be a portfolio of GitHub repositories, generated
via Jekyll plugins that use the GitHub API to read repository metadata and to
find thumbnails in README files.
Notable files:

- [scripts/get_github_metadata](https://github.com/osteele/code.osteele.com/blob/master/scripts/get_github_metadata)
  uses the [GitHub's GraphQL API](https://graphql.github.com) to download a list
  of repositories.
- [config/repo_metadata.yml](https://github.com/osteele/code.osteele.com/blob/master/config/repo_metadata.yml)
  configures the repository metadata query.
- [scripts/update_thumbnails](https://github.com/osteele/code.osteele.com/blob/master/scripts/update_thumbnails)
  scans repo README files for candidate thumbnail images.
- [src/Main.elm](https://github.com/osteele/code.osteele.com/blob/master/src/Main.elm)
  is the [Elm](https://elm-lang.org) code that presents the metadata.
