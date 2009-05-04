require 'test_helper'

class InviteMailerTest < ActionMailer::TestCase
  test "invite" do
    @expected.subject = 'InviteMailer#invite'
    @expected.body    = read_fixture('invite')
    @expected.date    = Time.now

    assert_equal @expected.encoded, InviteMailer.create_invite(@expected.date).encoded
  end

end
