class ItemController < ApplicationController

  # "short" url redirects to permanent item url
  def short
    item_id = params[:item_id]  # hex-encoded
    item = Item.find item_id.to_i(16)
    # ignore permissions. let the perm url do that.
    new_url = "#{root_url}collections/#{item.collection_id}/items/#{item.id}"
    if params[:start]
      new_url += "?start=#{params[:start]}"
    end 
    if params[:end]
      new_url += "&end=#{params[:end]}"
    end 
    redirect_to new_url, :status => :moved_permanently
  end

end
