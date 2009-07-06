require 'paperclip'
class User < ActiveRecord::Base
  acts_as_authentic
  belongs_to :team
end

class User

  attr_accessor :payments
  validates_presence_of :tos

  # roles are hardcoded TODO we could be more flexible
  ROLE_PARTICIPANT = "participant"
  ROLE_CAPTAIN = "captain"

  # Paperclip
  has_attached_file :photo,
    :styles => {
      :thumb=> "50x50#",
      :small  => "88x88>",
      :medium => "150x150>",
      :large => "300x300>" 
    }

  def is_owner?()
    return self != nil && self.team_id && self.team_id > 0 && self.role == "captain"
  end

  def is_captain?()
    return is_owner?()
  end

  def avatar(size)
    if self.photo_file_name 
      "<img src=\"/system/photos/#{self.id}/#{size}/" + self.photo_file_name + "\" />" 
    else
      case size
        when size == "thumb"
          d = "50"
        when size == "small"
          d = "88"
        when size == "medium"
          d = "150"
        when size == "large"
          d = "300"
      end
      "<img src=\"/images/default.jpg\" width=\"#{d}\" height=\"#{d}\" />" 
    end
  end

end
