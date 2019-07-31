# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactFormsController, type: :controller do
  let(:mock_client) do
    instance_double(
      SymphonyClient,
      patron_info: { 'fields' => { 'address1' => [], 'standing' => { 'key' => '' } } }
    )
  end
  let(:user) do
    { username: 'somesunetid', 'patronKey' => '123' }
  end

  before do
    allow(SymphonyClient).to receive(:new).and_return(mock_client)
    login_as(username: 'stub_user')
    warden.set_user(user)
    headers = { HTTP_REFERER: root_path }
    request.headers.merge! headers
  end

  describe 'creating a message to contact Access Services' do
    it 'returns html success' do
      post :create, params: {
        message: 'Hello pooftah',
        email: 'test@test.mail',
        url: '/summaries',
        contact_form_to: 'greencirc@stanford.edu'
      }
      expect(flash[:success]).to eq 'Thank you! Library staff will be in touch with you soon.'
    end
  end

  describe 'validating a message to contact Access Services' do
    it 'returns an error if no message is sent' do
      post :create, params: { message: '', email: 'test@test.mail', url: '/summaries' }
      expect(flash[:danger]).to eq 'A message is required'
    end
    it 'blocks potential spam with a url in the message' do
      post :create, params: { message: 'I like to spam by sending you a http://www.somespam.com.  lolzzzz',
                              email: 'test@test.mail',
                              url: '/summaries' }
      expect(flash[:danger]).to eq 'Your message appears to be spam, and has not been sent. ' \
                                            'Please try sending your message again without any links in the comments.'
    end
  end
end
