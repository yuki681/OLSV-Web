class License < ApplicationRecord
  has_many :permissions, dependent: :destroy
  has_many :license_notices, dependent: :destroy
  has_many :notices, through: :license_notices
  has_many :actions, through: :permissions
end
