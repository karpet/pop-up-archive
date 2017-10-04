class QueryBuilder::OrFilter < QueryBuilder::CollectiveFilter
  def collective_type
    :should
  end
end
