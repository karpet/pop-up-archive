class QueryBuilder::AndFilter < QueryBuilder::CollectiveFilter
  def collective_type
    :must
  end
end
