class OcrPolicy < ApplicationPolicy
  def recognize?
    user.staff? || user.admin?
  end

  def batch_recognize?
    user.staff? || user.admin?
  end

  def history?
    user.staff? || user.admin?
  end

  def stats?
    user.staff? || user.admin?
  end

  def create_package?
    user.staff? || user.admin?
  end
end
