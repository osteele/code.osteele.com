# frozen_string_literal: true

# Match an image path in Markdown
# TODO: look for <img src=…> too
MD_IMAGE_RE = /\!\[[^\]]*\]\((.+?)\)/

GITHUB_USER_AGENT = 'osteele/code.osteele.com'

# Given a GitHub nameWithOwner, return it's README's download URL, or nil
def get_repo_readme_url(nwo)
  uri = URI.join("https://api.github.com/repos/#{nwo}/readme")
  headers = { 'User-Agent' => GITHUB_USER_AGENT }
  token = ENV['JEKYLL_GITHUB_TOKEN']
  headers['Authorization'] = "Bearer #{token}" if token
  begin
    return JSON.parse(uri.open(headers).read)['download_url']
  rescue OpenURI::HTTPError
    return nil
  end
end

# Give a the Markdown source of a README (or other file), return its content —
# skipping over an initial header, and any initial images (which tend to
# be badges instead of logos or screenshots).
def get_markdown_content(markdown)
  markdown
end

def get_markdown_images(markdown)
  markdown.scan(MD_IMAGE_RE)
end
