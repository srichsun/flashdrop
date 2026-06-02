class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "MerchantOS <no-reply@merchant-os.onrender.com>")
  layout "mailer"
end
