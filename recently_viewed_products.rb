class RecentlyViewedProducts
  MAXIMUM_PRODUCTS = 20

  attr_accessor :product_id, :session

  def initialize(session, product_id = nil)
    @session = session
    @product_id = product_id
  end

  def add_product
    if session.nil?
      products = product_id.to_s
    else
      products = parse_ids
      products << product_id unless products.include?(product_id.to_s)
      products = join_new_product(products)
      check_space_for_new_product(products)
    end
  end

  def get_products
    if session.present?
      product_ids = parse_ids
      Spree::Product.by_store(store).where(id: product_ids.map(&:to_i))
    end
  end

  def parse_ids
    session.split('&').flatten
  end

  def remove_product(product_id)
    session = parse_ids
    session.delete_if { |id| id == product_id }
    session.join('&')
  end

  private

  def check_space_for_new_product(products)
    products.delete_at(0) if products.size > MAXIMUM_PRODUCTS
    products
  end

  def join_new_product(products)
    products.map(&:to_s)
  end

  def store
    if product_id
      Spree::Product.find_by(id: product_id).try(:store)
    else
      StoreService.store
    end
  end
end
