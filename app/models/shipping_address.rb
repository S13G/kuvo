class ShippingAddress < ApplicationRecord
  belongs_to :user
  has_many :orders

  validates :address_tag, presence: true, uniqueness: true
  validates :address, presence: true
  validates :user, presence: true
  validates :is_default, uniqueness: { scope: :user_id, if: :is_default }

  before_save :ensure_single_default

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
end
