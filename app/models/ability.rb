# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    if user.nil?
      return
    end

    if user.superadmin?
      can :manage, :all

      cannot :manage, AdminUser, superadmin: true
    else
      can :read, ActiveAdmin::Page

      can :manage, [
        Product, Category, ProductColor,
        ProductImage, ProductReview, ProductSize,
        ProductVariant
      ]

      can :read, AdminUser, superadmin: false
      can :read, CurrencySetting
      can :read, Discount

      cannot :destroy, :all
    end
  end
end
