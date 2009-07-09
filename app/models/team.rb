require 'fastercsv'

class ActiveRecord::Base
  def self.to_csv(*args)
    find(:all).to_csv(*args)
  end
  
  def export_columns(format = nil)
    self.class.content_columns.map(&:name) - ['created_at', 'updated_at']
  end
  
  def to_row(format = nil)
    export_columns(format).map { |c| self.send(c) }
  end
end

class Array
  def to_csv(options = {})
    if all? { |e| e.respond_to?(:to_row) }
      header_row = first.export_columns(options[:format]).to_csv
      content_rows = map { |e| e.to_row(options[:format]) }.map(&:to_csv)
      ([header_row] + content_rows).join
    else
      FasterCSV.generate_line(self, options)
    end
  end
end

class Team < ActiveRecord::Base

  attr_accessor :total_donations

  # acts_as_ferret :fields => [ :name, :description ]

  has_many :users
  has_many :bookings
  has_many :notes

  # has_many :payments, :through => :owner_id

  # TODO fix i cannot get this to work - anselm may 15 2009
  #  validates_format_of :name, :with => /^[;\[\^\$\.\\|\(\)\\\/]/

  # TODO this is inelegant
  def sanitize(str)
    return "" if !str
    return Sanitize.clean(str)
  end

  def sanitize_force
    self.name = sanitize self.name
    self.description = sanitize self.description
    self.calendar = sanitize self.calendar
    self.roomtime = sanitize self.roomtime
    self.roomname = sanitize self.roomname
    self.hours = sanitize self.hours
    self.save
  end

  ##################################################################################################
  # helpers for payments
  ##################################################################################################

  # not the most elegant code ever written...  basically associate payment totals with members
  def payment_sorted_users
    members = []
    User.find(:all, :conditions => ["team_id = ?", self.id]).each do |member|
	total = 0
	@payments = Payment.find(:all,
                     :conditions => ["owner_id = ? AND description = ?", member.id, Payment::DONE ] )
	@payments.each do |payment|
		total = total + payment.amount
	end
	member.payments = total
	members << member
    end
    members.sort! { |y,x| x.payments <=> y.payments }
    # less than elegant
    self.total_donations = 0
    members.each do |member|
      self.total_donations = self.total_donations + member.payments
    end
    return members 
  end

  # not the most elegant code ever written...
  def self.payment_top_teams
    t = []
    teams = Team.find(:all, :conditions => ["active = ?", true])
    teams.each do |team|
       team.payment_sorted_users
       t << team
    end
    t.sort! { |y,x| x.total_donations <=> y.total_donations }
    return t
  end

  # not the most elegant code ever written...
  def self.payment_top_users
    u = []
    teams = Team.find(:all, :conditions => ["active = ?", true])
    teams.each do |team|
       users = team.payment_sorted_users
       u.concat( users )
    end
    u.sort! { |y,x| x.payments <=> y.payments }
    return u
  end

  ##################################################################################################
  # Search
  #
  # We're going to want to at some point allow real search
  # We also want to push down work on the model to the model as we are doing
  # For now this implements what we need but it is not efficient
  ##################################################################################################

  # super lazy
  # def lazy_search(phrase)
  #  terms = phrase.split.collect { |c| "%{c.downcase}%" }
  #  find_by_sql(["select t.* from table teams where #{ (["(lower(t.text_field1) like ? or lower(t.text_field1) like ?)"] * tokens.size).join(" and ") } order by s.created_on desc", *(tokens * 2).sort])
  # end

  def self.get_active_with_search(phrase)

    if !phrase || phrase.to_s.length < 1 
      teams = Team.find(:all, :conditions => ["active = ?", true])
      return teams
    end

    words = phrase.to_s.split.collect { |c| sanitize(c.downcase) }
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

  ################################################################################################
  # slot availability
  # no longer used
  #
  # a team captain uses the team form to edit their team and select "hoped for" time slots
  #
  # an administrator can promote a slot to be the real one
  ################################################################################################

=begin

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

=end

  ################################################################################################
  # helper utilities to figure the role of a participant in a team
  ################################################################################################

  def is_owner?(person)
    return person !=nil &&  person.team_id == self.id && person.role == "captain"
  end

  def is_captain?(person)
    return is_owner?(person)
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
