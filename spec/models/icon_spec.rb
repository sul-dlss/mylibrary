# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Icon do
  subject(:icon) { described_class.new(:renew, classes: 'awesome') }

  describe '#svg' do
    it 'returns a string' do
      expect(icon.svg).to be_an String
    end
    it 'returns raw svg' do
      expect(Capybara.string(icon.svg))
        .to have_css 'svg title', text: 'Eligible for renewal'
    end
  end

  describe '#options' do
    it 'applies options classes and default class' do
      expect(icon.options[:class]).to eq 'sul-icons awesome'
    end
  end

  describe '#path' do
    it 'prepends icons and sufixes .svg' do
      expect(icon.path).to eq 'icons/renew.svg'
    end
  end

  describe 'file_source' do
    context 'when the file is not available' do
      subject(:icon) { described_class.new(:yolo) }

      it {
        expect { icon.file_source }
          .to raise_error(/could not find/i)
      }
    end

    context 'when the file is available' do
      it 'returns the filesource' do
        expect(icon.file_source).to include '<svg'
      end
    end
  end
end
