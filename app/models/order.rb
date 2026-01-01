class Order < ApplicationRecord
  belongs_to :user
  belongs_to :shipping_address
  has_many :order_items

  enum :status, {
    pending: "pending",
    paid: "paid",
    processing: "processing",
    in_transit: "in transit",
    delivered: "delivered",
    cancelled: "cancelled"
  }

  validates :total_amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :shipping_fee_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true
  validates :tracking_number, uniqueness: true, allow_blank: true

  before_validation :generate_tracking_number, on: :create
  after_create :record_initial_status
  after_update :record_status_change, if: :saved_change_to_status?

  def record_initial_status
    self.status_history << {
      from_status: nil,
      to_status: status,
      changed_at: Time.current
    }
    save!
  end

  def record_status_change
    self.status_history << {
      from_status: status_before_last_save,
      to_status: status,
      changed_at: Time.current
    }
    save!
  end

  def self.active_orders
    where.not(status: [statuses[:cancelled], statuses[:delivered]])
  end

  def self.cancelled_orders
    where(status: statuses[:cancelled])
  end

  def self.completed_orders
    where(status: statuses[:delivered])
  end

  def self.recent
    order(created_at: :desc)
  end

  def self.with_items_and_products
    includes(order_items: :product)
  end

  def generate_tracking_number
    self.tracking_number = "TRK-#{SecureRandom.alphanumeric(14).upcase}"
  end

  def total_amount_with_shipping_cents
    total_amount_cents + shipping_fee_cents
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id shipping_address_id shipping_fee_cents status total_amount_cents tracking_number updated_at user_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order_items shipping_address user]
  end

  def cancel!
    update(status: :cancelled)
  end

  def as_json(options = nil)
    {
      id: id,
      status: status,
      total_amount_cents: total_amount_cents,
      shipping_fee_cents: shipping_fee_cents,
      total_amount_with_shipping_cents: total_amount_with_shipping_cents,
      tracking_number: tracking_number,
      shipping_address: shipping_address.as_json,
      order_items: order_items.as_json,
      status_history: status_history
    }
  end

end
