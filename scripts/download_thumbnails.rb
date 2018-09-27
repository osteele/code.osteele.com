# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'open-uri'
require 'pathname'
require_relative 'utils'

MD_IMAGE = /\!\[[^\]]*\]\((.+?)\)/
REPO_JSON_PATH = '_data/repos.json'
RAW_URL_TPL = 'https://raw.githubusercontent.com/${nameWithOwner}/master/'

IMAGE_PREFIX = 'static/img/thumbnails'
README_NAMES = case_combinations('README.md') #+ case_combinations('README.rst')
JSON_OPTIONS = { indent: '  ', space: ' ', array_nl: "\n", object_nl: "\n" }
               .freeze

repos = JSON.parse File.open(REPO_JSON_PATH).read

# Update nwo's thumbnail path. Write the file immediately, since this doesn't
# add much time and makes the next run faster if we're stopped in the middle.
def commit(repos, nwo, thumbnail_path)
  relpath = thumbnail_path && Pathname.new(thumbnail_path).relative_path_from(
    Pathname.new(IMAGE_PREFIX)
  ).to_s
  repo = repos.find { |r| r['nameWithOwner'] == nwo }
  return if repo['thumbnailPath'] == relpath
  repo['thumbnailPath'] = relpath
  # TODO: use atomic_write
  File.open(REPO_JSON_PATH, 'w') do |f|
    f << JSON.generate(repos, **JSON_OPTIONS)
  end
end

def find_readme(url_prefix)
  README_NAMES.each do |name|
    readme_url = URI.join(url_prefix, name)
    begin
      return [name, readme_url.read]
    rescue OpenURI::HTTPError
      next
    end
  end
  nil
end

repos.reverse.each do |repo|
  nwo = repo['nameWithOwner']
  print "#{nwo}: "
  STDOUT.flush
  raw_url_prefix = RAW_URL_TPL.sub('${nameWithOwner}', nwo)
  image_path = File.join(IMAGE_PREFIX, nwo, 'screenshot.*')
  thumbnail_path = Dir.glob(image_path).first
  if thumbnail_path
    if /\.missing$/.match?(thumbnail_path)
      puts 'no image (cached)'
      commit(repos, nwo, nil)
    else
      puts "#{thumbnail_path} (cached)"
      commit(repos, nwo, thumbnail_path)
    end
    next
  end

  readme_name, readme_content = find_readme(raw_url_prefix)
  m = readme_content && MD_IMAGE.match(readme_content)
  unless m
    puts(readme_name ? "no image in #{readme_name}" : 'no README')
    image_path = File.join(IMAGE_PREFIX, nwo, 'screenshot.missing')
    FileUtils.mkdir_p File.dirname(image_path)
    open(image_path, 'w') do |f|
      f.write('')
    end
    commit(repos, nwo, nil)
    next
  end

  image_url = URI.join(raw_url_prefix, m[1]).to_s
  image_ext = File.extname(image_url)
  image_path = File.join(IMAGE_PREFIX, nwo, "screenshot#{image_ext}")

  puts "#{image_url} -> #{image_path}"
  FileUtils.mkdir_p File.dirname(image_path)
  URI.parse(image_url).open do |f|
    IO.copy_stream(f, image_path)
  end
  commit(repos, nwo, thumbnail_path)
end
