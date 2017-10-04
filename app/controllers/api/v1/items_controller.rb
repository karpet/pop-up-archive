class Api::V1::ItemsController < Api::V1::BaseController

  # this controller serves /api/collection/:coll_id/items

  expose(:collection)
  expose(:items, ancestor: :collection)

  # currently un-used
  # :nocov:
  expose(:collection_items) do
    if !params[:collection_id]
      raise ActiveRecord::RecordNotFound
    end
    searched_collection_items
  end
  # :nocov:

  expose(:item)
  expose(:contributions, ancestor: :item)

  # currently un-used
  # :nocov:
  expose(:searched_collection_items) do
    max_items = collection.items.count # TODO sane ceiling?
    query_builder = QueryBuilder.new({query:"collection_id:#{params[:collection_id].to_i}"}, current_user)
    search_query = Search.new(items_index_name) do
      query_builder.query do |q| 
        query &q
      end 
      size(max_items)
      sort do |s|
        s.by('id', 'asc')
      end
    end 
    response = Item.search(search_query).response
    ::ItemResultsPresenter.new(response).format_results
  end
  # :nocov:

  authorize_resource decent_exposure: true

  def update
    item.save
    respond_with :api, item
  end

  def show
    respond_with :api, item
  end

  def create
    if current_user.is_over_monthly_limit?
      render status: 413, json: {
        error: 'Monthly limit exceeded',
      }
      return
    end
    item.valid?
    item.save
    respond_with :api, item
  end

  def destroy
    cur_item = item
    cur_item_ok = false
    cur_items = current_user.all_items
    cur_items.each do |i|
      if cur_item.id == i.id
        #logger.warn "cur_item amongst user.all_items: #{i.id}"
        cur_item_ok = true
      end
    end
    ability = Ability.new(current_user)
    if cur_item_ok && ability.can?(:destroy, cur_item)
      cur_item.destroy
      respond_with :api, cur_item
    else
      render status: 403, json: { error: 'Permission denied' }
    end
  end

end
