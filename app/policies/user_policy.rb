class UserPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    # 用户可以查看自己的信息，管理员可以查看所有用户
    user.id == record.id || user.admin?
  end

  def create?
    user.admin?
  end

  def update?
    # 用户可以更新自己的信息，管理员可以更新所有用户
    user.id == record.id || user.admin?
  end

  def destroy?
    user.admin? && user.id != record.id
  end

  def update_role?
    user.admin?
  end

  def reset_password?
    user.admin?
  end

  def enable?
    user.admin?
  end

  def disable?
    user.admin? && user.id != record.id
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
