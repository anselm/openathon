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
      :thumb=> "100x100#",
      :small  => "150x150>",
      :medium => "300x300>",
      :large => "400x400>" 
    }

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
