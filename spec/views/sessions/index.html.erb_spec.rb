# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'sessions/index' do
  subject(:page) { Capybara.string(rendered) }

  before do
    assign(:symphony_ok, true)
  end

  it 'renders login buttons' do
    render

    expect(page).to have_link('Log in with SUNet ID').and(
      have_link('Log in with PIN')
    )
  end

  context 'when symphony is down' do
    before do
      assign(:symphony_ok, false)
    end

    it 'renders a maintenance message' do
      render

      expect(page).to have_content 'Temporarily unavailable'
    end

    it 'suppresses the login buttons' do
      render

      expect(page).not_to have_link('Log in with SUNet ID')
    end
  end
end
