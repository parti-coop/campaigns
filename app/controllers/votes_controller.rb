class VotesController < ApplicationController
  include VoteHelper

  before_action :authenticate_user!, except: [:agree, :disagree, :neutral]

  def agree
    @widget = params[:widget]
    fetch_votable
    choice(:agree)

    respond_to do |format|
      format.js
      format.html { redirect_back(fallback_location: @votable) }
    end
  end

  def disagree
    @widget = params[:widget]
    fetch_votable
    choice(:disagree)

    respond_to do |format|
      format.js
      format.html { redirect_back(fallback_location: @votable) }
    end
  end

  def neutral
    @widget = params[:widget]
    fetch_votable
    choice(:neutral)

    respond_to do |format|
      format.js
      format.html { redirect_back(fallback_location: @votable) }
    end
  end

  def cancel
    @widget = params[:widget]
    @votable ||= params[:votable_type].constantize.find params[:votable_id]
    @vote = @votable.fetch_vote_of(current_user)

    if @vote.present?
      errors_to_flash(@vote) unless @vote.destroy
    end

    @votable.reload

    respond_to do |format|
      format.js
      format.html { redirect_back(fallback_location: @votable) }
    end
  end

  private

  def choice(choice)
    if !user_signed_in? and anonymous_voted?(@votable)
      render 'login_alert.js.erb'
      return
    end

    @vote = @votable.fetch_vote_of(current_user) if user_signed_in?

    ActiveRecord::Base.transaction do
      if @vote.blank?
        @vote = @votable.votes.build(choice: choice, user: current_user)
        mark_anonymous_voted_poll(@votable, choice) unless user_signed_in?
        errors_to_flash(@vote) unless @votable.save
      elsif @vote.choice != choice
        @vote.update_attributes(choice: choice)
        errors_to_flash(@vote) unless @vote.save
      end
    end
    @votable.reload
  end

  def fetch_votable
    @votable ||= params[:votable_type].constantize.find params[:votable_id]
  end
end
