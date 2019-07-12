# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckoutsController do
  let(:mock_client) { instance_double(SymphonyClient) }

  before do
    allow(SymphonyClient).to receive(:new).and_return(mock_client)
  end

  context 'with an unauthenticated request' do
    it 'redirects to the home page' do
      expect(get(:index)).to redirect_to root_url
    end
  end

  context 'with an authenticated request' do
    let(:user) do
      { username: 'somesunetid', patron_key: '123' }
    end

    let(:mock_response) do
      {
        fields: {
          circRecordList: [{ key: 1, fields: { dueDate: '2019-05-03' } }]
        }
      }.with_indifferent_access
    end

    before do
      allow(mock_client).to receive(:checkouts).with('123').and_return(mock_response)
      warden.set_user(user)
    end

    it 'displays list of checkouts' do
      expect(get(:index)).to render_template 'index'
    end

    it 'assigns a list of checkouts' do
      get(:index)

      expect(assigns(:checkouts)).to include a_kind_of(Checkout).and(have_attributes(key: 1))
    end
  end
end
