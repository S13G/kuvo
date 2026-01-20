class ShippingAddress < ApplicationRecord
  belongs_to :user
  has_many :orders

  validates :address_tag, presence: true, uniqueness: { scope: :user_id }
  validates :address, presence: true
  validates :user, presence: true
  validate :address_limit

  before_save :ensure_single_default, :address_limit

  MAX_ADDRESSES = 10

  scope :ordered, -> {
    order(is_default: :desc, created_at: :desc)
      .to_a
      .sort_by { |a| [a.is_default? ? 0 : 1, a.created_at] }
  }

  def as_json(options = nil)
    {
      id: id,
      address_tag: address_tag,
      address: address,
      is_default: is_default
    }
  end

  private

  def ensure_single_default
    if is_default && is_default_changed?
      user.shipping_addresses.where.not(id: id).update_all(is_default: false)
    end
  end

  def address_limit
    if user
      if new_record? # Only check for new records to avoid blocking updates
        if user.shipping_addresses.count >= MAX_ADDRESSES
          errors.add(:base, "You cannot have more than #{MAX_ADDRESSES} addresses")
        end
      end
    end
  end
end