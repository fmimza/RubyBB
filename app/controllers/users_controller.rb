class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :show]

  before_filter :check_params, :only => [:index]
  helper_method :default_column, :default_direction

  # GET /users
  # GET /users.json
  def index
    if params[:group]
      @users = Group.for_user(current_user).find(params[:group]).users
    else
      @users = User
    end
    @users = @users.where(params[:sort] + " <> ''").order(params[:sort] + " " + params[:direction]).page params[:page]

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users, :except => [:email] }
    end
  end

  def tokens
    @tokens = []
    @tokens += [{id: "{\"type\":\"All\"}", name: t('common.all')}] if t('common.all').downcase.start_with?(params[:q].downcase)
    @tokens += [{id: "{\"type\":\"Humans\"}", name: t('common.humans')}] if t('common.humans').downcase.start_with?(params[:q].downcase)

    @tokens += (User.where("name LIKE ?", params[:q] + "%").order(:name) + Group.where("name LIKE ?", params[:q] + "%").order(:name)).map do |o|
      {id: "{\"id\":#{o.id},\"type\":\"#{o.class}\"}", name: o.name}
    end

    respond_to do |format|
      format.json { render json: @tokens }
    end
  end
  
  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.select('users.*').with_follows(current_user).find(params[:id])
    if request.path != user_path(@user)
      return redirect_to @user, :status => :moved_permanently
    end

    @graph_messages = Graph.new(@user.created_at, @user.messages.graph).accumulation
    @graph_follows = Graph.new(@user.created_at, @user.messages.graph_follows).accumulation

    @widgets_mode = true
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user, :except => [:email] }
    end
  end

  # PUT /users/1/bot
  def bot
    @user = User.find(params[:id])
    authorize! :bot, @user

    if params[:bot]
      @user.messages.delete_all
      @user.delete
    elsif params[:human]
      @user.update_column :human, true
    end

    t = Topic.find(params[:topic_id])
    t.touch

    respond_to do |format|
      format.html { redirect_to topic_url(t) }
      format.json { render json: @user, :except => [:email] }
    end
  end

  private

  def default_column
    'updated_at'
  end

  def default_direction column
    %w[topics_count messages_count updated_at].include?(column) ? 'desc' : 'asc'
  end

  def check_params
    params[:sort] = default_column unless User.column_names.include?(params[:sort])
    params[:direction] = default_direction(params[:sort]) unless %w[asc desc].include?(params[:direction])
  end

end
