# frozen_string_literal: true

module ApplicationHelper
  def active_page_class(name)
    'active' if controller_name == name
  end

  def list_group_item_status_for_checkout(checkout)
    if checkout.recalled?
      'list-group-item-danger'
    elsif checkout.overdue?
      'list-group-item-warning'
    end
  end
end
