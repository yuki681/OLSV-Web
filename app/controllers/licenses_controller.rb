class LicensesController < ApplicationController
  def index
    @q = params[:q]

    # TODO: 検索機能の追加
    @pagy, @licenses = pagy(:offset, License.all.order(:name), limit: 20)
  end

  def show
    @license = License.includes(
      :notices,
      permissions: [
        :actions,
        { condition_nodes: [ :condition, :child_nodes ] }
      ]
    ).find(params[:id])
  end
end
