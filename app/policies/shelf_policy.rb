class ShelfPolicy < ApplicationPolicy
  def index?
    user.admin? || user.staff?
  end

  def show?
    user.admin? || user.staff?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def toggle_status?
    user.admin?
  end

  class Scope < Scope
    def resolve
      scope.active
    end
  end
end