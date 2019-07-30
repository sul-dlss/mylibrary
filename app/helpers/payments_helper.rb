# frozen_string_literal: true

# Helper module for Fine Payments
module PaymentsHelper
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def cybersource_pay_url
    fines = patron_or_group.fines
    URI::HTTPS.build(
      host: Settings.symphony.host, path: '/secureacceptance/payment_form.php', query: {
        reason: fines.map(&:status).join(','),
        billseq: fines.map(&:sequence).values_at(0, -1).join('-'),
        amount: format('%.2f', fines.sum(&:owed)),
        session_id: 'UNUSED',
        group: patron_or_group.is_a?(Group) ? 'G' : '',
        user: patron_or_group.barcode
      }.to_query
    ).to_s
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end
