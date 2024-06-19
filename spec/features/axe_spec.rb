# frozen_string_literal: true

require 'rails_helper'
require 'axe-rspec'

RSpec.describe 'Accessibility testing', :js do
  let(:mock_client) { instance_double(FolioClient, ping: true, find_effective_loan_policy: {}) }

  let(:fine_loans) { Array.new(15, build(:patron_with_fines).patron_info['loans'].first) }
  let(:overdue_loans) { Array.new(50, build(:patron_with_overdue_items).patron_info['loans'].first) }
  let(:undergrad_patron_loans) { Array.new(15, build(:undergraduate_patron).patron_info['loans'].first) }
  let(:sponsor_patron_loans) { build(:sponsor_patron).patron_info['loans'] }
  let(:all_loans) { fine_loans + overdue_loans + undergrad_patron_loans + sponsor_patron_loans }
  let(:patron_info) do
    build(:sponsor_patron, custom_properties: { 'loans' => all_loans }).patron_info
  end

  let(:loan_policy) { build(:grad_mono_loans) }

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
    allow(mock_client).to receive_messages(patron_info:)
    allow(Folio::LoanPolicy).to receive(:new).and_return(loan_policy)
    login_as(User.new({ username: 'somesunetid', 'patronKey' => '123' }))
  end

  it 'validates the home page' do
    visit root_path
    expect(page).to be_accessible
  end

  it 'validates the summaries page' do
    visit summaries_path
    expect(page).to be_accessible
  end

  it 'validates the checkout page' do
    visit checkouts_path
    expect(page).to be_accessible
  end

  it 'validates the requests page' do
    visit requests_path
    expect(page).to be_accessible
  end

  it 'validates group requests page' do
    visit requests_path(group: true)
    expect(page).to be_accessible
    find('[data-mylibrary-modal]').click
    expect(page).to be_accessible
  end

  it 'validates the fines page' do
    visit fines_path
    expect(page).to be_accessible
  end

  it 'validates the payments page' do
    visit payments_path
    expect(page).to be_accessible
  end

  it 'validates the contact forms page' do
    visit contact_forms_path
    expect(page).to be_accessible
  end

  it 'validates the feedback forms page' do
    visit feedback_path
    expect(page).to be_accessible
  end

  it 'validates the login page' do
    visit login_path
    expect(page).to be_accessible
  end

  it 'validates the logout page' do
    visit logout_path
    expect(page).to be_accessible
  end

  it 'validates the reset_pin page' do
    visit reset_pin_path
    expect(page).to be_accessible
  end

  it 'validates the change_pin page' do
    visit change_pin_path
    expect(page).to be_accessible
  end

  it 'validates the unavaliable page' do
    visit unavailable_path
    expect(page).to be_accessible
  end

  def be_accessible
    be_axe_clean.excluding('#g-recaptcha-response')
  end
end
