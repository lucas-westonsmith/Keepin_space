class MessagesController < ApplicationController
  before_action :authenticate_user!

  def index
    @messages = [] # ❌ À remplacer plus tard par les vrais messages
  end

  def show
    @message = {} # ❌ Placeholder à remplacer
  end

  def create
    flash[:notice] = "Message envoyé !"
    redirect_to messages_path
  end
end
