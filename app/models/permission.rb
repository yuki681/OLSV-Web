class Permission < ApplicationRecord
  belongs_to :license
  has_many :permission_actions, dependent: :destroy
  has_many :actions, through: :permission_actions
end
