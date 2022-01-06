# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'checkouts/_checkout.html.erb' do
  let(:checkout_attributes) { {} }
  let(:checkout) do
    instance_double(
      Checkout,
      accrued: nil,
      author: '',
      barcode: nil,
      call_number: '',
      catkey: '12345',
      checkout_date: 120.days.ago,
      claimed_returned?: false,
      days_overdue: nil,
      days_remaining: 120,
      due_date: 120.days.from_now,
      from_ill?: false,
      item_key: nil,
      key: 'abc123',
      library: 'GREEN',
      lost?: false,
      overdue?: false,
      patron_key: 'xyz321',
      recalled?: false,
      recalled_date: nil,
      renewable?: false,
      renewal_date: nil,
      resource: nil,
      short_term_loan?: false,
      sort_key: nil,
      title: 'Checkout Title',
      **checkout_attributes
    )
  end

  let(:patron) { instance_double(Patron, can_renew?: false) }

  before do
    without_partial_double_verification do
      allow(view).to receive(:patron).and_return(patron)
    end

    render 'checkouts/checkout', checkout: checkout
  end

  it 'links to the item in SearchWorks' do
    expect(rendered).to have_link(
      'View in SearchWorks',
      href: 'https://searchworks.stanford.edu/view/12345'
    )
  end

  context 'when the library is from ILL' do
    let(:checkout_attributes) { { from_ill?: true } }

    it 'does not include a link to the item in SearchWorks' do
      expect(rendered).not_to have_link('View in SearchWorks')
    end
  end
end
