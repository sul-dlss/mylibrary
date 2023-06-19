# frozen_string_literal: true

# A mailer for sending PIN reset emails
class ResetPinsMailer < ApplicationMailer
  default from: 'sul-privileges@stanford.edu'

  # Send an email with a link to change a patron's PIN
  def reset_pin
    @patron = params[:patron]
    @url = change_pin_with_token_url(params[:token])

    mail(
      to: email_address_with_name(@patron.email, @patron.display_name),
      subject: t('mylibrary.reset_pins_mailer.reset_pin.subject')
    )
  end
end
