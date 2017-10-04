class Role < ActiveRecord::Base

  has_and_belongs_to_many :users, :join_table => :users_roles
  has_and_belongs_to_many :organizations, :join_table => :organizations_roles
  belongs_to :resource, :polymorphic => true
  
  scopify

  def destroy
    # mimic the acts_as_paranoid behavior, w/o actually using that module.
    # since the handy with_role(), auto-methods, do not respect the deleted_at scope,
    # and there's no way to combine with_deleted and with_role.
    # i.e. we want to set the column but do not want to respect it on search.
    update_attribute :deleted_at, DateTime.now.utc
  end

  def recover
    update_attribute :deleted_at, nil
  end

  def single_designee
    if organizations.size > 1 or users.size > 1 
      raise "More than one Organization and/or User designated for Role #{id} #{name}"
    elsif organizations.size == 1
      organizations.first
    elsif users.size == 1
      users.first
    else
      raise "No Organization or User designated to Role #{id} #{name}"
    end
  end

end
