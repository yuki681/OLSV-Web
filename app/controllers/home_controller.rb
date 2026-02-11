class HomeController < ApplicationController
  def show
    @licenses_count = License.count
  end
end
