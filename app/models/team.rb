class Team < ActiveRecord::Base

  has_many :users

  def is_owner?(person)
    return person !=nil &&  person.team_id == self.id && person.role == "captain"
  end

  def is_member?(person)
    return person !=nil && person.team_id == self.id 
  end

  def set_captain(person)
    if person
      person.team_id = self.id
      person.role = 'captain'
      person.save
      return true
    else return false
    end
  end

  # Paperclip
  has_attached_file :photo,
    :styles => {
      :thumb=> "100x100#",
      :small  => "150x150>",
      :medium => "300x300>",
      :large => "400x400>"
    }


end
