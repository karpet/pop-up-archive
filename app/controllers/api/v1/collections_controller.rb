class Api::V1::CollectionsController < Api::V1::BaseController
  expose :collections do
    if user_signed_in?
      collections = current_user.collections_without_my_uploads
      collections.paginate(page: params[:page], per_page: 3)
    else
      []
    end
  end
  expose :kollection do
    if params[:id]
      koll_exists = Collection.exists? params[:id]
      koll = nil
      if user_signed_in?
        koll = current_user.collections.find_by_id(params[:id])
      end
      koll ||= Collection.is_public.find_by_id(params[:id])
      if !koll
        if koll_exists
          raise CanCan::AccessDenied.new "May not fetch collection with id #{params[:id]}"
        else
          raise ActiveRecord::RecordNotFound.new "Cannot fetch collection with id #{params[:id]}"
        end
      end
      koll
    else
      Collection.new(params[:collection].merge(creator: current_user))
    end
  end

  expose :collection do 
    kollection
  end

  def create
    kollection.save
    respond_with :api, kollection
  end

  def update
    kollection.update_attributes(params[:collection])
    respond_with :api, kollection
  end 

  def destroy
    kollection.destroy
    respond_with :api, kollection
  end
end
