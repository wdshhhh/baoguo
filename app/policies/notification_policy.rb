class NotificationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    record.user_id == user.id || user.admin?
  end

  def mark_read?
    record.user_id == user.id
  end

  def mark_all_read?
    true
  end

  def unread_count?
    true
  end

  def retry?
    user.staff? || user.admin?
  end

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
