class LicensesController < ApplicationController
  def index
  end
  
  def show
    @license = License.includes(
        :notices,
        permissions: [
          :actions,
          { condition_nodes: [:condition, :child_nodes] } ,
        ],
      ).find(params[:id])
  end
end
