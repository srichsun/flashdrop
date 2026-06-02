# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  def index?
    true
  end

  # Owners and staff both fulfill orders
  def ship?
    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all # acts_as_tenant scopes to the current store
    end
  end
end
