class ReviewsController < ApplicationController

  def create
    if current_user
    @review = Review.new(review_params)
    @review.user_id = @current_user.id
    @review.location_id = params[:location_id].to_i
      if @review.save
        redirect_to(:back)
      else
        flash[:notice]="You must select a rating to submit a review"
        redirect_to(:back)
      end
    else
    redirect_to root_path
    end
  end

  def new
  	@location = Location.find(params[:id])
  	@review = Review.new
  end

  def update
  end

  def destroy
    @review = Review.find(params[:id])
    if @review.delete
      redirect_to(:back)
    end
  end

  private

  def review_params
    params.require(:review).permit(:body, :rating)
  end

end
