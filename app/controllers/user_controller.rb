class UserController < ApplicationController
  def index
    render json: { user: '1'}
  end
end
