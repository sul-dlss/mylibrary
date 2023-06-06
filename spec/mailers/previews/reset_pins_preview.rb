# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/reset_pin
class ResetPinsPreview < ActionMailer::Preview
  def reset_pin
    ResetPinsMailer.with(
      patron: preview_patron,
      token: 'j3n+JOtqbo2KV8SGVZsZn/tjalSjaVSpOeDxuIQmEAVGSsk8O'
    ).reset_pin
  end

  private

  # An example patron record for testing PIN reset email appearance
  def preview_patron
    Folio::Patron.new('id' => '77052ede-7ded-4583-afcb-bc845b7eab80',
                      'user' => {
                        'barcode' => '2558563207',
                        'personal' => {
                          'firstName' => 'Jane',
                          'lastName' => 'Doe',
                          'email' => 'janedoe@stanford.edu'
                        }
                      })
  end
end
