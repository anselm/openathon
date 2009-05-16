class Booking < ActiveRecord::Base
  def self.slot_taken?(slotname)
    booking = Booking.find(:first, :conditions => ["slot = ?", slotname])
    return booking != nil
  end
  def self.slot_free?(slotname)
    return !self.slot_taken?(slotname)
  end
end
