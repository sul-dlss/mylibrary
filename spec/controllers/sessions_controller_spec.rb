# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SessionsController do
  let(:mock_client) { instance_double(FolioClient, ping: true) }

  before do
    allow(FolioClient).to receive(:new).and_return(mock_client)
  end

  context 'with an authenticated request' do
    let(:user) do
      User.new(username: 'somesunetid', patron_key: '513a9054-5897-11ee-8c99-0242ac120002')
    end

    before do
      warden.set_user(user)
    end

    describe 'GET index' do
      it 'redirects to the home page' do
        expect(get(:index)).to redirect_to summaries_url
      end
    end

    describe 'GET destroy' do
      it 'logs out of the current session' do
        get :destroy

        expect(warden.user).to be_nil
      end

      it 'redirects to the root' do
        expect(get(:destroy)).to redirect_to root_url
      end
    end
  end

  context 'with a shibboleth authenticated request' do
    let(:user) do
      User.new(shibboleth: true)
    end

    before do
      warden.set_user(user)
    end

    describe 'GET destroy' do
      it 'redirects to the SSO logout path' do
        expect(get(:destroy)).to redirect_to '/Shibboleth.sso/Logout'
      end
    end
  end

  describe 'GET index' do
    it 'renders the index template' do
      expect(get(:index)).to render_template 'index'
    end

    it 'pings Folio to make sure it is up' do
      get(:index)

      expect(assigns(:ils_ok)).to be true
    end

    context 'when Folio is down' do
      before do
        allow(mock_client).to receive(:ping).and_return(false)
      end

      it 'assigns false to folio_ok' do
        get(:index)

        expect(assigns(:ils_ok)).to be false
      end
    end
  end

  describe 'GET form' do
    it 'renders the form template' do
      expect(get(:form)).to render_template 'form'
    end
  end

  describe 'POST login_by_university_id' do
    context 'with a valid login' do
      before do
        allow(mock_client).to receive(:login_by_barcode_or_university_id)
          .with('01234567', '123').and_return('patronKey' => 1)
      end

      it 'logs in the user' do
        post(:login_by_university_id, params: { university_id: '01234567', pin: '123' })

        expect(warden.user).to have_attributes username: '01234567', patron_key: 1
      end

      it 'redirects the user to the summary page' do
        expect(post(:login_by_university_id, params: { university_id: '01234567', pin: '123' }))
          .to redirect_to summaries_url
      end
    end

    context 'with an invalid login' do
      it 'redirects failed requests back to the login page' do
        expect(post(:login_by_university_id)).to redirect_to login_url
      end

      it 'sets an alert' do
        get(:login_by_university_id)
        expect(flash[:alert]).to include('Unable to authenticate.')
      end
    end
  end

  describe 'GET login_by_sunetid' do
    context 'with a valid login' do
      before do
        request.env['REMOTE_USER'] = 'test123'
        allow(mock_client).to receive(:login_by_sunetid).with('test123')
                                                        .and_return('key' => '513a9054-5897-11ee-8c99-0242ac120002')
      end

      it 'logs in the user' do
        get(:login_by_sunetid)

        expect(warden.user).to have_attributes username: 'test123', patron_key: '513a9054-5897-11ee-8c99-0242ac120002'
      end

      it 'redirects the user to the summary page' do
        expect(get(:login_by_sunetid)).to redirect_to summaries_url
      end
    end

    context 'with an invalid login' do
      it 'redirects failed requests back to the login page' do
        expect(get(:login_by_sunetid)).to redirect_to root_url
      end

      it 'sets a flash error' do
        get(:login_by_sunetid)
        expect(flash[:error]).to include('Your SUNet ID is not linked to a library account')
      end
    end
  end
end
