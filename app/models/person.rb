class Person < ActiveRecord::Base
  attr_accessible :name

  has_many :contributions, dependent: :destroy
  has_many :items, through: :contributions

  before_save :generate_slug, on: :create

  include Searchable

  index_name { Rails.env.test? ? "test_#{people}" : ENV['PEOPLE_INDEX_NAME'] || 'people'}

  settings index: { number_of_shards: 1 },
  analysis: {
    filter: {
      ngram_filter: {
        type: "edgeNGram",
        min_gram: 2,
        max_gram: 8,
        side: "front"
      }
    },
    analyzer: {
      index_ngram_analyzer: {
        type: "custom",
        tokenizer: "standard",
        filter: ["lowercase", "ngram_filter"]
      },
      search_ngram_analyzer: {
        type: "custom",
        tokenizer: "standard",
        filter: ["standard", "lowercase", "ngram_filter"]
      }
    }
  } do
    mappings dynamic: 'false', _all: {'enabled' => false} do
      indexes :id,    type: 'integer', index: :not_analyzed
      indexes :name,  type: 'text', analyzer: 'index_ngram_analyzer', search_analyzer: 'search_ngram_analyzer'
      indexes :slug,  type: 'keyword'
      indexes :collection_ids, type: 'integer', index: :not_analyzed
    end
  end

  def to_indexed_json(params={})
    as_indexed_json(params).to_json
  end

  def as_indexed_json(params={})
    {
      collection_ids: collection_ids,
      name: name,
      slug: slug,
      id: id
    }
  end

  def self.search_within_collection(collection_id, query)
    Person.__elasticsearch__.search(
    query: {
      filtered: {
        query: {
          term: { name: query },
        },
        filter: {
          terms: { collection_id: [collection_id.to_i] }
        }
      }
    }
    )
  end

  def collection_ids
    items.collect{|i| i.collection_id}.uniq
  end

  def self.for_name(string)
    find_by_slug slugify string or create name: string
  end

  def as_json(params={})
    name.as_json
  end

  private

  def generate_slug
    self.slug = self.class.slugify name
  end

  def self.slugify(string)
    string.downcase.gsub(/\W/,'')
  end

end
