# frozen_string_literal: true

# Controller for Contct forms
class ContactFormsController < ApplicationController
  def new; end

  def create
    return unless request.post?

    if validate
      params[:name] = patron.display_name
      params[:email] = patron.email
      ContactMailer.submit_feedback(params, request.remote_ip).deliver_now
      flash[:success] = 'Thank you! Someone from Access Services will be in touch with you soon.'
    end
    respond_to do |format|
      format.json { render json: flash }
      format.html { redirect_to params[:url] }
    end
  end

  protected

  def url_regex
    %r{/.*href=.*|.*url=.*|.*http:\/\/.*|.*https:\/\/.*/i}
  end

  def validate
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
