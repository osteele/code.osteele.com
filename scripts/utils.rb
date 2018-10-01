# frozen_string_literal: true

require "json"
require "yaml"

JSON_OPTIONS = \
  {
    indent: "  ",
    space: " ",
    array_nl: "\n",
    object_nl: "\n"
  }.freeze

def read_json(fname)
  return JSON.parse(File.open(fname).read)
end

# TODO: use atomic_write
def write_json!(fname, json)
  File.open(fname, "w") do |f|
    f << JSON.generate(json, **JSON_OPTIONS)
  end
end

def load_yaml(fname)
  return YAML.safe_load(File.read(fname))
rescue Errno::ENOENT
  return {}
end
