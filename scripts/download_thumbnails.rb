# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'open-uri'
require 'pathname'
require_relative 'utils'

MD_IMAGE_RE = /\!\[[^\]]*\]\((.+?)\)/
REPO_JSON_PATH = '_data/repos.json'

# TODO: replace this by path relative to README URL
RAW_URL_TPL = 'https://raw.githubusercontent.com/${nameWithOwner}/master/'

THUMBNAIL_DIR = 'static/img/thumbnails'

repos = read_json(REPO_JSON_PATH)

# Update nwo's thumbnail path. Write the file immediately, since this doesn't
# add much time and makes the next run faster if we're stopped in the middle.
def update_thumbnail_path(repos, nwo, thumbnail_path)
  relpath = thumbnail_path && Pathname.new(thumbnail_path).relative_path_from(
    Pathname.new(THUMBNAIL_DIR)
  ).to_s
  repo = repos.find { |r| r['nameWithOwner'] == nwo }
  return if repo['thumbnailPath'] == relpath
  repo['thumbnailPath'] = relpath
  write_json(REPO_JSON_PATH, repos)
end

def find_readme(nwo)
  uri = URI.join("https://api.github.com/repos/#{nwo}/readme")
  headers = {"User-Agent" => "osteele/code.osteele.com"}
  if (token = ENV['JEKYLL_GITHUB_TOKEN'])
    headers['Authorization'] = "Bearer #{token}"
  end
  begin
    download_url = JSON.parse(uri.open(headers).read)['download_url']
  rescue OpenURI::HTTPError
    return nil
  end
  return [File.basename(download_url), URI.parse(download_url).read]
end

repos.sort_by { |r| r['nameWithOwner'] }.each do |repo|
  nwo = repo['nameWithOwner']
  print "#{nwo}: "
  STDOUT.flush
  raw_url_prefix = RAW_URL_TPL.sub('${nameWithOwner}', nwo)
  metadata_path = File.join(THUMBNAIL_DIR, nwo, 'metadata.json')
  FileUtils.mkdir_p File.dirname(metadata_path)
  metadata = File.exist?(metadata_path) ? read_json(metadata_path) : {}

  is_missing = metadata['is_missing'] == true
  thumbnail_path = metadata['thumbnail_path']
  if is_missing or thumbnail_path
    if is_missing
      puts 'no image (cached)'
      update_thumbnail_path(repos, nwo, nil)
    else
      puts "#{thumbnail_path} (cached)"
      update_thumbnail_path(
        repos, nwo,
        File.join(THUMBNAIL_DIR, nwo, thumbnail_path)
        )
    end
    next
  end

  readme_name, readme_content = find_readme(nwo)
  metadata['readme_name'] = readme_name
  matches = (readme_content ? readme_content.scan(MD_IMAGE_RE) : [])
            .map(&:first)
            .map { |s| s.sub(/\?.*/, '') }
  matches = matches.reject { |s| s.match(/^https?:/) }
  unless matches.any?
    puts(readme_name ? "no image in #{readme_name}" : 'no README')
    metadata['is_missing'] = true
    metadata['thumbnail_path'] = nil
    write_json(metadata_path, metadata)
    update_thumbnail_path(repos, nwo, nil)
    next
  end

  thumbnail_rel_url = matches.first
  metadata['thumbnail_url'] = thumbnail_rel_url
  thumbnail_url = URI.join(raw_url_prefix, thumbnail_rel_url).to_s
  thumbnail_ext = File.extname(thumbnail_url)
  thumbnail_path = File.join(THUMBNAIL_DIR, nwo, "thumbnail#{thumbnail_ext}")

  puts "#{thumbnail_url} -> #{thumbnail_path}"
  FileUtils.mkdir_p File.dirname(thumbnail_path)
  URI.parse(thumbnail_url).open do |f|
    IO.copy_stream(f, thumbnail_path)
  end
  update_thumbnail_path(repos, nwo, thumbnail_path)
  metadata['is_missing'] = false
  metadata['thumbnail_path'] = File.basename(thumbnail_path)
  write_json(metadata_path, metadata)
  update_thumbnail_path(repos, nwo, nil)
end
