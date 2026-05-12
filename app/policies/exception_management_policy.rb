class ExceptionManagementPolicy < ApplicationPolicy
  def index?
    user.staff? || user.admin?
  end

  def show?
    user.staff? || user.admin?
  end

  def create?
    user.staff? || user.admin?
  end

  def update?
    user.staff? || user.admin?
  end

  def destroy?
    user.admin?
  end

  def mark_as_processing?
    user.staff? || user.admin?
  end

  def resolve?
    user.staff? || user.admin?
  end

  def batch_process?
    user.staff? || user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin? || user.staff?
        scope.all
      else
        scope.none
      end
    end
  end
end
