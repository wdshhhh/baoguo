class SystemSettingPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    user.admin?
  end

  def update?
    user.admin?
  end

  def batch_update?
    user.admin?
  end

  def reset?
    user.admin?
  end

  def rollback?
    user.admin?
  end

  def logs?
    user.admin?
  end

  def history?
    user.admin?
  end
end
