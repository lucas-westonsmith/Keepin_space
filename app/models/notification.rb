class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :event

  scope :unread, -> { where(read_at: nil) }

  def mark_as_read!
    update(read_at: Time.current)
  end
end
