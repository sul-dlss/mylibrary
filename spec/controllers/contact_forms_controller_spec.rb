# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactFormsController, type: :controller do
  before do
    headers = { HTTP_REFERER: root_path }
    request.headers.merge! headers
  end

  describe 'creating a new message' do
    it 'return html success' do
      post :create, params: { message: 'Hello pooftah' }
      expect(flash[:success]).to eq 'Thank you! Someone from Access Services will be in touch with you soon.'
    end
  end

  describe 'validate' do
    it 'return an error if no message is sent' do
      post :create, params: { message: '' }
      expect(flash[:danger]).to eq 'A message is required'
    end
    it 'block potential spam with a url in the message' do
      post :create, params: { message: 'I like to spam by sending you a http://www.somespam.com.  lolzzzz' }
      expect(flash[:danger]).to eq 'Your message appears to be spam, and has not been sent. ' \
                                            'Please try sending your message again without any links in the comments.'
    end
    it 'block potential spam with a http:// in the user_agent field' do
      post :create, params: { user_agent: 'http://www.google.com', message: 'Legit message' }
      expect(flash[:danger]).to eq 'Your message appears to be spam, and has not been sent.'
    end
    it 'block potential spam with a http:// in the viewport field' do
      post :create, params: { viewport: 'http://www.google.com', message: 'Legit message' }
      expect(flash[:danger]).to eq 'Your message appears to be spam, and has not been sent.'
    end
  end
end
