class PermissionAction < ApplicationRecord
  belongs_to :permission
  belongs_to :action
end