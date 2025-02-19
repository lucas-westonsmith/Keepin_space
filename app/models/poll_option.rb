class PollOption < ApplicationRecord
  belongs_to :poll
  validates :content, presence: true
end
