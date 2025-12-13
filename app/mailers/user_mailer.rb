class UserMailer < ApplicationMailer
  default from: "support #{ENV['GMAIL_USERNAME']}"

  def otp_email
    @user = params[:user]
    @otp_code = params[:otp_code]
    mail(to: @user.email, subject: "Kuvo Verification - Your OTP Code")
  end
end
