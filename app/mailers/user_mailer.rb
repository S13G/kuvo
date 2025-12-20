class UserMailer < ApplicationMailer

  def otp_email(user, otp_code)
    @user = user
    @otp_code = otp_code
    mail(to: @user.email, subject: "Kuvo Verification - Your OTP Code")
  end
end
