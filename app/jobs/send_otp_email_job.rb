class SendOtpEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id, otp_code)
    user = User.find(user_id)
    UserMailer.otp_email(user, otp_code).deliver_later
  end
end
