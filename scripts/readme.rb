# frozen_string_literal: true

require "base64"

# Match an image path in Markdown
# TODO: look for <img src=…> too
MD_IMAGE_RE = /\!\[[^\]]*\]\((.+?)\)/
MARKDOWN_EXTS = %w[.markdown .mdown .mkdn .md].freeze

GITHUB_USER_AGENT = "osteele/code.osteele.com"

class Readme
  def self.from_nwo(nwo)
    data = get_repo_readme_data(nwo)
    return nil unless data

    return Readme.new(data)
  end

  def self.from_markdown(content)
    return Readme.new(content: content, name: "string.markdown")
  end

  def initialize(data)
    @data = data
  end

  def name
    return @data[:name]
  end

  # ignores initial badges
  def images
    return [] unless MARKDOWN_EXTS.include?(File.extname(name).downcase)

    matches = get_markdown_images(without_initial_badges)
              .map { |s| s.sub(/\?.*/, "") }
    # For now, only consider on-site images
    matches = matches.reject { |s| s.match(/^https?:/) }
    return matches
  end

  def thumbnail_url
    return images.first
  end

  def without_initial_badges
    return remove_initial_badges(@data[:content])
  end
end

# Given a GitHub nameWithOwner, return its README info or nil
def get_repo_readme_data(nwo)
  uri = URI.join("https://api.github.com/repos/#{nwo}/readme")
  headers = { "User-Agent" => GITHUB_USER_AGENT }
  token = ENV["JEKYLL_GITHUB_TOKEN"]
  headers["Authorization"] = "Bearer #{token}" if token
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
  return markdown.sub(/(#.*\s*)(\s*\[!.+?\]\(.+?\)\n)*/, '\1')
end

def get_markdown_images(markdown)
  return markdown.scan(MD_IMAGE_RE).map(&:first)
end
