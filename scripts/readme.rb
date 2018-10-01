# frozen_string_literal: true

require "base64"

# Match an image path in Markdown
# TODO: look for <img src=…> too
MARKDOWN_IMAGE_RE = /\!\[[^\]]*\]\((.+?)\)/

MARKDOWN_EXTS = %w[.markdown .mdown .mkdn .md].freeze

# rubocop:disable Style/PercentLiteralDelimiters
BADGE_URL_PATTERN = %r[
  https://codeclimate.com/repos/.*/badges/.*
  | https://www.codeship.io/projects/.*
  | https://travis-ci.org/.*
]x
# rubocop:enable Style/PercentLiteralDelimiters

GITHUB_USER_AGENT = "osteele/code.osteele.com"
JEKYLL_GITHUB_TOKEN = ENV["JEKYLL_GITHUB_TOKEN"]

class Readme
  def self.from_github_nwo(nwo)
    data = get_repo_readme_data(nwo)
    return nil unless data

    Readme.new(data)
  end

  def self.from_markdown(content)
    Readme.new(content: content, name: "string.markdown")
  end

  def initialize(data)
    @data = data
  end

  def name
    @data[:name]
  end

  def markdown
    return nil unless MARKDOWN_EXTS.include?(File.extname(name).downcase)

    return @data[:content]
  end

  # ignores initial badges
  def images
    # FIXME: don't strip query parameters; handle upstream instead
    return get_markdown_images(markdown_without_badges)
           .map { |s| s.sub(/\?.*/, "") }
  end

  def badge_images
    images.select { |url| url.match(BADGE_URL_PATTERN) }
  end

  def thumbnail_url
    (images - badge_images).first
  end

  def markdown_without_badges
    remove_initial_badges(markdown || "")
  end
end

# Given a GitHub nameWithOwner, return its README info or nil
def get_repo_readme_data(nwo)
  uri = URI.join("https://api.github.com/repos/#{nwo}/readme")
  headers = { "User-Agent" => GITHUB_USER_AGENT }
  headers["Authorization"] = "Bearer #{JEKYLL_GITHUB_TOKEN}" if JEKYLL_GITHUB_TOKEN
  begin
    data = JSON.parse(uri.open(headers).read)
  rescue OpenURI::HTTPError
    return nil
  end
  raise EncodingError("Unknown encoding: #{data['encoding']}") \
    unless data["encoding"] == "base64"

  return {
    content: Base64.decode64(data["content"]),
    download_url: data["download_url"],
    name: data["name"]
  }
end

# Give a the Markdown source of a README (or other file), return its content —
# skipping over an initial header, and any initial images (which tend to
# be badges instead of logos or screenshots).
def remove_initial_badges(markdown)
  markdown.sub(/(#.*\s*)(\s*\[!.+?\]\(.+?\)\n)*/, '\1')
end

def get_markdown_images(markdown)
  markdown.scan(MARKDOWN_IMAGE_RE).map(&:first)
end
