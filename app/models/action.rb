class Action < ApplicationRecord
  has_many :permission_actions, dependent: :destroy
  has_many :permissions, through: :permission_actions
end
