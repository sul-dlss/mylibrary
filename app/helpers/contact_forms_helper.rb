# frozen_string_literal: true

# ContactFormsHelper
module ContactFormsHelper
  def contact_form_to(code = nil)
    label = ['Circulation & Privileges']
    label[0] = Folio::Library.find_by_code(code)&.name if code
    label << ' ('
    label << link_to(library_email(code), "mailto:#{library_email(code)}")
    label << ')'
    safe_join(label, '')
  end
end
