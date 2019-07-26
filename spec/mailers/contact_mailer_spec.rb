# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactMailer do
  describe 'contact access services' do
    describe 'with all fields' do
      let(:ip) { '123.43.54.123' }
      let(:params) do
        {
          name: 'Daenerys Targaryen',
          email: 'dtarg@westeros.org',
          contact_form_to: 'greencirc@stanford.edu'
        }
      end
      let(:mail) { described_class.submit_feedback(params, ip) }

      it 'has the correct to field' do
        expect(mail.to).to eq ['greencirc@stanford.edu']
      end

      it 'has the correct subject' do
        expect(mail.subject).to eq 'Access Services Question/Comment from My Library App'
      end

      it 'has the correct from field' do
        expect(mail.from).to eq ['contact@mylibrary.stanford.edu']
      end

      it 'has the correct reply to field' do
        expect(mail.reply_to).to eq ['dtarg@westeros.org']
      end

      it 'has the right email' do
        expect(mail.body).to have_content 'Name: Daenerys Targaryen'
      end

      it 'has the right name' do
        expect(mail.body).to have_content 'Email: dtarg@westeros.org'
      end

      it 'has the right host' do
        expect(mail.body).to have_content 'Host: foo.example.com'
      end

      it 'has the right IP' do
        expect(mail.body).to have_content '123.43.54.123'
      end
    end

    describe 'without name and email' do
      let(:ip) { '123.43.54.123' }
      let(:params) { {} }
      let(:mail) { described_class.submit_feedback(params, ip) }

      it 'has the right email' do
        expect(mail.body).to have_content 'Name: User not logged in'
      end

      it 'has the right name' do
        expect(mail.body).to have_content 'Email: User not logged in'
      end
    end
  end
end
