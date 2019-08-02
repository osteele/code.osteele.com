# frozen_string_literal: true

require "base64"
require "nokogiri"
require_relative "./utils"

# Match an image path in Markdown
# TODO: look for <img src=…> too
MARKDOWN_IMAGE_RE = /\!\[[^\]]*\]\((.+?)\)/.freeze

MARKDOWN_EXTS = %w[.markdown .mdown .mkdn .md].freeze

# rubocop:disable Style/PercentLiteralDelimiters
BADGE_URL_PATTERN = %r[
  https://codeclimate.com/repos/.*/badges/.*
  | https://www.codeship.io/projects/.*
  | https://travis-ci.org/.*
]x.freeze
# rubocop:enable Style/PercentLiteralDelimiters

GITHUB_USER_AGENT = "osteele/code.osteele.com"
JEKYLL_GITHUB_TOKEN = ENV["JEKYLL_GITHUB_TOKEN"]

class Readme
  def self.from_github_nwo(nwo)
    data = get_repo_readme_data(nwo)
    return nil unless data

    return MarkdownReadme.new(data) \
      if MARKDOWN_EXTS.include?(File.extname(name).downcase)

    return HtmlReadme.from_github_html_url(data)
  end

  def self.from_markdown(content)
    MarkdownReadme.new(content: content)
  end

  def self.from_html(content)
    HtmlReadme.from_html(content)
  end

  def initialize(data)
    @data = data
  end

  def name
    @data[:name]
  end

  def badge_image_urls
    image_urls.select { |url| url.match(BADGE_URL_PATTERN) }
  end

  def thumbnail_url
    (image_urls - badge_image_urls).first
  end
end

class MarkdownReadme < Readme
  def markdown
    @data[:content]
  end

  def markdown_without_badges
    remove_initial_badges(markdown || "")
  end

  # ignores initial badges
  def image_urls
    get_markdown_images(markdown_without_badges)
  end
end

class HtmlReadme < Readme
  def self.from_github_html_url(data)
    html_src = URI.parse(data[:html_url]).open(http_request_headers).read
    doc = Nokogiri::HTML(html_src)
    doc = doc.at("#readme article.markdown-body")
    doc.search("a svg.octicon-link").map(&:parent).each(&:remove)

    data = data.dup.update(html_document: doc)
    HtmlReadme.new(data)
  end

  def self.from_html(content)
    HtmlReadme.new(html_document: Nokogiri::HTML.fragment(content))
  end

  def html_document
    @data[:html_document]
  end

  def image_urls
    html_document.search("img").map { |e| e.attr("src") }.compact
  end

  def badge_image_urls
    super + image_urls.grep(%r{^https://camo.githubusercontent.com})
  end
end

# Given a GitHub nameWithOwner, return its README info or nil
def get_repo_readme_data(nwo)
  uri = URI.join("https://api.github.com/repos/#{nwo}/readme")
  begin
    data = JSON.parse(uri.open(http_request_headers).read)
  rescue OpenURI::HTTPError
    return nil
  end

  raise EncodingError("Unknown encoding: #{data['encoding']}") \
    unless data["encoding"] == "base64"

  return {
    content: Base64.decode64(data["content"]),
    download_url: data["download_url"],
    html_url: data["html_url"],
    name: data["name"]
  }
end

# Give the Markdown source of a README (or other file), return its content —
# skipping over an initial header, and any initial images (which tend to
# be badges instead of logos or screenshots).
def remove_initial_badges(markdown)
  markdown.sub(/(#.*\s*)(\s*\[!.+?\]\(.+?\)\n)*/, '\1')
end

def get_markdown_images(markdown)
  markdown.scan(MARKDOWN_IMAGE_RE).map(&:first)
end
