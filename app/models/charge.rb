class Charge < ActiveRecord::Base
  belongs_to :user

  attr_accessible :ref_id, :amount, :ref_type, :transaction_at, :extras

end
