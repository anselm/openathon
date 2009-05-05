class Team < ActiveRecord::Base

  def is_owner?(person)
    return person !=nil &&  person.team_id == self.id && person.role == "owner"
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

end
