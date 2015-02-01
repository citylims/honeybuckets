class LocationsController < ApplicationController
  protect_from_forgery

  def home
    honey = twitter_client.search('#honeybuckets').take(3) # <- tweets at a time
    @honey_embed = honey.map do |tweet|
      twitter_client.oembed(tweet.id, option = { hide_media: :true, hide_thread: :true })
    end
  end

  def map
    @geojson = { locations: []}

    if params[:search] && params[:search] != ''
      @search = params[:search]
      @coordinates = Geocoder.search(@search)[0].data['geometry']['location']
      @geojson[:search] = {
        latitude: @coordinates['lat'],
        longitude: @coordinates['lng']
      }
    else
      @search = false
    end


    @locations = Location.all
    @locations.each do |location|
      if location.reviews.length >= 1
        rating = location.reviews.average(:rating)
      else
        rating = "No ratings yet!"
      end
      @geojson[:locations] << {
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [location.long, location.lat]
          },
          properties: {
            name: location.name,
            address: location.address,
            :'marker-color' => '#00607d',
            :'marker-symbol' => 'circle',
            :'marker-size' => 'medium',
            :'url' => location_path(location),
            :'rating' => rating
          }
        }
    end

    honey = twitter_client.search('Washington D.C.').take(6) # <-tweets at a time
    @honey_embed = honey.map do |tweet|
      twitter_client.oembed(tweet.id, options = { hide_media: :true, hide_thread: :true })
    end

    respond_to do |format|
      format.html
      format.json { render json: @geojson }
    end
  end

  def show
    @location = Location.find(params[:id])
    @review = Review.new
    @this = Review.last
    @reviews = Review.where(location_id: params[:id])
    @rating = @location.reviews.average(:rating)

    @geojson = {
          type: 'Feature',
          geometry: {
            type: 'Point',
            coordinates: [@location.long, @location.lat]
          },
          properties: {
            name: @location.name,
            address: @location.address,
            :'marker-color' => '#00607d',
            :'marker-symbol' => 'circle',
            :'marker-size' => 'medium',
            :'url' => location_path(@location),
            :'rating' => @rating
          }
        }

    if current_user
      @user = User.find(session[:user_id])
    else
      @user = User.new(name: 'guest')
    end

    respond_to do |format|
      format.html
      format.json { render json: @geojson }
    end
  end

  def new
    @location = Location.new
    @review = Review.new
  end

  def create
    @location = Location.new(location_params)
    @address_components = Geocoder.search("#{@location.lat}, #{@location.long}")[0].data['address_components']
    @street_num = @address_components[0]['long_name']
    @street = @address_components[1]['long_name']
    @location.address = @street_num + " " + @street
    if @location.name == nil
      flash[:notice]= "You must input a name for your new location!"
      redirect_to(:back)
    else
    @location.save
  end

    respond_to do |format|
      format.html
      format.json { render :json => {location: location_path(@location)} }
    end
  end

private
  def location_params
    params.require(:location).permit(:name, :lat, :long)
  end
end
