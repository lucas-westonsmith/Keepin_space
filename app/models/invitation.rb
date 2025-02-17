class Invitation < ApplicationRecord
  belongs_to :event
  belongs_to :user, optional: true

  before_create :generate_unique_token

  enum status: { pending: 0, accepted: 1, declined: 2, maybe: 3 }, _default: "pending"

  validates :email, presence: true, unless: -> { user.present? }
  validates :phone, uniqueness: { scope: :event_id }, allow_blank: true

  private

  def generate_unique_token
    self.token ||= SecureRandom.hex(10)  # Génère un token unique
  end
end
