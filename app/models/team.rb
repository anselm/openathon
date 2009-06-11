
class Team < ActiveRecord::Base

  # acts_as_ferret :fields => [ :name, :description ]

  has_many :users
  has_many :bookings

 # i cannot get this to work - anselm may 15 2009
 #  validates_format_of :name, :with => /^[;\[\^\$\.\\|\(\)\\\/]/

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
    all = Team.find(:all, :conditions => ["active = ?", true])
    all.each do |team|
      words.each do |word|
        if team.name != nil && team.name.to_s.downcase.include?(word)
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

  #
  # slot availability
  #
  # a team captain uses the team form to edit their team and select "hoped for" time slots
  #
  # an administrator can promote a slot to be the real one
  #

  def before_destroy
    Booking.destroy_all(:team_id => self.id)
  end

  def slot_finalize_not_admin
    Booking.destroy_all(:team_id => self.id)
    return if !self.calendar
    self.calendar.split(",").each do |slot|
      booking = Booking.new(:team_id => self.id, :slot => slot, :status => "desired" )
      booking.save
    end
  end

  def slot_finalize_admin
    Booking.destroy_all(:team_id => self.id)
    return if !self.calendar
    self.calendar.split(",").each do |slot|
      booking = Booking.new(:team_id => self.id, :slot => slot, :status => "reserved" )
      booking.save
      # TODO we shouldn't use this to build pre admin state in the ui...
      self.calendar = ""
      self.save
      return
    end
  end

  def slot_desired?(slotname)
    return false if !self.calendar
    self.calendar.split(",").each do |slot|
      return true if slot == slotname
    end
    return false
  end 

  def slot_yours?(slotname)
    return Booking.find(:first, :conditions => ["slot = ? AND team_id = ?",slotname,self.id])
  end

  def self.slot_taken?(slotname)
    return Booking.find(:first, :conditions => ["slot = ? AND status = ?", slotname, "reserved"])
  end

  def self.slot_free?(slotname)
    return !self.slot_taken?(slotname)
  end


  #
  # helper utilities to figure the role of a participant in a team
  #

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
    return nil if !person || !person.team_id
    return Team.find(:first,:conditions => { :id => person.team_id })
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
