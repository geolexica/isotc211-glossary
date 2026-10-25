#!/usr/bin/env ruby
# frozen_string_literal: true

# Migrate RelatedConcept#content from bare strings to the lang-keyed
# shape required since glossarist 2.13 (L10N invariant: all relationship
# free-text is { "eng" => ... }). Idempotent — hash content is skipped.
# English-only datasets; the "eng" key is hardcoded by design.
#
# Usage: ruby scripts/migrate_related_content_l10n.rb datasets/*/

require "yaml"

ARGV.each do |dir|
  changed = 0
  total = 0
  Dir.glob(File.join(dir, "concepts", "*.yaml")).sort.each do |f|
    total += 1
    docs = YAML.load_stream(File.read(f))
    docs = [docs] unless docs.is_a?(Array)
    touched = false
    docs.each do |doc|
      next unless doc.is_a?(Hash)
      rels = doc["related"]
      next unless rels.is_a?(Array)
      rels.each do |r|
        next unless r.is_a?(Hash) && r["content"].is_a?(String)
        r["content"] = { "eng" => r["content"] }
        touched = true
      end
    end
    next unless touched
    File.write(f, docs.map { |d| YAML.dump(d) }.join("---\n"))
    changed += 1
  end
  puts "#{dir}: migrated #{changed}/#{total} files"
end
