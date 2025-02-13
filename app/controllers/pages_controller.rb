class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[home discover pricing]

  def home
  end

  def discover
  end

  def pricing
  end
end
