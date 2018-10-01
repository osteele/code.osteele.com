# frozen_string_literal: true

require_relative "../scripts/readme"

RSpec.describe :Readme do
  describe :from_nwo do
    it "returns the README from a GitHub repo"
    it "handles repos that don't have READMEs"
    it "passes non-404 exceptions"
  end

  describe :without_initial_badges do
    it "skips the badges at the top of a file" do
      readme = Readme.from_markdown <<~EOF
        # Title

        [![Build Status](https://travis-ci.org/osteele/repo.svg?branch=master)](https://travis-ci.org/osteele/repo)
        [![Docs](./docs/docs-badge.svg)](http://osteele.github.io/repo/)

        And now it begins.
      EOF
      expect(readme.without_initial_badges).to eq "# Title\n\n\nAnd now it begins.\n"
    end
  end

  describe :get_markdown_images do
    it "recognizes Markdown image markup" do
      readme = Readme.from_markdown('line 1\npre ![](path/to/image.png) post')
      expect(readme.images).to eq ["path/to/image.png"]
    end

    it "recognizes images with alt text" do
      readme = Readme.from_markdown('line 1\npre ![alt text](path/to/image.png) post')
      expect(readme.images).to eq ["path/to/image.png"]
    end

    it "recognizes HTML image markup"
    it "ignores non-image links"
  end
end
