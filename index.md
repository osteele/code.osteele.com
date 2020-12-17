---
layout: projects
title: Oliver Steele | Code
---

## About this page

This page aspires to be a portfolio of GitHub repositories, generated via Jekyll
plugins that use the GitHub API to read repository metadata, and to find
thumbnails in README files.

Currently it's very much a work in progress; hence the ugly formatting.

The source for this page is [here](https://github.com/osteele/code.osteele.com).
Notable files:

- [scripts/get_github_metadata](https://github.com/osteele/code.osteele.com/blob/master/scripts/get_github_metadata)
  uses the GitHub API to download a list of repositories.
- [config/repo_metadata.yml](https://github.com/osteele/code.osteele.com/blob/master/config/repo_metadata.yml)
  configures the repository metadata query.
- [scripts/update_thumbnails](https://github.com/osteele/code.osteele.com/blob/master/scripts/update_thumbnails)
  scans repo README files for candidate thumbnail images.
- [src/Main.elm](https://github.com/osteele/code.osteele.com/blob/master/src/Main.elm)
  is the Elm code that presents the metadata.

## Repos
