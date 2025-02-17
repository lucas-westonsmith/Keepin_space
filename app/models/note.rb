class Note < ApplicationRecord
  belongs_to :author, class_name: "User"
  belongs_to :target, class_name: "User", optional: true
  belongs_to :event, optional: true
end
