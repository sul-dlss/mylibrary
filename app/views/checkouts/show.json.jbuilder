# frozen_string_literal: true

json.checkout 'foo'
json.user params[:id]
json.checkouts [{ id: 1, name: 'Book' }, { id: 2, name: 'Magazine' }]
