class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Every user belongs to one store
  belongs_to :tenant

  # API refresh tokens (one per logged-in device/session)
  has_many :refresh_tokens, dependent: :destroy

  # owner can do everything; staff is limited (enforced via Pundit policies)
  enum :role, { owner: 0, staff: 1 }
end
