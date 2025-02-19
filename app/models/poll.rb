class Poll < ApplicationRecord
  belongs_to :event
  has_many :poll_options, dependent: :destroy
end
