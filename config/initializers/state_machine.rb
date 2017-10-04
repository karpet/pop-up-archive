# It seems that there is no underscore method on ActiveModel name
# It is added here, so it will be accessible and state machine
# can work. It should be removed after this is fixed
class ActiveModel::Name
  def underscore
    to_s.underscore
  end
end
