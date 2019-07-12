# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Request do
  subject do
    described_class.new({
      key: '1',
      fields: fields
    }.with_indifferent_access)
  end

  let(:request) { subject }
  let(:fields) do
    {
      status: 'ACTIVE',
      queuePosition: '3',
      queueLength: '7',
      item: {
        fields: {
          bib: {
            key: '1184859',
            fields: {
              title: 'The Lego movie videogame [electronic resource]',
              author: 'Cool people made this'
            }
          },
          call: {
            fields: {
              dispCallNumber: 'ZMS 4033',
              sortCallNumber: 'ZMS 004033'
            }
          }
        }
      }
    }
  end

  it 'has a key' do
    expect(request.key).to eq '1'
  end

  it 'has a status' do
    expect(request.status).to eq 'ACTIVE'
  end

  it 'has a title' do
    expect(request.title).to eq 'The Lego movie videogame [electronic resource]'
  end

  it 'has an author' do
    expect(request.author).to eq 'Cool people made this'
  end

  it 'has a call number' do
    expect(request.call_number).to eq 'ZMS 4033'
  end

  it 'has a shelf key' do
    expect(request.shelf_key).to eq 'ZMS 004033'
  end

  it 'has a catkey' do
    expect(request.catkey).to eq '1184859'
  end

  it 'has the queue length' do
    expect(request.queue_length).to eq '7'
  end

  it 'has the queue position' do
    expect(request.queue_position).to eq '3'
  end
end
