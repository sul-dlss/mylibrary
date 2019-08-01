# frozen_string_literal: true

# ContactFormsHelper
module ContactFormsHelper
  def contact_form_to(code = nil)
    label = ['Circulation & Privileges']
    label[0] = library_name(code) if code
    label << ' ('
    label << link_to(library_email(code), "mailto:#{library_email(code)}")
    label << ')'
    safe_join(label, '')
  end
end
