class Notice < ApplicationRecord
  has_many :license_notices, dependent: :destroy
  has_many :licenses, through: :license_notices
end
