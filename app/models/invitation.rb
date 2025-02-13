class Invitation < ApplicationRecord
  belongs_to :event
  belongs_to :user, optional: true

  enum status: { pending: 0, accepted: 1, declined: 2, maybe: 3 }, _default: "pending"

  validates :email, presence: true, unless: -> { user.present? }
end
