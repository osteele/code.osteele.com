# frozen_string_literal: true

require_relative "../scripts/readme"

RSpec.describe :Readme do
  describe :from_nwo do
    it "returns the README from a GitHub repo"
    it "handles repos that don't have READMEs"
    it "passes non-404 exceptions"
  end

  describe :images do
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

  describe :thumbnail do
    it "omits images in badge position" do
      readme = Readme.from_markdown <<~EOF
        # Title

        [![Build Status](https://travis-ci.org/osteele/repo.svg?branch=master)](https://travis-ci.org/osteele/repo)
        [![Docs](./docs/docs-badge.svg)](http://osteele.github.io/repo/)

        Non-badge content starts here.
      EOF
      expect(readme.thumbnail_url).to eq nil
    end

    it "omits badges at known SaaS URLs" do
      readme = Readme.from_markdown <<~EOF
        [![Code Climate](https://codeclimate.com/repos/5290f2d67e00a43c5d053345/badges/923265ce69ba80f69de3/gpa.png)](https://codeclimate.com/repos/5290f2d67e00a43c5d053345/feed)
        [![Build Status](https://travis-ci.org/osteele/repo.svg?branch=master)](https://travis-ci.org/osteele/repo)
        # Header
        ![alt text](path/to/image.png)
      EOF
      expect(readme.thumbnail_url).to eq "path/to/image.png"
    end
  end
end
