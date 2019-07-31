# frozen_string_literal: true

# ContactMailer
class ContactMailer < ActionMailer::Base
  def submit_feedback(params, ip)
    @name = params[:name].presence || 'User not logged in'
    @email = params[:email] || 'User not logged in'
    @message = params[:message]
    @ip = ip

    mail(to: params[:contact_form_to],
         subject: 'Circulation & Privileges Question/Comment from My Library App',
         from: 'contact@mylibrary.stanford.edu',
         reply_to: params[:email])
  end
end
