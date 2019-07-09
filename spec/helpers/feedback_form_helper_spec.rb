# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeedbackFormHelper do
  describe '#show_feedback_form?' do
    it 'return true when not under the FeedbackFormsController' do
      expect(helper).to be_show_feedback_form
    end
  end
end
