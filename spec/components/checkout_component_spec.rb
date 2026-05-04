# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckoutComponent, type: :component do
  subject(:component) { described_class.new(checkout: checkout, patron: patron) }

  let(:patron) { instance_double(Folio::Patron, can_renew?: false) }

  let(:checkout_attributes) { {} }
  let(:checkout) do
    instance_double(
      Folio::Checkout,
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
      item_id: nil,
      key: 'abc123',
      library_name: 'Green Library',
      lost?: false,
      overdue?: false,
      patron_key: 'xyz321',
      recalled?: false,
      renewable?: false,
      short_term_loan?: false,
      sort_key: nil,
      title: 'Checkout Title',
      **checkout_attributes
    )
  end

  let(:rendered) { Capybara.string(render_inline(component)) }

  it 'links to the item in SearchWorks' do
    expect(rendered).to have_link(
      'View in SearchWorks',
      href: 'https://searchworks.stanford.edu/view/12345'
    )
  end

  context 'when the library is from ILL' do
    let(:checkout_attributes) { { from_ill?: true } }

    it 'does not include a link to the item in SearchWorks' do
      expect(rendered).to have_no_link('View in SearchWorks')
    end
  end

  describe '#list_group_item_status_for_checkout' do
    context 'with a recalled item' do
      let(:checkout) { instance_double(Folio::Checkout, recalled?: true) }

      it 'is *-danger' do
        expect(component.list_group_item_status_for_checkout).to eq 'list-group-item-danger'
      end
    end

    context 'with an overdue item' do
      let(:checkout) { instance_double(Folio::Checkout, recalled?: false, overdue?: true) }

      it 'is *-warning' do
        expect(component.list_group_item_status_for_checkout).to eq 'list-group-item-warning'
      end
    end
  end

  describe '#time_remaining_for_checkout' do
    context 'when the checkout is a short term loan' do
      let(:checkout) { instance_double(Folio::Checkout, short_term_loan?: true, due_date: 42.minutes.from_now) }

      it 'returns the distance of time in words' do
        expect(component.time_remaining_for_checkout).to eq '42 minutes'
      end
    end

    context 'when the checkout is not a short term loan' do
      let(:checkout) { instance_double(Folio::Checkout, short_term_loan?: false, days_remaining: 42) }

      it 'pluralizes the number of days remaining' do
        expect(component.time_remaining_for_checkout).to eq '42 days'
      end
    end
  end

  describe '#render_checkout_status' do
    let(:checkout) do
      instance_double(
        Folio::Checkout,
        recalled?: false,
        overdue?: false,
        lost?: false,
        claimed_returned?: false,
        accrued: 0,
        sort_key: 0,
        barcode: '36105000000',
        catkey: 'a12345',
        due_date: nil,
        checkout_date: Time.zone.parse('2024-01-01'),
        days_remaining: 31,
        short_term_loan?: false,
        title: 'Title',
        author: 'Author',
        call_number: 'Call number',
        key: '0',
        library_name: 'Green Library',
        from_ill?: false
      )
    end

    context 'when a recalled item has accrued fines' do
      before do
        allow(checkout).to receive_messages(recalled?: true, accrued: 15)
      end

      it 'renders the right html' do
        expect(rendered).to have_css('.text-recalled', text: 'Recalled $15').and(have_css('.sul-icons'))
      end
    end

    context 'when a recalled item has no accrued fines' do
      before do
        allow(checkout).to receive_messages(recalled?: true)
      end

      it 'renders the right html' do
        expect(rendered).to have_css('.text-recalled', text: 'Recalled').and(have_css('.sul-icons'))
      end
    end

    context 'when an item is claimed returned' do
      before do
        allow(checkout).to receive_messages(overdue?: true, days_overdue: 20, lost?: true, claimed_returned?: true,
                                            accrued: 666)
      end

      it 'renders the right html' do
        expect(rendered).to have_text('Processing claim')
      end
    end

    context 'when an item is lost' do
      before do
        allow(checkout).to receive_messages(overdue?: true, days_overdue: 200, lost?: true, accrued: 666)
      end

      it 'renders the right html' do
        expect(rendered).to have_css('.text-lost', text: 'Assumed lost $666').and(have_css('.sul-icons'))
      end
    end

    context 'when an overdue item has accrued fines' do
      before do
        allow(checkout).to receive_messages(overdue?: true, days_overdue: 50, accrued: 666)
      end

      it 'renders the right html' do
        expect(rendered).to have_css('.text-overdue', text: 'Overdue $666').and(have_css('.sul-icons'))
      end
    end

    context 'when an overdue item has no accrued fines' do
      before do
        allow(checkout).to receive_messages(overdue?: true, days_overdue: 1)
      end

      it 'renders the right html' do
        expect(rendered).to have_css('.text-overdue', text: 'Overdue').and(have_css('.sul-icons'))
      end
    end

    context 'when an item is not deliquent' do
      it 'renders the right html' do
        expect(rendered).to have_text('OK')
      end
    end
  end
end
