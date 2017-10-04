  class QueryBuilder::Facet

    attr_accessor :name, :options, :type

    def initialize(name, options={})
      @name = name
      @type = options.delete(:type)
      @options = options
    end

    def to_proc
      lambda do |search|
        search.send(:"#{type}", name.intern, options)
      end
    end

    private

    def options
      @options.present? ? @options : {}
    end

  end
