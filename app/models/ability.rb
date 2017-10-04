class Ability
  include CanCan::Ability

  def initialize(user)

    if user && user.has_role?(:super_admin)
    # superadmin
      can :manage, :all

    elsif user
    # has account
      can :read,   Collection, :items_visible_by_default => true
      can :read,   Collection, id: ( user.collection_ids )
      can :create, Collection
      can :update, Collection, id: ( user.collection_ids )
      can :destroy, Collection if ( user.organization && user.can_admin_org? ) 

      can :read,   Item, :is_public => true
      can :create, Item, collection: { id: ( user.collection_ids ) }
      can :read,   Item, collection: { id: ( user.collection_ids ) }
      can :update, Item, collection: { id: ( user.collection_ids ) }
      can :destroy, Item, id: ( user.organization && user.can_admin_org? ? user.all_items.collect(&:id) : user.item_ids )

      can :read,   Entity
      can :manage, Entity, item: { collection: { id: ( user.collection_ids ) }}

      can :read,   Contribution
      can :manage, Contribution, item: { collection: { id: ( user.collection_ids ) }}

      can :read, Admin::TaskList if (user.has_role?("super_admin"))

      can :read, User if (user.has_role?("super_admin"))

      can :manage, AudioFile, item: { collection: { id: ( user.collection_ids ) }}
      can :order_transcript, AudioFile if ( !user.organization_id.nil? && user.has_role?("admin", user.organization))
      can :add_to_amara,     AudioFile if ( !user.organization_id.nil? && user.has_role?("admin", user.organization))

      can :read,   Organization
      can :manage, Organization, id: ( user.organization_id )

    else
    # anonymous
      can :read,   Collection, :items_visible_by_default => true

      can :read,   Item, :is_public => true

      can :read,   Entity

      can :read,   Contribution

      can :read,   Organization
    end

  end
end
