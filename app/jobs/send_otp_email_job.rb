class SendOtpEmailJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 3

  discard_on ActiveRecord::RecordNotFound

  def perform(user_id, otp_code)
    user = User.find_by(id: user_id)
    return if user.nil?

    UserMailer.otp_email(user, otp_code).deliver_later
  end
end
