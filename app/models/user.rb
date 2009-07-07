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

  def sanitize_force
    self.firstname = sanitize self.firstname
    self.lastname = sanitize self.lastname
    self.address = sanitize self.address
    self.age = sanitize self.age
    self.phone = sanitize self.phone
    self.save
  end

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
      when "thumb"
        d = "50"
      when "small"
        d = "88"
      when "medium"
        d = "150"
      when "large"
        d = "300"
      else d = "150"
      end
      "<img src=\"/images/default.jpg\" width=\"#{d}\" height=\"#{d}\" />" 
    end
  end

end
