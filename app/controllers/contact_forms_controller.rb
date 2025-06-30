# frozen_string_literal: true

# Controller for contact forms; note that this is
# only accessible to logged-in users.
class ContactFormsController < ApplicationController
  before_action :authenticate_user!

  # Render a form for contacting a library or access services
  #
  # GET /contact
  # GET /contact/new
  def new
    respond_to do |format|
      format.html do
        return render layout: false if request.xhr?
      end
    end
  end

  # Handle contact form submission by sending an email to the
  # appropriate recipients
  #
  # POST /contact
  def create
    return unless request.post?

    if valid?
      params[:name] = patron.display_name
      params[:email] = patron.email
      ContactMailer.submit_feedback(params, request.remote_ip).deliver_now
      flash[:success] = t 'mylibrary.contact_form.success'
    end
    respond_to do |format|
      format.json { render json: flash }
      format.html { redirect_to params[:url] }
    end
  end

  protected

  def url_regex
    %r/.*href=.*|.*url=.*|.*https?:\/{2}.*/i
  end

  def valid?
    errors = []
    errors << 'A message is required' if params[:message].blank?
    if params[:message]&.match(url_regex)
      errors << 'Your message appears to be spam, and has not been sent. ' \
                'Please try sending your message again without any links in the comments.'
    end
    flash[:danger] = errors.join('<br/>') unless errors.empty?
    flash[:danger].nil?
  end
end
