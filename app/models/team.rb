class Team < ActiveRecord::Base

  def is_owner?(person)
    return person !=nil &&  person.team_id == self.id && person.role == "captain"
  end

  def is_member?(person)
    return person !=nil && person.team_id == self.id 
  end

  def set_captain(person)
    if person
      person.team_id = self.id
      dbuser.role = 'captain'
      dbuser.save
      return true
    else return false
    end
  end

end
