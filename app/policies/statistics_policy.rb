class StatisticsPolicy < ApplicationPolicy
  def summary?
    user.staff? || user.admin?
  end

  def trend?
    user.staff? || user.admin?
  end

  def package_by_courier?
    user.staff? || user.admin?
  end

  def weight_distribution?
    user.staff? || user.admin?
  end

  def export?
    user.staff? || user.admin?
  end
end
