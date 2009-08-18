class MailMailer < ActionMailer::Base
  
  def raise(invitor, invitee, user_text, sent_at = Time.now)
    subject    "Please sponsor #{invitor.firstname} #{invitor.lastname} in Raise Your Voice -- 24-hour karaoke marathon to benefit Ethos Music Center"
    recipients invitee
    from       "#{invitor.firstname} #{invitor.lastname} <#{invitor.email}>"
    sent_on    sent_at
    body       :invitee => invitee, :user_text => user_text
    content_type "text/html"
  end

  def invite(invitor, invitee, user_text, sent_at = Time.now)
    subject    "#{invitor.firstname} #{invitor.lastname} has invited you to join #{invitor.team.name}, in a 24-hour karaoke marathon!"
    recipients invitee
    from       "#{invitor.firstname} #{invitor.lastname} <#{invitor.email}>"
    sent_on    sent_at
    body       :invitee => invitee, :user_text => user_text
    content_type "text/html"    
  end

  def testing(user,reset_url)
  end

  def password_reset_instructions(user, reset_url)  
    subject       "Password Reset Instructions"  
    from          "Voicebox Karaoke"  
    recipients    user.email  
    sent_on       Time.now  
    body          :edit_password_reset_url => reset_url  
  end 

end

