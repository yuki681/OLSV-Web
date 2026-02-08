class Condition < ApplicationRecord
  enum :condition_type, { obligation: "OBLIGATION", requisite: "REQUISITE", restriction: "RESTRICTION" }
end
