# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactFormsHelper do
  describe '#contact_form_to' do
    context 'when code is not provided' do
      it 'creates a default contact' do
        expect(helper.contact_form_to).to eq 'Circulation &amp; Privileges ' \
                                             '(<a href="mailto:greencirc@stanford.edu">greencirc@stanford.edu</a>)'
      end
    end

    context 'when code is provided' do
      it 'creates a custom contact' do
        expect(helper.contact_form_to('EARTH-SCI'))
          .to eq 'Earth Sciences Library (Branner) ' \
                 '(<a href="mailto:brannerlibrary@stanford.edu">brannerlibrary@stanford.edu</a>)'
      end
    end
  end
end
