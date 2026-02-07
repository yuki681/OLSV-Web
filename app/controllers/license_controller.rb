class LicenseController < ApplicationController
  def index
  end
  
  def show
    @license = License.includes(:notices).find(params[:id])
  end
end
