class OperationLogPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def export?
    user.admin?
  end
end
