class BookmarksController < ApplicationController
  before_filter :authenticate_user!
  before_filter :check_params, only: :index

  # GET /bookmarks
  # GET /bookmarks.json
  def index
    @forum = Forum.new
    @topics = Topic.select('topics.*').includes(:user, :first_message, last_message: [:user]).bookmarked_by(current_user).accessible_for(current_user, 'view').order("#{params[:sort]} #{params[:order]}").page(params[:page])

    respond_to do |format|
      format.html
      format.json { render json: @topics }
    end
  end

  # PUT /bookmarks
  def mark_as_read
    Bookmark.where(:user_id => current_user.id).each do |b|
      b.update_attribute :message_id, b.topic.last_message_id
    end

    respond_to do |format|
      format.html { redirect_to bookmarks_url }
      format.json { head :no_content }
    end
  end

  # DELETE /bookmarks
  def clear
    Bookmark.where(:user_id => current_user.id).delete_all

    respond_to do |format|
      format.html { redirect_to bookmarks_url }
      format.json { head :no_content }
    end
  end

  private

  def check_params
    params[:sort] = Topic.default_column unless Topic.column_names.include?(params[:sort])
    params[:direction] = Topic.default_direction(params[:sort]) unless %w[asc desc].include?(params[:direction])
  end
end
