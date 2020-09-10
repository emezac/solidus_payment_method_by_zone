# frozen_string_literal: true

require 'spec_helper'

describe Spree::Order, type: :model do
  let(:mx) { create(:country_mx) }
  let(:usa) { Spree::Country.find_by(iso: 'US') }
  let(:us_zone) { create(:zone) }
  let(:mx_zone) { create(:zone) }
  let(:us_payment_method) { create(:check_payment_method, name: 'US method') }
  let(:mx_payment_method) { create(:check_payment_method, name: 'MX method') }
  let(:order) { create(:order_with_totals) }

  before(:each) do
    order.line_items << create(:line_item)
    us_zone.members.create(zoneable: usa)
    mx_zone.members.create(zoneable: mx)
    us_payment_method.payment_method_zones.create(zone: us_zone)
    mx_payment_method.payment_method_zones.create(zone: mx_zone)
  end

  describe 'available_payment_methods' do
    it 'includes frontend payment methods' do
      payment_method = Spree::PaymentMethod::Check.create!({
        name: 'Fake',
        active: true,
        available_to_users: true,
        available_to_admin: false
      })
      expect(order.available_payment_methods).to include(payment_method)
    end

    it 'must not include payment methods for Mexico in addresses of US' do
      expect(order.available_payment_methods).to include(us_payment_method)
      expect(order.available_payment_methods).not_to include(mx_payment_method)
    end

    context 'with mexican address' do
      let(:state) { create(:state_ja, country: mx) }
      let(:address) { create(:address, city: 'Leon', state: state) }
      let!(:order) { create(:order_with_totals, ship_address: address) }

      it 'must include mx payment method' do
        expect(order.available_payment_methods).not_to include(us_payment_method)
        expect(order.available_payment_methods).to include(mx_payment_method)
      end

      context 'with state zone' do
      end
    end

    context 'with address not matching zones' do
      let(:ar) { create(:country, iso: 'AR') }
      let(:caba) { create(:state_ja, country: ar, state_code: 'C') }
      let(:address) { create(:address, city: 'Recoleta', state: caba) }
      let!(:order) { create(:order_with_totals, ship_address: address) }

      it 'must not return any payment method' do
        expect(order.available_payment_methods.count).to eq(0)
      end
    end
  end
end
