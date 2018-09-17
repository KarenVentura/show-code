require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class PriceRangeSack < Spree::ShippingCalculator
      has_many :price_ranges, foreign_key: :calculator_id
      accepts_nested_attributes_for :price_ranges, allow_destroy: true

      def self.description
        Spree.t(:price_range_sack)
      end

      def uses_price_range?
        true
      end

      def compute_package(package)
        range = detect_price_range(package.order.total)
        range.nil? ? 0 : range.shipment_price
      end

      def detect_price_range(package_price)
        price_ranges.detect do |range|
          included_in_price_range?(package_price, range)
        end
      end

      def included_in_price_range?(package_price, range)
        (range.minimum_price_order..range.maximum_price_order).cover? package_price
      end
    end
  end
end