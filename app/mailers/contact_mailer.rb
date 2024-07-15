# frozen_string_literal: true

# ContactMailer
class ContactMailer < ApplicationMailer
  def submit_feedback(params, ip)
    @name = params[:name].presence || 'User not logged in'
    @email = params[:email] || 'User not logged in'
    @message = params[:message]
    @ip = ip
    @barcode = params[:barcode]
    @status = params[:status]

    mail(to: params[:contact_form_to],
         subject: t('mylibrary.contact_mailer.subject').to_s,
         from: 'contact@mylibrary.stanford.edu',
         reply_to: params[:email])
  end
end
