# frozen_string_literal: true

# Controller for Contct forms
class ContactFormsController < ApplicationController
  def new
    respond_to do |format|
      format.html
      format.js # modal window
    end
  end

  def create
    return unless request.post?

    if validate
      FeedbackMailer.submit_feedback(params, request.remote_ip).deliver_now
      flash[:success] = 'Thank you! Someone from Access Services will be in touch with you soon.'
    end

    redirect_to request.referer
  end

  protected

  def url_regex
    %r{/.*href=.*|.*url=.*|.*http:\/\/.*|.*https:\/\/.*/i}
  end

  def validate
    errors = []
    errors << 'A message is required' if params[:message].blank?
    if params[:message]&.match?(url_regex)
      errors << 'Your message appears to be spam, and has not been sent. ' \
                'Please try sending your message again without any links in the comments.'
    end
    if params[:user_agent] =~ url_regex ||
       params[:viewport] =~ url_regex
      errors << 'Your message appears to be spam, and has not been sent.'
    end
    flash[:danger] = errors.join('<br/>') unless errors.empty?
    flash[:danger].nil?
  end
end
