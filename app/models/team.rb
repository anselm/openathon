class Team < ActiveRecord::Base

  # acts_as_ferret :fields => [ :title, :description ]

  has_many :users

  # super lazy
  # def lazy_search(phrase)
  #  terms = phrase.split.collect { |c| "%{c.downcase}%" }
  #  find_by_sql(["select t.* from table teams where #{ (["(lower(t.text_field1) like ? or lower(t.text_field1) like ?)"] * tokens.size).join(" and ") } order by s.created_on desc", *(tokens * 2).sort])
  # end

  #
  # Search
  #
  # We're going to want to at some point allow real search
  # We also want to push down work on the model to the model as we are doing
  # For now this implements what we need but it is not efficient
  # 

  def self.get_active_with_search(phrase)

    if !phrase || phrase.to_s.length < 1 
      teams = Team.find(:all, :conditions => ["active = ?", true])
      return teams
    end

    words = phrase.to_s.split.collect { |c| Sanitize.clean(c.downcase) }
    teams = []
    temp = Team.find(:all, :conditions => ["active = ?", true])
    temp.each do |team|
      words.each do |word|
        if team.title != nil && team.title.to_s.downcase.include?(word)
          teams << team
          break
        end
        if team.description !=nil && team.description.to_s.downcase.include?(word) 
          teams << team
          break
        end
      end
    end
    return teams

  end

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

  def self.get_team(person)
    return Team.find(person.team_id) if person && person.team_id
    return nil
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
