class User < ApplicationRecord
  # Devise authentication
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :events, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :notes_written, class_name: "Note", foreign_key: "author_id", dependent: :destroy
  has_many :notes_received, class_name: "Note", foreign_key: "target_id", dependent: :destroy
  has_many :notifications, dependent: :destroy

  # ActiveStorage pour l'avatar
  has_one_attached :avatar

  # Contacts (relations auto-référentielles)
  has_many :contacts_as_user, class_name: "Contact", foreign_key: "user_id", dependent: :destroy
  has_many :contacts, through: :contacts_as_user, source: :contact

  # Validation des liens sociaux
  validates :linkedin, :facebook, :instagram, :twitter, :tiktok, :github, format: { with: URI::DEFAULT_PARSER.make_regexp, allow_blank: true, message: "must be a valid URL" }
  validates :secondary_email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true, message: "must be a valid email address" }

  # Enum pour le rôle (admin, membre, invité)
  enum role: { guest: 0, member: 1, admin: 2 }
end
