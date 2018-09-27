# frozen_string_literal: true

require 'fileutils'
require 'graphql/client'
require 'graphql/client/http'
require 'yaml'

SCHEMA_PATH = '.cache/github-schema.json'
REPO_JSON_PATH = '_data/repos.json'
REPO_OVERRIDE_PATH = 'data/repo-overrides.yaml'

JEKYLL_CONFIG = YAML.safe_load File.read('_config.yml')
REPO_OVERRIDES = YAML.safe_load File.read(REPO_OVERRIDE_PATH)

# in addition to viewer
REPO_OWNERS = [JEKYLL_CONFIG['repo_owners'] || []].flatten

HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
  def headers(_context)
    if (token = ENV['JEKYLL_GITHUB_TOKEN'])
      { Authorization: "Bearer #{token}" }
    else
      puts 'Missing GitHub access token'
      {}
    end
  end
end

unless File.exist?(SCHEMA_PATH)
  FileUtils.mkdir_p File.dirname(SCHEMA_PATH)
  puts "Saving #{SCHEMA_PATH}"
  GraphQL::Client.dump_schema(HTTP, SCHEMA_PATH)
end

Client = GraphQL::Client.new(schema: SCHEMA_PATH, execute: HTTP)

IndexQuery = Client.parse <<-'GRAPHQL'
  query($count: Int, $cursor: String) {
    viewer {
      login
      repositories(first: $count, after: $cursor) {
        pageInfo {
          hasNextPage
          endCursor
        }
        edges {
          node {
            name
            nameWithOwner
            owner {
              login
            }
            createdAt
            pushedAt
            description
            url
            homepageUrl
            isArchived
            isFork
            isPrivate
            primaryLanguage {
              name
            }
            languages(first: 100) {
              edges {
                node {
                  name
                }
              }
            }
            repositoryTopics(first:10) {
              edges {
                node {
                  topic {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  }
GRAPHQL

repos = []
repo_count = 0
cursor = nil
viewer = nil
loop do
  result = Client.query(IndexQuery, variables: { count: 100, cursor: cursor })
  viewer = result.data.viewer
  repo_count += viewer.repositories.edges.length
  repos +=
    viewer
    .repositories.edges
    .map(&:node)
    .reject { |repo| repo.is_fork || repo.is_private }
    .select { |r| (REPO_OWNERS + [viewer.login]).include? r.owner.login }
  page_info = viewer.repositories.page_info
  break unless page_info.has_next_page
  cursor = page_info.end_cursor
end

repo_hashes = repos.map do |repo|
  h = repo.to_h.dup
  h['languages'] = repo.languages.edges.map { |edge| edge.node.name }
  h['primaryLanguage'] = repo.primary_language.name if repo.primary_language
  h['topics'] = repo.repository_topics.edges.map { |edge| edge.node.topic.name }
  h.delete 'homepageUrl' if h['homepageUrl']&.empty?
  h.delete 'isFork'
  h.delete 'isPrivate'
  h.delete 'repositoryTopics'
  h['owner'] = h['owner'].dup
  h['owner'].delete '__typename'
  h
end

# Apply overrides
repo_hashes.each do |repo|
  owner = REPO_OVERRIDES[repo['nameWithOwner']]
  repo['tags'] = owner['tags'] if owner&.key? 'tags'
end

puts "Writing #{repo_hashes.length} public source repos / #{repo_count} total"

FileUtils.mkdir_p File.dirname(REPO_JSON_PATH)
json_options = { indent: '  ', space: ' ', array_nl: "\n", object_nl: "\n" }

File.open(REPO_JSON_PATH, 'w') do |f|
  f << JSON.generate(repo_hashes, **json_options)
end

# File.open('data/owner.json', 'w') do |f|
#   owner = { login: viewer.login }
#   f << JSON.generate(owner.to_h, **json_options)
# end
