class ChatgptController < ApplicationController
  def index

  end

  def choose
    choice = params[:choice]
    result = OpenaiService.new(choice).call
    render json: { choice: result }
  end
end
