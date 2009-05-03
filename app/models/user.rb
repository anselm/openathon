class User < ActiveRecord::Base
  acts_as_authentic
end

class User
  # roles are hardcoded TODO we could be more flexible
  ROLE_PARTICIPANT = "participant"
  ROLE_CAPTAIN = "captain"
end
