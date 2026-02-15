class LicensesController < ApplicationController
  def index
    @q = params[:q].to_s
    q_tokens = @q.split(/[[:blank:]]+/).reject(&:blank?)

    if q_tokens.present?
      # TODO: PostgreSQLの場合はILIKEを使用する必要がある。
      # レコード数700件程度であれば、十分高速（10ms未満）であることを確認した。
      @licenses = License.all
      q_tokens.each do |token|
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(token)}%"
        @licenses = @licenses.where("name LIKE ?", pattern)
      end

    else
      @licenses = License.none
    end

    @pagy, @licenses = pagy(:offset, @licenses, limit: 20)
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
