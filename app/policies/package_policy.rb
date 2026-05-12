class PackagePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    # 普通用户只能查看自己的包裹，工作人员和管理员可以查看所有包裹
    user.customer? ? record.user_id == user.id : true
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

  def store?
    user.staff? || user.admin?
  end

  def pick_up?
    user.staff? || user.admin?
  end

  def mark_exception?
    user.staff? || user.admin?
  end

  def batch_store?
    user.staff? || user.admin?
  end

  def batch_pick_up?
    user.staff? || user.admin?
  end

  class Scope < Scope
    def resolve
      if user.customer?
        scope.where(user_id: user.id, deleted_at: nil)
      else
        scope.where(deleted_at: nil)
      end
    end
  end
end
