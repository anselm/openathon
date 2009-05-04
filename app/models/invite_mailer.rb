class InviteMailer < ActionMailer::Base
  

  def invite(invitee, user_text, sent_at = Time.now)
    subject    'Join my team for the Ethos Karaokathon'
    recipients invitee
    from       ''
    sent_on    sent_at
    
    body       :invitee => invitee, :user_text => user_text
  end

end
