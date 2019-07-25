# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'checkouts/index.html.erb' do
  let(:patron) { instance_double(Patron, remaining_checkouts: nil) }

  before do
    controller.singleton_class.class_eval do
      protected

      def patron_or_group; end
      helper_method :patron_or_group
    end

    stub_template 'shared/_navigation.html.erb' => 'Navigation'
    allow(view).to receive(:patron_or_group).and_return(patron)

    assign(:checkouts, [])
  end

  it 'shows the number of checkouts' do
    render

    expect(rendered).to include('<h2>Checked out: 0</h2>')
  end

  context 'with a fee borrower' do
    before do
      allow(patron).to receive(:remaining_checkouts).and_return(25)
    end

    it 'shows the number of checkouts remaining' do
      render

      expect(rendered).to include('<h2>Checked out: 0 (25 remaining)</h2>')
    end
  end
end
