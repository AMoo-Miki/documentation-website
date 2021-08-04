# frozen_string_literal: true

require "jekyll/hooks"
require "jekyll/document"
require "json"
require "set"

module Jekyll::VersionIndexer
  @versioned = []
  @versioned_docs = {}
  @canonical_versions = {}

  @version_pattern = /^(.*\/)(\d+(?:\.\d+)+)\/?(.*)$/.freeze

  def self.init(site)
    @site = site

    versioned_root_names = @site.data["versioned_root_labels"]

    versioned_roots = {}
    canonical_docs = {}

    @site.documents.each do |document|
      if (match = document.url.match(@version_pattern))
        root = match.captures[0]
        version = match.captures[1].to_f
        version_string = match.captures[1]
        canonical = root + match.captures[2]

        data = {
          "url" => document.url,
          "path" => document.path,
          "root" => root,
          "version" => version,
          "version_string" => version_string,
          "canonical" => canonical,
          "root_label" => versioned_root_names[root]
        }

        @versioned_docs[document.url] = data

        # Record the version for the canonical
        unless canonical_docs.key?(canonical)
          canonical_docs[canonical] = Set.new
        end

        canonical_docs[canonical] << {
          "url" => document.url,
          "version" => version,
          "version_string" => version_string,
        }

        # Record the version for the root
        unless versioned_roots.key?(root)
          versioned_roots[root] = Set.new
        end

        versioned_roots[root] << {
          "version" => version,
          "version_string" => version_string
        }

      end
    end

    # Produce a mapping of canonical doc-urls to available versions, sorted desc
    canonical_docs.each do |key, val|
      @canonical_versions[key] = val.to_a.sort_by { |o| -o["version"] }.map { |o| ({
        "version" => o["version"],
        "url" => o["url"]
      })}
    end

    # Produce a mapping of versioned root-urls to their label and versions, sorted desc
    versioned_roots.each do |key, val|
      versioned_roots[key] = {
        "version" => val.to_a.sort_by { |o| -o["version"] },
        "label" => versioned_root_names[key]
      }
    end

    site.data["_versioned-roots"] = versioned_roots

    File.open(File.join(@site.config["destination"], "../versions.json"), 'w') do |f|
      f.puts JSON.pretty_generate(@canonical_versions)
    end
  end

  def self.modify(document)
    return unless @versioned_docs.key?(document.url)
    
    versioned_doc = @versioned_docs[document.url]
    document.data["_compilation-name"] = versioned_doc["root_label"]
    document.data["_doc-version"] = versioned_doc["version_string"]
    document.data["_doc-versions"] = @canonical_versions[versioned_doc["canonical"]]
  end

end

# Before any Document or Page is processed, initialize the ContentIndexer

Jekyll::Hooks.register :site, :pre_render do |site|
  Jekyll::VersionIndexer.init(site)
end

# Process a Document as soon as its content is ready

Jekyll::Hooks.register :documents, :post_convert do |document|
  Jekyll::VersionIndexer.modify(document)
end

# Save the produced collection after Jekyll is done writing all its stuff

Jekyll::Hooks.register :site, :post_write do |_|
  #Jekyll::VersionIndexer.save
end
