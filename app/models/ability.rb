# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    if user.has_any_role?("admin", "super_admin")
      can :manage, :all
    elsif user.has_role?("seller")
      can :read, Product
      can :read, Media
      can :read, Location, id: user.location_id
      can :read, Warehouse, location_id: user.location_id
      can :read, WarehouseInventory, warehouse: { location_id: user.location_id }
      can :manage, Order, seller_id: user.id
    elsif user.has_role?("customer")
      can :manage, Customer, user_id: user.id
    else

    end


    # Define abilities for the user here. For example:
    #
    #   return unless user.present?
    #   can :read, :all
    #   return unless user.admin?
    #   can :manage, :all
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, published: true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/define_check_abilities.md
  end
end
