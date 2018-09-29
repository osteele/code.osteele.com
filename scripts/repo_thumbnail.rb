# frozen_string_literal: true

require 'base64'

# Match an image path in Markdown
# TODO: look for <img src=…> too
MD_IMAGE_RE = /\!\[[^\]]*\]\((.+?)\)/

GITHUB_USER_AGENT = 'osteele/code.osteele.com'

# Given a GitHub nameWithOwner, return its README info or nil
def get_repo_readme_data(nwo)
  uri = URI.join("https://api.github.com/repos/#{nwo}/readme")
  headers = { 'User-Agent' => GITHUB_USER_AGENT }
  token = ENV['JEKYLL_GITHUB_TOKEN']
  headers['Authorization'] = "Bearer #{token}" if token
  begin
    data = JSON.parse(uri.open(headers).read)
  rescue OpenURI::HTTPError
    return nil
  end
  raise EncodingError("Unknown encoding: #{data['encoding']}") \
    unless data['encoding'] == 'base64'

  return {
    content: Base64.decode64(data['content']),
    download_url: data['download_url'],
    name: data['name']
  }
end

# Give a the Markdown source of a README (or other file), return its content —
# skipping over an initial header, and any initial images (which tend to
# be badges instead of logos or screenshots).
def get_markdown_content(markdown)
  return markdown
end

def get_markdown_images(markdown)
  return markdown.scan(MD_IMAGE_RE).map(&:first)
end
