class QueryBuilder::CollectiveFilter < QueryBuilder::Filter
  def initialize(filters)
    @filters = filters
  end

  def type
      collective_type
  end

  def value
      @filters.map(&:to_h)
  end

  def present?
    @filters.present?
  end

  def blank?
    @filters.blank?
  end

  def length
    present? ? 1 : 0
  end
end
