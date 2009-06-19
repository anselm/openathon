require 'test_helper'

class MailMailerTest < ActionMailer::TestCase
  test "invite" do
    @expected.subject = 'MailMailer#invite'
    @expected.body    = read_fixture('invite')
    @expected.date    = Time.now
    assert_equal @expected.encoded, MailMailer.create_invite(@expected.date).encoded
  end
end
