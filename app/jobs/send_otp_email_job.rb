class SendOtpEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id, otp_code)
    user = User.find(user_id)
    UserMailer.with(user: user, otp_code: otp_code).otp_email.deliver_later
  end
end
