# frozen_string_literal: true

require_relative "../scripts/repo_thumbnail"

RSpec.describe :get_repo_readme_data do
  it "returns the README from a GitHub repo"
  it "handles repos that don't have READMEs"
  it "passes non-404 exceptions"
end

RSpec.describe :remove_initial_badges do
  it "skips the badges at the top of a file" do
    src = <<~EOF
      # Title

      [![Build Status](https://travis-ci.org/osteele/repo.svg?branch=master)](https://travis-ci.org/osteele/repo)
      [![Docs](./docs/docs-badge.svg)](http://osteele.github.io/repo/)

      And now it begins.
    EOF
    expect(remove_initial_badges(src)).to eq "# Title\n\n\nAnd now it begins.\n"
  end
end

RSpec.describe :get_markdown_images do
  it "recognizes Markdown image markup" do
    images = get_markdown_images('line 1\npre ![](path/to/image.png) post')
    expect(images).to eq ["path/to/image.png"]
  end

  it "recognizes images with alt text" do
    images = get_markdown_images('line 1\npre ![alt text](path/to/image.png) post')
    expect(images).to eq ["path/to/image.png"]
  end

  it "recognizes HTML image markup"
  it "ignores non-image links"
end
