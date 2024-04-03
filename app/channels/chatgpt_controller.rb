class ChatgptController < ApplicationController
  def index

  end

  def begin
    response = OpenaiService.new(nil).begin
    render json: { response: response }
  end

  def choose
    choice = params[:choice]
    result = OpenaiService.new(choice).call
    render json: { choice: result }
  end
end
