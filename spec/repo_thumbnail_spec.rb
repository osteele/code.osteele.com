# frozen_string_literal: true

require_relative '../scripts/repo_thumbnail'

RSpec.describe :get_repo_readme_data do
  it 'returns the README from a GitHub repo'
  it "handles repos that don't have READMEs"
  it 'passes non-404 exceptions'
end

RSpec.describe :get_markdown_content do
  it 'skips the badges at the top of a file'
end

RSpec.describe :get_markdown_images do
  it 'recognizes Markdown image markup' do
    images = get_markdown_images('line 1\npre ![](path/to/image.png) post')
    expect(images).to eq ['path/to/image.png']
  end

  it 'recognizes images with alt text' do
    images = get_markdown_images('line 1\npre ![alt text](path/to/image.png) post')
    expect(images).to eq ['path/to/image.png']
  end

  it 'recognizes HTML image markup'
  it 'ignores non-image links'
end
