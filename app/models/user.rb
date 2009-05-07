
class User < ActiveRecord::Base
  acts_as_authentic
end

class User
  # roles are hardcoded TODO we could be more flexible
  ROLE_PARTICIPANT = "participant"
  ROLE_CAPTAIN = "captain"

  # Paperclip
  has_attached_file :photo,
    :styles => {
      :thumb=> "100x100#",
      :small  => "150x150>",
      :medium => "300x300>",
      :large => "400x400>" 
    }

end
