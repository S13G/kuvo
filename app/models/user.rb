class User < ApplicationRecord
  has_secure_password

  has_one :profile, dependent: :destroy, class_name: "Profile"
  has_one :cart, dependent: :destroy
  has_many :user_otps, dependent: :destroy
  has_many :blacklisted_tokens, dependent: :destroy
  has_many :product_favorites, dependent: :destroy
  has_many :favorited_products, through: :product_favorites, source: :product
  has_many :shipping_addresses
  has_many :product_reviews
  has_many :orders

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true

  validates :password, length: { minimum: 8 }, presence: true, if: :password_required?
  validate :password_complexity

  after_create :create_profile, :send_otp_email, :create_cart

  def password_required?
    password_digest.blank? || password.present?
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at email provider username is_verified id uid updated_at password_digest]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[profile user_otps blacklisted_tokens product_favorites favorited_products shipping_addresses]
  end

  def generate_secure_password(length = 12)
    chars = [
      ("A".."Z").to_a.sample,
      ("a".."z").to_a.sample,
      ("0".."9").to_a.sample,
      %w[! @ # $ % ^ & *].sample
    ]

    # Fill the rest with random characters from all types
    all_chars = [
      ("A".."Z"),
      ("a".."z"),
      ("0".."9"),
      %w[! @ # $ % ^ & *]
    ].map(&:to_a).flatten
    chars += Array.new(length - chars.size) { all_chars.sample }

    chars.shuffle.join
  end

  def as_json(options = {})
    {
      id: id,
      email: email,
      username: username,
      created_at: created_at,
      updated_at: updated_at,
      profile_exist: profile.present?
    }
  end

  def send_otp_email
    otp = generate_otp
    UserOtp.create_object(self, otp)
    SendOtpEmailJob.perform_later(id, otp)
  end

  def bookmark(product)
    product_favorites.find_or_create_by(product: product)
  end

  def unbookmark(product)
    product_favorites.where(product_id: product.id).destroy_all
  end

  def favorited?(product)
    favorited_products.exists?(product.id)
  end

  def favorite_products
    favorited_products.includes(:product_reviews, :product_variants, :product_images).map { |p| p.as_json }
  end

  def add_to_favorites!(product)
    bookmark(product)
  end

  def remove_from_favorites!(product_id:)
    product = Product.find(product_id)
    unbookmark(product)
  end

  def all_shipping_addresses
    shipping_addresses.as_json
  end

  private

  def generate_otp
    rand(100000..999999)
  end

  def password_complexity
    return if password.blank?

    errors.add(:password, "must be at least 8 characters long") if password.length < 8
    errors.add(:password, "must contain at least one uppercase letter") if password.match?(/[A-Z]/) == false
    errors.add(:password, "must contain at least one lowercase letter") if password.match?(/[a-z]/) == false
    errors.add(:password, "must contain at least one digit") if password.match?(/[0-9]/) == false
    errors.add(:password, "must contain at least one special character (!@#$%^&*)") if password.match?(/[!@#$%^&*]/) == false
  end

  def create_profile
    # initialize profile so user.profile never returns nil
    build_profile.save(validate: false)
  end
end
