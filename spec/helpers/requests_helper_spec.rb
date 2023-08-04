# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestsHelper do
  context 'with a Symphony request' do
    describe '#request_location_options' do
      let(:request) { instance_double(Symphony::Request, pickup_library: 'GREEN', home_location: 'STACKS') }

      it 'creates options for a requests location to be changed' do
        options = helper.request_location_options(request)
        expect(options).to have_css 'option', count: 11
      end

      it 'creates options with value and text' do
        options = helper.request_location_options(request)
        expect(options).to have_css 'option[value="HOPKINS"]', text: 'Marine Biology Library (Miller)'
      end
    end
  end

  context 'with a FOLIO request' do
    let(:default_service_points) do
      build(:default_service_points)
    end

    before do
      allow(Folio::ServicePoint).to receive_messages(
        default_service_points: default_service_points
      )
    end

    describe '#request_location_options' do
      context 'with a restricted pickup service point' do
        let(:request) do
          instance_double(Folio::Request, pickup_library: 'ART',
                                          service_point_id: '77cd12ac-2de8-4d13-99a0-f6b3b4f4bdca')
        end

        before do
          allow(request).to receive(:restricted_pickup_service_points).and_return([{
            'code' => 'ART',
            'id' => '77cd12ac-2de8-4d13-99a0-f6b3b4f4bdca',
            'discoveryDisplayName' => 'Art & Architecture (Bowes)',
            'pickupLocation' => true
          }])
          allow(request).to receive(:is_a?).with(Folio::Request).and_return(true)
        end

        it 'only allows the restricted service point as an option' do
          options = helper.request_location_options(request)
          expect(options).to have_css 'option', count: 1
        end

        it 'creates option with correct value and text' do
          options = helper.request_location_options(request)
          expect(options).to have_css 'option[value="77cd12ac-2de8-4d13-99a0-f6b3b4f4bdca"]',
                                      text: 'Art & Architecture (Bowes)'
        end
      end

      context 'with a non-restricted pickup service point' do
        let(:request) do
          instance_double(Folio::Request, pickup_library: 'GREEN-LOAN',
                                          service_point_id: 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d')
        end

        before do
          allow(Folio::ServicePoint).to receive_messages(
            find_by_id: instance_double(Folio::ServicePoint,
                                        code: 'GREEN-LOAN',
                                        id: 'a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d',
                                        is_default_for_campus: 'SUL',
                                        is_default_pickup: true,
                                        name: 'Green Library',
                                        pickup_location: true)
          )
          allow(request).to receive(:restricted_pickup_service_points).and_return(nil)
          allow(request).to receive(:is_a?).with(Folio::Request).and_return(true)
        end

        it 'puts all the defaults into the options list' do
          options = helper.request_location_options(request)
          expect(options).to have_css 'option', count: 2
        end

        it 'pre-selects the origin service point of the request' do
          options = helper.request_location_options(request)
          expect(options).to have_selector("option[selected='selected'][value='a5dbb3dc-84f8-4eb3-8bfe-c61f74a9e92d']",
                                           text: 'Green Library')
        end
      end

      context 'with a non-default origin pickup service point' do
        let(:request) do
          instance_double(Folio::Request, pickup_library: 'ARS',
                                          service_point_id: 'faa81922-3da8-4086-a7fa-977d7d3e7977')
        end

        before do
          allow(Folio::ServicePoint).to receive_messages(
            find_by_id: instance_double(Folio::ServicePoint,
                                        code: 'ARS',
                                        id: 'faa81922-3da8-4086-a7fa-977d7d3e7977',
                                        is_default_for_campus: nil,
                                        is_default_pickup: false,
                                        name: 'Archive of Recorded Sound',
                                        pickup_location: true)
          )
          allow(request).to receive(:restricted_pickup_service_points).and_return(nil)
          allow(request).to receive(:is_a?).with(Folio::Request).and_return(true)
        end

        it 'adds the origin service point to the default options list if it is a pickup location' do
          options = helper.request_location_options(request)
          expect(options).to have_css 'option', count: 3
        end

        it 'pre-selects the origin service point of the request' do
          options = helper.request_location_options(request)
          expect(options).to have_selector("option[selected='selected'][value='faa81922-3da8-4086-a7fa-977d7d3e7977']",
                                           text: 'Archive of Recorded Sound')
        end
      end
    end
  end
end
