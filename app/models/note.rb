
#
# relations give attributes to notes
#

class Relation < ActiveRecord::Base
  belongs_to :note
  acts_as_solr( :fields => [ :value ] )
  RELATION_NULL                = "null"
  RELATION_TAG                 = "tag"
end

#
# Notes
#

class Note < ActiveRecord::Base
  has_many :relations
  acts_as_solr( :fields => [:title, :link, :description ] )
  KIND_NULL = "null"
  KIND_USER = "user"
  KIND_NOTE = "note"
  KIND_FEED = "feed"
end

#
# Note Relations Management
# Notes have support for arbitrary relationships attached to any given note
# A typing system is implemented at this level; above the scope of activerecord
# The reasoning for this is to have everything in the same sql query space
#

class Note

  def relation_get(kind, sibling_id = nil)
    r = nil
    if sibling_id
      r = Relation.first(:note_id => self.id, :kind => kind, :sibling_id => sibling_id )
    else
      r = Relation.first(:note_id => self.id, :kind => kind )
    end
    return r.value if r
    return nil
  end

  def relation_first(kind, sibling_id = nil)
    r = nil
    if sibling_id
      r = Relation.first(:note_id => self.id, :kind => kind, :sibling_id => sibling_id )
    else
      r = Relation.first(:note_id => self.id, :kind => kind )
    end
    return r
  end

  def relation_all(kind = nil, sibling_id = nil)
    query = { :note_id => self.id }
    query[:kind] = kind if kind
    query[:sibling_id] = sibling_id if sibling_id
    Relation.all(query)
  end

  def relation_destroy(kind = nil, sibling_id = nil)
    query = { :note_id => self.id }
    query[:kind] = kind if kind
    query[:sibling_id] = sibling_id if sibling_id
    Relation.destroy_all(query)
  end

  def relation_add(kind, value, sibling_id = nil)
    relation_destroy(kind,sibling_id)
    return if !value
    Relation.create!({
                 :note_id => self.id,
                 :sibling_id => sibling_id,
                 :kind => kind,
                 :value => value.to_s.strip
               })
  end

  def relation_add_array(kind,value,sibling_id = nil)
    relation_destroy(kind,sibling_id)
    return if !value
    value.each do |v|
      Relation.create!({
                   :note_id => self.id,
                   :sibling_id => sibling_id,
                   :kind => kind,
                   :value => v.strip
                 })
    end
  end

  def relation_save_hash_tags(text)
     text.scan(/#[a-zA-Z]+/i).each do |tag|
       relation_add(Relation::RELATION_TAG,tag[1..-1])
     end
  end

end

=begin

#
# Here is how we talk to various content publishers on the net.
# We'll probably only build out the twitter support at first.
#

require 'twitter'

class Note

  NOTE_RESPONDED = 1
  NOTE_UNRESPONDED = 0

  def self.eat_all
     self.eat_twitter_replies
     # self.notes_respond_all
  end

  #
  # eat results from twitter at large - filtering for portland
  #
  def self.eat_twitter_search
    results = []
    twitter = Twitter::Base.new(SITE_TWITTER_NAME,SITE_TWITTER_PASSWORD)
    Twitter::Search.new('').geocode(45.53,-122.67,"25mi").each do |twit|

      #userinfo = nil
      #results << "trying to get user #{twit.from_user_id}"
      #begin
      #       userinfo = twitter.user(twit.from_user_id)
      #       results << "got user #{twit.from_user_id}"
      #rescue
      #       results << "got some kind of error for user #{twit.from_user_id}"
      #end

      results << self.eat_save(
                        :id => twit.id,
                        :text => twit.text,
                        :userid => twit.from_user_id,
                        :usertitle => twit.from_user,
                        :userlocation => twit["location"],
                        :userdescription => "",
                        :provenance => "twitter"
                    )
    end
    return results
  end

  #
  # eat results specifically for us - public messages
  #
  def self.eat_twitter_replies
    results = []
    twitter = Twitter::Base.new(SITE_TWITTER_NAME,SITE_TWITTER_PASSWORD)
    twitter.replies().each do |twit|
      results << self.eat_save(
                       :id => twit.id,
                       :text => twit.text,
                       :userid => twit.user.id,
                       :usertitle => twit.user.screen_name,
                       :userlocation => twit.user.location,
                       :userdescription => twit.user.description,
                       :provenance => "twitter"
                   )
      end
    return results
  end

  def self.sanitize(text)
    # TODO improve by applying more sanitization that I am doing now
    l = SITE_TWITTER_NAME.length
    text = text[l..-1] if text[0..l] == "#{SITE_TWITTER_NAME} "
    l = l + 2
    text = text[l..-1] if text[0..l] == "d #{SITE_TWITTER_NAME} "
    return text
  end

  #
  # build a user object to track users as part of the relationship
  # we keep these in the same table so we can do networked relationships more easily
  #
  def self.find_or_update_user(args)
    uuid = "#{args[:provenance]}_#{args[:id]}"
    user = Note.find(:kind => KIND_USER,
                     :uuid => uuid
                    )
    if !user
      Note.create(
                     :kind => KIND_USER,
                     :uuid => uuid,
                     :title => args[:title],
                     :location => args[:location],
                     :description => args[:description],
                     :provenance => args[:provenance]
                 )
    else
      user.update_attributes(
                     :title => args[:title],
                     :description => args[:description],
                     :location => args[:location]
                     )
    end
    return user
  end

  #
  # go ahead and actually save a note - tracking its provenance in particular
  # also remember the user who made the note - we track users in this same table
  #
  def self.eat_save(args)

     uuid = "#{args[:provenance]}#{args[:id]}"

     note = Note.first(:uuid => uuid )
     return "Note already found #{uuid} #{args[:text]}" if note

     user = self.find_or_update_user(
                             :provenance => args[:provenance],
                             :id => args[:userid],
                             :title => args[:usertitle],
                             :location => args[:userlocation],
                             :description => args[:userdescription]
                           )

     note = Note.create!(
                        :kind => Note::KIND_NOTE,
                        :id => args[:id],
                        :provenance => args[:provenance],
                        :description => args[:text],
                        :owner_id => user.id,
                        :created_at => DateTime::now,
                        :updated_at => DateTime::now,
                        :permissions => NOTE_UNRESPONDED
                        # in_reply_to_user_id
                        # created_at
                        # source
                        # in_reply_to_status_id
                        # truncated
                        # favorited
                        )

     note.relation_save_hash_tags(args[:text])

  end

  #
  # A response engine
  #

  def self.respond_all
    results = []
    Note.all(:permissions => NOTE_UNRESPONDED).each do |note|
      user = Note.first(:id => note.owner_id)
      self.befriend(user)
      result = nil
      if note[:provenance] == "twitter"
        result = self.respond_twitter(user,note)
      end
      if result
        note.permissions = NOTE_RESPONDED
        note.save!
        results << result
      else
        results << "failed to save note"
      end
    end
    return results
  end

  def self.respond_twitter(user,post)

    twitter = Twitter::Base.new(SITE_TWITTER_NAME,SITE_TWITTER_PASSWORD)

    # publish to twitter as a form of public activity surfacing or grouping
    if false
      message = "via #{user.login} #{post.title}"
      response = twitter.post(message)
    end

    # decide on an appropriate response
    # message = "@#{user.title} #{response}"
    # twitter.post(message)

    return message

  end

end

=end

